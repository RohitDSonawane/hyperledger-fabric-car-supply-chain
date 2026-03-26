#!/usr/bin/env bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

function createCustomer {
	infoln "Enrolling the CA admin"
	mkdir -p ../organizations/peerOrganizations/customer.example.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/customer.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca-customer --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-customer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-customer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-customer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-customer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/config.yaml"

	infoln "Registering peer0"
  set -x
	fabric-ca-client register --caname ca-customer --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-customer --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-customer --id.name customeradmin --id.secret customeradminpw --id.type admin --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-customer -M "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/msp" --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-customer -M "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls" --enrollment.profile tls --csr.hosts peer0.customer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null


  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/ca.crt"
  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/signcerts/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/server.crt"
  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/keystore/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/server.key"

  mkdir "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/tlscacerts"
  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/tlscacerts/ca.crt"

  mkdir "${PWD}/../organizations/peerOrganizations/customer.example.com/tlsca"
  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem"

  mkdir "${PWD}/../organizations/peerOrganizations/customer.example.com/ca"
  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/msp/cacerts/"* "${PWD}/../organizations/peerOrganizations/customer.example.com/ca/ca.customer.example.com-cert.pem"

  infoln "Generating the user msp"
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:11054 --caname ca-customer -M "${PWD}/../organizations/peerOrganizations/customer.example.com/users/User1@customer.example.com/msp" --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/customer.example.com/users/User1@customer.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
	fabric-ca-client enroll -u https://customeradmin:customeradminpw@localhost:11054 --caname ca-customer -M "${PWD}/../organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp" --tls.certfiles "${PWD}/fabric-ca/customer/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/customer.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp/config.yaml"
}
