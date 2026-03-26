#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0




# default to using Manufacturer
ORG=${1:-Manufacturer}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ORDERER_CA=${DIR}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
PEER0_MANUFACTURER_CA=${DIR}/organizations/peerOrganizations/manufacturer.example.com/tlsca/tlsca.manufacturer.example.com-cert.pem
PEER0_SHOWROOM_CA=${DIR}/organizations/peerOrganizations/showroom.example.com/tlsca/tlsca.showroom.example.com-cert.pem
PEER0_CUSTOMER_CA=${DIR}/organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem


if [[ ${ORG,,} == "manufacturer" || ${ORG,,} == "digibank" ]]; then

   CORE_PEER_LOCALMSPID=ManufacturerMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/organizations/peerOrganizations/manufacturer.example.com/users/Admin@manufacturer.example.com/msp
   CORE_PEER_ADDRESS=localhost:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/organizations/peerOrganizations/manufacturer.example.com/tlsca/tlsca.manufacturer.example.com-cert.pem

elif [[ ${ORG,,} == "showroom" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=ShowroomMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/organizations/peerOrganizations/showroom.example.com/users/Admin@showroom.example.com/msp
   CORE_PEER_ADDRESS=localhost:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/organizations/peerOrganizations/showroom.example.com/tlsca/tlsca.showroom.example.com-cert.pem

elif [[ ${ORG,,} == "customer" ]]; then

   CORE_PEER_LOCALMSPID=CustomerMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
   CORE_PEER_ADDRESS=localhost:11051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem

else
   echo "Unknown \"$ORG\", please choose Manufacturer/Digibank, Showroom/Magnetocorp, or Customer"
   echo "For example to get the environment variables for Customer, run: ./setOrgEnv.sh Customer"
   echo
   echo "This can be automated to set them as well with:"
   echo
   echo 'export $(./setOrgEnv.sh Showroom | xargs)'
   exit 1
fi

# output the variables that need to be set
echo "FABRIC_CFG_PATH=${DIR}/config"
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_MANUFACTURER_CA=${PEER0_MANUFACTURER_CA}"
echo "PEER0_SHOWROOM_CA=${PEER0_SHOWROOM_CA}"
echo "PEER0_CUSTOMER_CA=${PEER0_CUSTOMER_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
