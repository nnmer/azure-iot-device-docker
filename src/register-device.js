'use strict';

var fs = require('fs');
var Transport = require('azure-iot-provisioning-device-http').Http;

var X509Security = require('azure-iot-security-x509').X509Security;
var ProvisioningDeviceClient = require('azure-iot-provisioning-device').ProvisioningDeviceClient;

var provisioningHost = process.env.PROVISIONING_HOST;
if (!provisioningHost) {
  console.error('please set the PROVISIONING_HOST environment variable to the one you want to use. The default public provisioning host is: global.azure-devices-provisioning.net');
  process.exit(-1);
}

var idScope = process.env.ID_SCOPE;
if (!idScope) {
  console.error('please set the ID_SCOPE environment variable to the one you want to use.');
  process.exit(-1);
}

var registrationId = process.env.REGISTRATION_ID;
if (!registrationId) {
  console.error('please set the REGISTRATION_ID environment variable to the one you want to use.');
  process.exit(-1);
}


var register = function doRequest() {
    console.log('Start registration request')
    var deviceCert = {
        cert: fs.readFileSync('/home/node/device-key-public.pem').toString(),
        key: fs.readFileSync('/home/node/device-key-private.pem').toString()        
      };
    
    var transport = new Transport();
    var securityClient = new X509Security(registrationId, deviceCert);
    var deviceClient = ProvisioningDeviceClient.create(provisioningHost, idScope, transport, securityClient);

    
    return new Promise(function(resolve, reject){
        deviceClient.register(function(err, result) {
            if (err) {                
                reject(err)            
            } else {
                resolve([deviceClient, result]);            
            }
        });  
    })
}
// Register the device.  Do not force a re-registration.

exports.register = register;