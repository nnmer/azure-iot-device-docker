#!/bin/bash

checkExecStatus(){
    if [ $? -ne 0 ]; then
        echo ERROR, see the log.
        read Press any key to continue
        exit $?
    fi
}

start()
{
    #
    # Install node dependencies
    #
    # yarn --cwd ./src install
    # cd ./src
    # npm install
    # checkExecStatus
    # cd ../

    #
    # Filesystem prepare
    #
    rm -fr ./scripts/build/certs/edge
    mkdir -p ./scripts/build/certs/edge

    rm -f ./scripts/build/index.txt
    touch ./scripts/build/index.txt

    #
    # Generate edge device certificates    
    #
   
    cd ./scripts
    sh ./certGen.sh create_edge_device_certificate edge-device
    mv ./build/certs/new-edge-device.cert.pem ./build/certs/edge/edge-device.cert.pem
    mv ./build/certs/new-edge-device.cert.pfx ./build/certs/edge/edge-device.cert.pfx
    mv ./build/private/new-edge-device.key.pem ./build/certs/edge/edge-device.key.pem
    mv ./build/csr/new-edge-device.csr.pem ./build/certs/edge/edge-device.csr.pem    

    cat ./build/certs/edge/edge-device.cert.pem ./build/certs/azure-iot-test-only.intermediate.cert.pem ./build/certs/azure-iot-test-only.root.ca.cert.pem > ./build/certs/edge/edge-device-full-chain.cert.pem    

    #
    # Install certificates on edge device
    # @url https://docs.microsoft.com/en-us/azure/iot-edge/how-to-create-transparent-gateway#install-certificates-on-the-gateway
    #
    



    cp edge-provision.sh ./build/certs/edge/edge-provision.sh
    cat > ./build/certs/edge/Dockerfile << EOL
FROM toolboc/azure-iot-edge-device-container
COPY edge-provision.sh /usr/local/bin/
EOL

    az iot hub device-identity create --device-id ${edgeDeviceName} --hub-name ${iothubName} --edge-enabled
    edgeDeviceConnectionString=$(az iot hub device-identity show-connection-string --device-id ${edgeDeviceName} --hub-name ${iothubName} --query="connectionString")

    # this is a hack as edge device need a registered module to be fully registered at IoT Hub
    az iot edge set-modules --device-id ${edgeDeviceName} --hub-name ${iothubName} --content ./edge-deployment-schema.json

    cd ../
    #
    # Prepare docker-compose.yml file
    #
    cat > ./docker-compose.yml << EOL
version: '3'

services:
  edge-device:
    build:
      context: ./scripts/build/certs/edge/
    privileged: true
    environment:
      connectionString: ${edgeDeviceConnectionString}
      IOTEDGE_HOMEDIR: /var/lib/iotedge
    ports:
      - "8883:8883"
      - "5671:5671"
      - "443:443"
    volumes:
      - ./scripts/build/certs/edge/config-append.conf:/edge-certs/config-append.conf
      - ./scripts/build/certs/edge/edge-device.key.pem:/edge-certs/device-key-private.pem
      - ./scripts/build/certs/edge/edge-device-full-chain.cert.pem:/edge-certs/device-full-chain.pem
      - ./scripts/build/certs/azure-iot-test-only.root.ca.cert.pem:/edge-certs/trusted_ca.pem

EOL


    #for idx in [1..$deviceDesiredNumber]
    for (( idx=1; idx<=$deviceDesiredNumber; idx++ ))
    do
        az iot hub device-identity create --device-id dev-${idx} --hub-name ${iothubName}
        deviceConnectionString=$(az iot hub device-identity show-connection-string --device-id dev-${idx} --hub-name ${iothubName} --query="connectionString")

        cat >> ./docker-compose.yml << EOL
  device-${idx}:
    image: node:8.12.0-jessie
    volumes:
      - ./src:/home/node/app
      - ./scripts/build/certs/azure-iot-test-only.root.ca.cert.pem:/home/cert/ca.cert.pem
    working_dir: /home/node/app
    command:  'npm run start-iotedge-downstream-device'
    environment:
      DEVICE_CONNECTION_STRING: ${deviceConnectionString}
      REGISTRATION_ID: dev-${idx}
    depends_on:
      - edge-device
    

EOL
    done
}





if [ $# -ne 3 ]; then
    echo "Usage: run-edge-dev.sh WWW XXX YYY ZZZ"
    echo "       WWW # IoT Hub name where devices would be aassigned to"
    echo "       XXX # number of desired devices"
    echo "       YYY # edge device name"
    exit 1
else
    iothubName=$1
    deviceDesiredNumber=$2
    edgeDeviceName=$3
    start
fi