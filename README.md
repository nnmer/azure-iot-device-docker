The purpose of this repository is to have an easy running sample of simulated devices packaged into docker containers.

2 cases:
- with authorization via X.509 certificate and group enrollment into Azure IoT Hub
- a device connected to IoTHub via IoT Edge

**Note: this is only for a demo and tests purposes, not for production.**

Example is based on some [azure-iot-samples-node](https://github.com/Azure-Samples/azure-iot-samples-node) code.

Next files are taken from the [Azure/azure-iot-sdk-c](https://github.com/Azure/azure-iot-sdk-c/tree/master/tools/CACertificates) repository:

- ./scripts/certGen.sh
- ./scripts/openssl_device_intermediate_ca.cnf
- ./scripts/openssl_root_ca.cnf


## Preparation

You need to have installed on your system:
- docker-ce 
- nodejs runtime

## Leaf device -> IoT Hub register with DPS and X.509

**Note**
If you are using **not** a global azure then change the file run-leaf-device-dps.sh at string
```
- PROVISIONING_HOST=global.azure-devices-provisioning.net
```
to correct global.azure-devices-provisioning.**XXX**

### Step 1.

Create Azure IoT Hub and DPS services, link them together. [Azure Docs for reference](https://docs.microsoft.com/en-us/azure/iot-dps/quick-setup-auto-provision)

### Step 2.

In root folder of the repo run:
```
bash run-init.sh
```

This will generate X.509 root certificate and verification certificate. 
When you will be prompted to provide verification code do next:
- go to *Azure DPS > Certificates* and add generated certificate, which is saved at *./scripts/build/certs/azure-iot-test-only.root.ca.cert.pem* .
- generate verification code for the certificate and provide it to the script
- add a verification certificate to your certificate settings at Azure DPS. The verification certificate is saved at *./scripts/build/certs/verification-code.cert.pem*


### Step 3a.

Go to "Azure DPS > Manage enrollments" and create your group enrollment, select your certificate from the list

### Step 3b.

Add a proper "IoTHub at Azure DPS > Linked IoT hubs"

### Step 4.

run:
```
run-leaf-device-dps.sh {Number_Of_Desired_Devices} {ID_Scope_Of_Your_Azure_DPS_Service}
docker-composer up
```

at this point you should have desired number of containers (devices) running and sending telemetry to your Azure IoT Hub





## Leaf device -> IoT Edge -> IoT Hub

Precondition:
- have azure-cli installed
- azure iot extension: **az extension add --name azure-cli-iot-ext**
- have IoT Hub created
- run **az login** if didn't run it yet

### Step 1

In root folder of the repo run:
```
bash run-init.sh
```

This will generate X.509 root certificate and verification certificate. 
When you will be prompted to provide verification code write any info (verification certificate will not be used in this case)


### Step 2

create CA cert for Edge device

```
sh run-edge-dev.sh <IoTHub-Name> <Number-Of-Leaf-Devices> <IoTEdge-Name>
```

### Step 3

```
docker-compose up
```

Be patiant, it may take a while while edge device finish startup communication with IoT Hub