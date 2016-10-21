#!/usr/bin/env node

var WebSocketClient = require('websocket').client;
var aws4 = require('hyper-aws4')

if (!process.env.HYPER_ACCESS || !process.env.HYPER_SECRET) {
    console.log("Error: please set env HYPER_ACCESS and HYPER_SECRET first")
    return
}

//disable SSL checking in Node
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

var client = new WebSocketClient();

client.on('connectFailed', function(error) {
    console.log('Connect Error: ' + error.toString());
});

client.on('connect', function(connection) {
    console.log('connected, watching event now');
    connection.on('error', function(error) {
        console.log("Connection Error: " + error.toString());
    });
    connection.on('close', function() {
        console.log('echo-protocol Connection Closed');
    });
    connection.on('message', function(message) {
        if (message.type === 'utf8') {
            console.log("Received: '" + message.utf8Data + "'");
        }
    });
});


//singv4
var signOption = {
    url: 'wss://us-west-1.hyper.sh:443/events/ws',
    method: 'GET',
    credential: {
        accessKey: process.env.HYPER_ACCESS,
        secretKey: process.env.HYPER_SECRET
    }
}
var headers = aws4.sign(signOption)

console.log("connecting to", signOption.url)
client.connect(signOption.url, '', null, headers);
