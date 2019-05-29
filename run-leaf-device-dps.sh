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

    rm -fr ./scripts/build/certs/devices
    mkdir -p ./scripts/build/certs/devices

    rm -f ./scripts/build/index.txt
    touch ./scripts/build/index.txt

    rm -f ./scripts/build/certs/new-device*
    rm -f ./scripts/build/csr/new-device*
    rm -f ./scripts/build/newcerts/*
    rm -f ./scripts/build/private/new-device*

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

        mv ./build/certs/new-device.cert.pem ./build/certs/devices/dev-${idx}.cert.pem
        mv ./build/certs/new-device.cert.pfx ./build/certs/devices/dev-${idx}.cert.pfx
        mv ./build/private/new-device.key.pem ./build/certs/devices/dev-${idx}.key.pem
        mv ./build/csr/new-device.csr.pem ./build/certs/devices/dev-${idx}.csr.pem

        cat ./build/certs/devices/dev-${idx}.cert.pem ./build/certs/azure-iot-test-only.intermediate.cert.pem ./build/certs/azure-iot-test-only.root.ca.cert.pem > ./build/certs/devices/dev-${idx}-full-chain.cert.pem

        cd ../
        cat >> ./docker-compose.yml << EOL
  device-${idx}:
    image: node:8.12.0-jessie
    volumes:
      - ./src:/home/node/app
      - ./scripts/build/certs/devices/dev-${idx}.key.pem:/home/node/device-key-private.pem
      - ./scripts/build/certs/devices/dev-${idx}-full-chain.cert.pem:/home/node/device-key-public.pem
    working_dir: /home/node/app
    command:  'npm run start-leaf-device-dps'
    environment:
      - PROVISIONING_HOST=global.azure-devices-provisioning.net
      - ID_SCOPE=${dpsIdScope}
      - REGISTRATION_ID=dev-${idx}

EOL
    done
}





if [ $# -ne 2 ]; then
    echo "Usage: run-leaf-device-dps.sh XXX YYY"
    echo "       XXX # number of desired devices"
    echo "       YYY # your DPS service Id Scope value"
    exit 1
else
    deviceDesiredNumber=$1
    dpsIdScope=$2
    start
fi