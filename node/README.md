websocket client(nodejs) for Hyper.sh
=====================================

# Usage
```
npm install websocket hyper-aws4

export HYPER_ACCESS=xxxx
export HYPER_SECRET=xxxxxxx

node wsclient.js
```

# Example
```
$ node wsclient.js                                            
connecting to wss://us-west-1.hyper.sh:443/events/ws
connected, watching event now
Received: '{"status":"start","id":"db0968ca16e0ca13cd4d1c5ff6175d03bff9a25e8924bf08d05a2c41151d7d79","from":"alpine","Type":"container","Action":"start","Actor":{"ID":"db0968ca16e0ca13cd4d1c5ff6175d03bff9a25e8924bf08d05a2c41151d7d79","Attributes":{"":"","empty":"","exitCode":"0","id":"test1","image":"alpine","key":"test1=test1","name":"wstest2","sh.hyper.fip":"","sh_hyper_instancetype":"s1","type":"test"}},"time":1477034060,"timeNano":1477034060936154675}'
Received: '{"status":"start","id":"db0968ca16e0ca13cd4d1c5ff6175d03bff9a25e8924bf08d05a2c41151d7d79","from":"alpine","Type":"container","Action":"start","Actor":{"ID":"db0968ca16e0ca13cd4d1c5ff6175d03bff9a25e8924bf08d05a2c41151d7d79","Attributes":{"":"","empty":"","exitCode":"0","id":"test1","image":"alpine","key":"test1=test1","name":"wstest2","sh.hyper.fip":"","sh_hyper_instancetype":"s1","type":"test"}},"time":1477034069,"timeNano":1477034069075899928}'
```
