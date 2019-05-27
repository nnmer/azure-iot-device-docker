#!/bin/bash

function checkExecStatus(){
    if [ $? -ne 0 ]; then
        echo ERROR, see the log.
        read Press any key to continue
        exit $?
    fi
}

function start()
{
    #
    # Install node dependencies
    #
    # yarn --cwd ./src install
    cd ./src
    npm install
    checkExecStatus
    cd ../

    #
    # Filesystem prepare
    #

    rm -fr ./scripts/certs/devices
    mkdir -p ./scripts/certs/devices

    rm -f ./scripts/index.txt
    touch ./scripts/index.txt

    rm -f ./scripts/certs/new-device*
    rm -f ./scripts/csr/new-device*
    rm -f ./scripts/newcerts/*
    rm -f ./scripts/private/new-device*

    #
    # Prepare docker-compose.yml file
    #
    cat > ./docker-compose.yml << EOL
version: '3'

services:
EOL


    #for idx in [1..$deviceDesiredNumber]
    for (( idx=1; idx<=$deviceDesiredNumber; idx++ ))
    do
        cd ./scripts
        sh ./certGen.sh create_device_certificate dev-${idx}

        mv ./certs/new-device.cert.pem ./certs/devices/dev-${idx}.cert.pem
        mv ./certs/new-device.cert.pfx ./certs/devices/dev-${idx}.cert.pfx
        mv ./private/new-device.key.pem ./certs/devices/dev-${idx}.key.pem
        mv ./csr/new-device.csr.pem ./certs/devices/dev-${idx}.csr.pem

        cat ./certs/devices/dev-${idx}.cert.pem ./certs/azure-iot-test-only.intermediate.cert.pem ./certs/azure-iot-test-only.root.ca.cert.pem > ./certs/devices/dev-${idx}-full-chain.cert.pem

        cd ../
        cat >> ./docker-compose.yml << EOL
  device-${idx}:
    image: node:8.12.0-jessie
    volumes:
      - ./src:/home/node/app
      - ./scripts/certs/devices/dev-${idx}.key.pem:/home/node/device-key-private.pem
      - ./scripts/certs/devices/dev-${idx}-full-chain.cert.pem:/home/node/device-key-public.pem
    working_dir: /home/node/app
    command:  'npm start'
    environment:
      - PROVISIONING_HOST=global.azure-devices-provisioning.net
      - ID_SCOPE=${dpsIdScope}
      - REGISTRATION_ID=dev-${idx}

EOL
    done
}





if [ $# -ne 2 ]; then
    echo "Usage: run-devices.sh XXX YYY"
    echo "       XXX # number of desired devices"
    echo "       YYY # your DPS service Id Scope value"
    exit 1
else
    deviceDesiredNumber=$1
    dpsIdScope=$2
    start
fi