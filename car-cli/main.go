package main

import (
	"crypto/x509"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/AlecAivazis/survey/v2"
	"github.com/fatih/color"
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"github.com/spf13/cobra"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

// HLF Constants
const (
	channelName      = "mychannel"
	chaincodeName    = "carcc"
	singleHostPath   = "/home/raj/HyperledgerFabric/Car-Supply-Chain/single-host"
	mspPathFormat    = singleHostPath + "/organizations/peerOrganizations/%s.example.com"
	certPathFormat   = mspPathFormat + "/users/Admin@%s.example.com/msp/signcerts/cert.pem"
	keyPathFormat    = mspPathFormat + "/users/Admin@%s.example.com/msp/keystore"
	tlsCertPathFormat = mspPathFormat + "/peers/peer0.%s.example.com/tls/ca.crt"
	peerEndpointFormat = "localhost:%d"
)

var (
	currentOrg = "manufacturer"
)

type Car struct {
	ID      string `json:"ID"`
	Make    string `json:"make"`
	Model   string `json:"model"`
	Color   string `json:"color"`
	Owner   string `json:"owner"`
	Status  string `json:"status"`
	Price   int    `json:"price"`
	MfgDate string `json:"mfgDate"`
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "car-cli",
		Short: "\U0001F697 Car Supply Chain HLF CLI Tool",
		Long:  color.CyanString(`Car Supply Chain HLF CLI Tool`),
	}

	rootCmd.AddCommand(initCmd())
	rootCmd.AddCommand(downCmd())
	rootCmd.AddCommand(interactCmd())

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func initCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "init",
		Short: "\U0001F680 Initialize the single-host HLF network and channel",
		Run: func(cmd *cobra.Command, args []string) {
			color.Cyan("\n--- \U0001F680 Initializing HLF Network (Single-Host) ---\n")
			spinner := []string{"|", "/", "-", "\\"}
			go func() {
				for {
					for _, s := range spinner {
						fmt.Printf("\r\033[36m%s\033[0m Starting network...", s)
						time.Sleep(100 * time.Millisecond)
					}
				}
			}()

			runShell("network.sh down")
			runShell("network.sh up createChannel -c " + channelName + " -ca -s couchdb")
			runShell("network.sh deployCC -ccn " + chaincodeName + " -ccp ../chaincode-go -ccl go")

			color.Green("\r\U0001F233 Network Initialization Complete!\n")
		},
	}
}

func downCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "down",
		Short: "\U0001F5D1 Bring down the HLF network",
		Run: func(cmd *cobra.Command, args []string) {
			color.Red("\n--- \U0001F5D1 Bringing Down Network ---\n")
			runShell("network.sh down")
			color.Green("\U0001F232 Network is DOWN!\n")
		},
	}
}

func interactCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "interact",
		Short: "\U0001F50D Interactive dashboard to interact with world state",
		Run: func(cmd *cobra.Command, args []string) {
			for {
				color.HiCyan("\n-------------------------------------------")
				color.HiCyan("   \U0001F697 CAR SUPPLY CHAIN DASHBOARD \U0001F697   ")
				color.HiCyan("-------------------------------------------")
				fmt.Printf("Current Context: [%s]\n\n", color.YellowString(strings.ToUpper(currentOrg)))

				var action string
				prompt := &survey.Select{
					Message: "What would you like to do?",
					Options: []string{
						"Switch Organization",
						"Create a Car",
						"Read Car Details",
						"Transfer Car Ownership",
						"View Car History",
						"Exit Dashboard",
					},
				}
				survey.AskOne(prompt, &action)

				switch action {
				case "Switch Organization":
					switchOrg()
				case "Create a Car":
					createCar()
				case "Read Car Details":
					readCar()
				case "Transfer Car Ownership":
					transferCar()
				case "View Car History":
					viewCarHistory()
				case "Exit Dashboard":
					color.Yellow("Exiting. Keep on tracking!")
					return
				}
			}
		},
	}
}

func switchOrg() {
	var org string
	prompt := &survey.Select{
		Message: "Choose organization context:",
		Options: []string{"manufacturer", "showroom"},
	}
	survey.AskOne(prompt, &org)
	currentOrg = org
	color.Green("\U0001F31F Switched context to %s\n", strings.ToUpper(currentOrg))
}

func createCar() {
	qs := []*survey.Question{
		{
			Name: "id",
			Prompt: &survey.Input{Message: "Asset ID (e.g. CAR999):"},
			Validate: survey.Required,
		},
		{
			Name: "make",
			Prompt: &survey.Input{Message: "Make:"},
			Validate: survey.Required,
		},
		{
			Name: "model",
			Prompt: &survey.Input{Message: "Model:"},
			Validate: survey.Required,
		},
		{
			Name: "color",
			Prompt: &survey.Input{Message: "Color:"},
			Validate: survey.Required,
		},
		{
			Name: "price",
			Prompt: &survey.Input{Message: "Price:"},
			Validate: survey.Required,
		},
	}

	carInput := struct {
		ID    string
		Make  string
		Model string
		Color string
		Price int
	}{}

	err := survey.Ask(qs, &carInput)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	executeTransaction("CreateCar", carInput.ID, carInput.Make, carInput.Model, carInput.Color, fmt.Sprintf("%d", carInput.Price))
}

