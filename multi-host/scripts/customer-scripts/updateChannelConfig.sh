#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run by addCustomer.sh as the
# first step of the Adding an Org to a Channel tutorial.
# It creates and submits a configuration transaction to
# add customer to the test network

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
COUNTER=1
MAX_RETRY=5


# imports
# test network home var targets to test-network folder
# the reason we use a var here is considering with customer specific folder
# when invoking this for customer as test-network/scripts/customer-scripts
# the value is changed from default as $PWD (test-network)
# to ${PWD}/.. to make the import works
export TEST_NETWORK_HOME="${PWD}/.."
. ${TEST_NETWORK_HOME}/scripts/configUpdate.sh 

infoln "Creating config transaction to add customer to network"

# Fetch the config for the channel, writing it to config.json
fetchChannelConfig 1 ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/channel-artifacts/config.json

# If CustomerMSP already exists on the channel, skip update as idempotent success.
if jq -e '.channel_group.groups.Application.groups.CustomerMSP' ${TEST_NETWORK_HOME}/channel-artifacts/config.json >/dev/null 2>&1; then
	successln "CustomerMSP is already part of channel '${CHANNEL_NAME}'. Skipping config update."
	exit 0
fi

# Modify the configuration to append the new org
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"CustomerMSP":.[1]}}}}}' ${TEST_NETWORK_HOME}/channel-artifacts/config.json ${TEST_NETWORK_HOME}/organizations/peerOrganizations/customer.example.com/customer.json > ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json
{ set +x; } 2>/dev/null

# Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to customer_update_in_envelope.pb
createConfigUpdate ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/channel-artifacts/config.json ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json ${TEST_NETWORK_HOME}/channel-artifacts/customer_update_in_envelope.pb

infoln "Signing config transaction"
signConfigtxAsPeerOrg 1 ${TEST_NETWORK_HOME}/channel-artifacts/customer_update_in_envelope.pb
signConfigtxAsPeerOrg 2 ${TEST_NETWORK_HOME}/channel-artifacts/customer_update_in_envelope.pb

infoln "Submitting channel update from peer0.showroom with retries"
setGlobals 2
local_rc=1
COUNTER=1
while [ $local_rc -ne 0 -a $COUNTER -le $MAX_RETRY ]; do
	sleep $DELAY
	set -x
	peer channel update -f ${TEST_NETWORK_HOME}/channel-artifacts/customer_update_in_envelope.pb -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	local_rc=$res
	if [ $local_rc -ne 0 ]; then
		infoln "Attempt ${COUNTER}/${MAX_RETRY} failed while updating channel config. Retrying in ${DELAY}s..."
	fi
	COUNTER=$(expr $COUNTER + 1)
done

cat log.txt
verifyResult $local_rc "Unable to submit config tx to add CustomerMSP on channel '${CHANNEL_NAME}'"

successln "Config transaction to add customer to network submitted"
