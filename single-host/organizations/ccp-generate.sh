#!/usr/bin/env bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${ORG_LOWER}/$2/g" \
        -e "s/\${P0PORT}/$3/g" \
        -e "s/\${CAPORT}/$4/g" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${ORG_LOWER}/$2/g" \
        -e "s/\${P0PORT}/$3/g" \
        -e "s/\${CAPORT}/$4/g" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

# Manufacturer
NAME="Manufacturer"
LOWER="manufacturer"
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/manufacturer.example.com/tlsca/tlsca.manufacturer.example.com-cert.pem
CAPEM=organizations/peerOrganizations/manufacturer.example.com/ca/ca.manufacturer.example.com-cert.pem

echo "$(json_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/manufacturer.example.com/connection-manufacturer.json
echo "$(yaml_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/manufacturer.example.com/connection-manufacturer.yaml

# Showroom
NAME="Showroom"
LOWER="showroom"
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/showroom.example.com/tlsca/tlsca.showroom.example.com-cert.pem
CAPEM=organizations/peerOrganizations/showroom.example.com/ca/ca.showroom.example.com-cert.pem

echo "$(json_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/showroom.example.com/connection-showroom.json
echo "$(yaml_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/showroom.example.com/connection-showroom.yaml
