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
        -e "s/\${CAPPORT}/$4/g" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${ORG_LOWER}/$2/g" \
        -e "s/\${P0PORT}/$3/g" \
        -e "s/\${CAPPORT}/$4/g" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

# Customer
NAME="Customer"
LOWER="customer"
P0PORT=11051
CAPORT=11054
PEERPEM=../organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem
CAPEM=../organizations/peerOrganizations/customer.example.com/ca/ca.customer.example.com-cert.pem

echo "$(json_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > ../organizations/peerOrganizations/customer.example.com/connection-customer.json
echo "$(yaml_ccp $NAME $LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > ../organizations/peerOrganizations/customer.example.com/connection-customer.yaml
