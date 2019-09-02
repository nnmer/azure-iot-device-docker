'use strict';


var fs = require('fs');
var uuid = require('uuid');
var Protocol = require('azure-iot-device-mqtt').Mqtt;
// Uncomment one of these transports and then change it in fromConnectionString to test other transports
// var Protocol = require('azure-iot-device-amqp').AmqpWs;
// var Protocol = require('azure-iot-device-http').Http;
// var Protocol = require('azure-iot-device-amqp').Amqp;
// var Protocol = require('azure-iot-device-mqtt').MqttWs;
var Client = require('azure-iot-device').Client;
var Message = require('azure-iot-device').Message;


var registration = require('./register-device');
// String containing Hostname, Device Id & Device Key in the following formats:
//  "HostName=<iothub_host_name>;DeviceId=<device_id>;SharedAccessKey=<device_key>"

// if (!connectionString) {
//   console.log('Please set the DEVICE_CONNECTION_STRING environment variable.');
//   process.exit(-1);
// }

// var client = Client.fromConnectionString(connectionString, Protocol);

function getRndInteger(min, max) {
  return Math.floor(Math.random() * (max - min + 1) ) + min;
}

// fromConnectionString must specify a transport constructor, coming from any transport package.
registration.register()
.then(function([authResults, regResult]){
  console.log('registration succeeded');
  console.log('assigned hub=' + regResult.assignedHub);
  console.log('deviceId=' + regResult.deviceId);
  //console.log('result=' + JSON.stringify(authResults));
  console.log('result=' + JSON.stringify(regResult));

  var connectionString = "HostName="+regResult.assignedHub+";DeviceId="+regResult.deviceId+";x509=true";
  console.log(connectionString)
  var client = Client.fromConnectionString(connectionString, Protocol);
  client.setOptions({
    cert: fs.readFileSync('/home/node/device-key-public.pem').toString(),
    key: fs.readFileSync('/home/node/device-key-private.pem').toString()
  })

  var connectCallback = function (err) {
    if (err) {
      console.error('Could not connect: ' + err.message);
    } else {
      var randValue = 15000;

      console.log('Client connected. Sending messages each '+randValue+'s');
      // while (1) {
        
        var interval = setInterval( function(){
          
          // any type of data can be sent into a message: bytes, JSON...but the SDK will not take care of the serialization of objects.
          var id = uuid.v4();
          var message = new Message(JSON.stringify({
            //_id: id,
            id: id,
            key: 'value',
            theAnswer: randValue
          }));
          // A message can have custom properties that are also encoded and can be used for routing
          message.properties.add('propertyName', 'propertyValue');

          // A unique identifier can be set to easily track the message in your application
          console.log('Sending message: ' + message.getData());
          
          message.messageId = uuid.v4();
        
           client.sendEvent(message, function (err, res) {
            if (err) {
              console.error('Could not send: ' + err.toString());
            } 
            
            if (res) {
              console.log('Message sent: ' + JSON.stringify(res));
            }
          })},
          randValue

        );

        client.on('error', function (err) {
          console.error(err.message);
        });

        client.on('disconnect', function() {        
          clearInterval(sendInterval);
          client.removeAllListeners();
          client.open(connectCallback);
        })
  
        client.on('message', function (msg) {
          console.log('Id: ' + msg.messageId + ' Body: ' + msg.data);
          // When using MQTT the following line is a no-op.
          client.complete(msg, printResultFor('completed'));
          // The AMQP and HTTP transports also have the notion of completing, rejecting or abandoning the message.
          // When completing a message, the service that sent the C2D message is notified that the message has been processed.
          // When rejecting a message, the service that sent the C2D message is notified that the message won't be processed by the device. the method to use is client.reject(msg, callback).
          // When abandoning the message, IoT Hub will immediately try to resend it. The method to use is client.abandon(msg, callback).
          // MQTT is simpler: it accepts the message by default, and doesn't support rejecting or abandoning a message.
        });

        // clearInterval(interval);
        //       randValue = getRndInteger(0.1,2) *1000;
        
      // }
    }
  };
  client.open(connectCallback);

})
.catch(function(error){
  console.log("error registering device: " + error);
  process.exit(-1)
})