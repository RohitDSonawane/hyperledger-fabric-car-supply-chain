#!/usr/bin/env bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
# test network home var targets to test-network folder
# the reason we use a var here is to accommodate scenarios
# where execution occurs from folders outside of default as $PWD, such as the test-network/addCustomer folder.
# For setting environment variables, simple relative paths like ".." could lead to unintended references
# due to how they interact with FABRIC_CFG_PATH. It's advised to specify paths more explicitly,
# such as using "../${PWD}", to ensure that Fabric's environment variables are pointing to the correct paths.
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
. ${TEST_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export PEER0_MANUFACTURER_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/manufacturer.example.com/tlsca/tlsca.manufacturer.example.com-cert.pem
export PEER0_SHOWROOM_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/showroom.example.com/tlsca/tlsca.showroom.example.com-cert.pem
export PEER0_CUSTOMER_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID=ManufacturerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MANUFACTURER_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/manufacturer.example.com/users/Admin@manufacturer.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID=ShowroomMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SHOWROOM_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/showroom.example.com/users/Admin@showroom.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID=CustomerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CUSTOMER_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    if [ "$1" -eq 1 ]; then
      PEER="peer0.manufacturer"
      CA=PEER0_MANUFACTURER_CA
    elif [ "$1" -eq 2 ]; then
      PEER="peer0.showroom"
      CA=PEER0_SHOWROOM_CA
    elif [ "$1" -eq 3 ]; then
      PEER="peer0.customer"
      CA=PEER0_CUSTOMER_CA
    fi

    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
