The purpose of this repository is to have an easy running sample of simulated devices packaged into docker containers with authorization via X.509 certificate and group enrollment into Azure IoT Hub.

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

## Run Steps 

**Note**
If you are using **not** a global azure then change the file run-provision-devices.sh at string
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

This will generate X.509 certificate and verification certificate. 
When you will be prompted to provide verification code do next:
- go to *Azure DPS > Certificates* and add generated certificate, which is saved at *./scripts/certs/azure-iot-test-only.root.ca.cert.pem* .
- generate verification code for the certificate and provide it to the script
- add a verification certificate to your certificate settings at Azure DPS. The verification certificate is saved at *./scripts/certs/verification-code.cert.pem*


### Step 3a.

Go to "Azure DPS > Manage enrollments" and create your group enrollment, select your certificate from the list

### Step 3b.

Add a proper "IoTHub at Azure DPS > Linked IoT hubs"

### Step 4.

run:
```
run-provision-devices.sh {Number_Of_Desired_Devices} {ID_Scope_Of_Your_Azure_DPS_Service}
docker-composer up
```

at this point you should have desired number of containers (devices) running and sending telemetry to your Azure IoT Hub