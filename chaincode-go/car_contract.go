package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// SmartContract defines the supply chain logic
type SmartContract struct {
	contractapi.Contract
}

// Car describes basic details of what is being tracked in the supply chain
type Car struct {
	ID        string `json:"ID"`
	Make      string `json:"make"`
	Model     string `json:"model"`
	Color     string `json:"color"`
	Owner     string `json:"owner"`
	Status    string `json:"status"` // MANUFACTURED, IN_SHOWROOM, OWNED
	Price     int    `json:"price"`
	MfgDate   string `json:"mfgDate"`
}

// HistoryQueryResult structure used for returning result of history query
type HistoryQueryResult struct {
	Record    *Car      `json:"record"`
	TxId      string    `json:"txId"`
	Timestamp time.Time `json:"timestamp"`
	IsDelete  bool      `json:"isDelete"`
}

// InitLedger adds a base set of cars to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	cars := []Car{
		{ID: "CAR001", Make: "Tesla", Model: "Model X", Color: "White", Owner: "Manufacturer", Status: "MANUFACTURED", Price: 80000, MfgDate: "2026-03-25"},
		{ID: "CAR002", Make: "BMW", Model: "i7", Color: "Black", Owner: "Manufacturer", Status: "MANUFACTURED", Price: 120000, MfgDate: "2026-03-24"},
	}

	for _, car := range cars {
		carJSON, err := json.Marshal(car)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(car.ID, carJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateCar issues a new car into the world state with given details.
// Only accessible by ManufacturerMSP
func (s *SmartContract) CreateCar(ctx contractapi.TransactionContextInterface, id string, make string, model string, color string, price int) error {
	exists, err := s.CarExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the car %s already exists", id)
	}

	// ACL: Check if caller is Manufacturer
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get caller MSP ID: %v", err)
	}
	if mspID != "ManufacturerMSP" {
		return fmt.Errorf("only Manufacturer can create cars. Current caller: %v", mspID)
	}

	car := Car{
		ID:      id,
		Make:    make,
		Model:   model,
		Color:   color,
		Owner:   "Manufacturer",
		Status:  "MANUFACTURED",
		Price:   price,
		MfgDate: time.Now().Format("2006-01-02"),
	}
	carJSON, err := json.Marshal(car)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, carJSON)
}

// ReadCar returns the car stored in the world state with given id.
func (s *SmartContract) ReadCar(ctx contractapi.TransactionContextInterface, id string) (*Car, error) {
	carJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if carJSON == nil {
		return nil, fmt.Errorf("the car %s does not exist", id)
	}

	var car Car
	err = json.Unmarshal(carJSON, &car)
	if err != nil {
		return nil, err
	}

	return &car, nil
}

// TransferCar updates the owner field of car with given id in world state.
func (s *SmartContract) TransferCar(ctx contractapi.TransactionContextInterface, id string, newOwner string, newStatus string) error {
	car, err := s.ReadCar(ctx, id)
	if err != nil {
		return err
	}

	// Business Logic: 
	// If transferring from Manufacturer -> Showroom: must be from ManufacturerMSP
	// If transferring from Showroom -> Customer: must be from ShowroomMSP
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return err
	}

	if car.Status == "MANUFACTURED" && mspID != "ManufacturerMSP" {
		return fmt.Errorf("only Manufacturer can transfer a new car. Current caller: %v", mspID)
	}

	if car.Status == "IN_SHOWROOM" && mspID != "ShowroomMSP" {
		return fmt.Errorf("only Showroom can sell the car to a customer. Current caller: %v", mspID)
	}

	car.Owner = newOwner
	car.Status = newStatus
	carJSON, err := json.Marshal(car)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, carJSON)
}

// CarExists returns true when asset with given ID exists in world state
func (s *SmartContract) CarExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	carJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return carJSON != nil, nil
}

// GetCarHistory returns the chain of custody for a car.
func (s *SmartContract) GetCarHistory(ctx contractapi.TransactionContextInterface, id string) ([]HistoryQueryResult, error) {
	resultsIterator, err := ctx.GetStub().GetHistoryForKey(id)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var results []HistoryQueryResult
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var car Car
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &car)
			if err != nil {
				return nil, err
			}
		} else {
			car = Car{ID: id}
		}

		timestamp := time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos))

		record := HistoryQueryResult{
			TxId:      response.TxId,
			Timestamp: timestamp,
			Record:    &car,
			IsDelete:  response.IsDelete,
		}
		results = append(results, record)
	}

	return results, nil
}

func main() {
	carChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating car supply chain chaincode: %v", err)
		return
	}

	if err := carChaincode.Start(); err != nil {
		fmt.Printf("Error starting car supply chain chaincode: %v", err)
	}
}