func readCar() {
	var id string
	prompt := &survey.Input{Message: "Enter Car ID to read:"}
	survey.AskOne(prompt, &id)

	result := evaluateTransaction("ReadCar", id)
	if result != "" {
		formatJSON(result)
	}
}

func transferCar() {
	var id, newOwner, newStatus string
	survey.AskOne(&survey.Input{Message: "Enter Car ID to transfer:"}, &id)

	prompt := &survey.Select{
		Message: "New Status:",
		Options: []string{"IN_SHOWROOM", "OWNED"},
	}
	survey.AskOne(prompt, &newStatus)

	survey.AskOne(&survey.Input{Message: "New Owner Name:"}, &newOwner)

	executeTransaction("TransferCar", id, newOwner, newStatus)
}

func viewCarHistory() {
	var id string
	survey.AskOne(&survey.Input{Message: "Enter Car ID to view history:"}, &id)

	result := evaluateTransaction("GetCarHistory", id)
	if result != "" {
		formatJSON(result)
	}
}

// Helpers

func runShell(command string) {
	cmd := exec.Command("bash", "-c", "./"+command)
	cmd.Dir = singleHostPath
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		color.Red("\U00002716 Error running %s: %v\n", command, err)
	}
}

func getGateway() (*client.Gateway, *grpc.ClientConn) {
	org := currentOrg
	peerPort := 7051
	if org == "showroom" {
		peerPort = 9051
	}

	clientConnection := newGrpcConnection(fmt.Sprintf(peerEndpointFormat, peerPort), strings.ToLower(org))
	
	id := newIdentity(org)
	sign := newSign(org)

	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithClientConnection(clientConnection),
		// Default timeouts
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(10*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		panic(fmt.Errorf("failed to connect to gateway: %w", err))
	}

	return gw, clientConnection
}

func executeTransaction(fcn string, args ...string) {
	gw, conn := getGateway()
	defer gw.Close()
	defer conn.Close()

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)

	color.Yellow("\U0000231B Submitting Transaction [%s] as %s...\n", fcn, currentOrg)

	_, err := contract.SubmitTransaction(fcn, args...)
	if err != nil {
		color.Red("\U00002716 SubmitTransaction Error: %v\n", err)
		return
	}
	color.Green("\U00002705 Transaction Successful!\n")
}

func evaluateTransaction(fcn string, args ...string) string {
	gw, conn := getGateway()
	defer gw.Close()
	defer conn.Close()

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)

	result, err := contract.EvaluateTransaction(fcn, args...)
	if err != nil {
		color.Red("\U00002716 EvaluateTransaction Error: %v\n", err)
		return ""
	}
	return string(result)
}

func newGrpcConnection(endpoint string, org string) *grpc.ClientConn {
	certificatePath := fmt.Sprintf(tlsCertPathFormat, org, org)
	certificate, err := os.ReadFile(certificatePath)
	if err != nil {
		panic(fmt.Errorf("failed to read TLS certificate: %w", err))
	}

	certPool := x509.NewCertPool()
	if ok := certPool.AppendCertsFromPEM(certificate); !ok {
		panic(fmt.Errorf("failed to append certificate to pool"))
	}

	transportCredentials := credentials.NewClientTLSFromCert(certPool, "")

	connection, err := grpc.Dial(endpoint, grpc.WithTransportCredentials(transportCredentials))
	if err != nil {
		panic(fmt.Errorf("failed to create gRPC connection: %w", err))
	}

	return connection
}

func newIdentity(org string) *identity.X509Identity {
	certificatePath := fmt.Sprintf(certPathFormat, org, org)
	certificate, err := os.ReadFile(certificatePath)
	if err != nil {
		panic(fmt.Errorf("failed to read certificate: %w", err))
	}

	cert, err := identity.CertificateFromPEM(certificate)
	if err != nil {
		panic(fmt.Errorf("failed to parse certificate: %w", err))
	}

	mspID := "ManufacturerMSP"
	if org == "showroom" {
		mspID = "ShowroomMSP"
	}

	id, err := identity.NewX509Identity(mspID, cert)
	if err != nil {
		panic(err)
	}

	return id
}

func newSign(org string) identity.Sign {
	keyDir := fmt.Sprintf(keyPathFormat, org, org)
	files, err := os.ReadDir(keyDir)
	if err != nil {
		panic(fmt.Errorf("failed to read key directory: %w", err))
	}

	var keyPath string
	for _, f := range files {
		if !f.IsDir() {
			keyPath = filepath.Join(keyDir, f.Name())
			break
		}
	}

	keyPEM, err := os.ReadFile(keyPath)
	if err != nil {
		panic(fmt.Errorf("failed to read private key: %w", err))
	}

	privateKey, err := identity.PrivateKeyFromPEM(keyPEM)
	if err != nil {
		panic(err)
	}

	sign, err := identity.NewPrivateKeySign(privateKey)
	if err != nil {
		panic(err)
	}

	return sign
}

func formatJSON(data string) {
	var obj interface{}
	if err := json.Unmarshal([]byte(data), &obj); err != nil {
		color.Yellow("Raw Output: %s", data)
		return
	}

	prettyJSON, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		color.Yellow("Raw Output: %s", data)
		return
	}
	color.White("%s", string(prettyJSON))
}
