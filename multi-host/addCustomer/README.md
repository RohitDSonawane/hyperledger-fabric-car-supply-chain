## Adding Customer to the test network

You can use the `addCustomer.sh` script to add another organization to the Fabric test network. The `addCustomer.sh` script generates the Customer crypto material, creates an Customer organization definition, and adds Customer to a channel on the test network.

You first need to run `./network.sh up createChannel` in the `test-network` directory before you can run the `addCustomer.sh` script.

```
./network.sh up createChannel
cd addCustomer
./addCustomer.sh up
```

If you used `network.sh` to create a channel other than the default `mychannel`, you need pass that name to the `addcustomer.sh` script.
```
./network.sh up createChannel -c channel1
cd addCustomer
./addCustomer.sh up -c channel1
```

You can also re-run the `addCustomer.sh` script to add Customer to additional channels.
```
cd ..
./network.sh createChannel -c channel2
cd addCustomer
./addCustomer.sh up -c channel2
```

For more information, use `./addCustomer.sh -h` to see the `addCustomer.sh` help text.
