websocket client(golang) for Hyper.sh
=====================================

Websocket client example for use websocket api `/events/ws` of Hyper.sh

# Usage

There are two ways to run websocket client.
- run wsclient.go
- use ./util.sh (wrapper for wsclient.go)

```
//The first thing is : fetch client code
$ go get github.com/hyperhq/websocket-client/
$ cd $GOPATH/src/github.com/hyperhq/websocket-client/go
```

## run wsclient.go

### view help of wsclient.go

```
$ go run wsclient.go --help   
Usage of /tmp/go-build045314814/command-line-arguments/_obj/exe/wsclient:
  -accessKey string
    	Hyper.sh Access Key
  -addr string
    	ApiRouter entrypoint (default "us-west-1.hyper.sh:443")
  -filter value
    	Filter event by container,image,label,event, example 'container=test,image=busybox,label=key=value,event=start' (default string method)
  -pretty
    	Output result json as prettyprint JSON
  -secretKey string
    	Hyper.sh Secret Key
```

### prepare credential environment variable
```
//set HYPER_ACCESS_KEY and HYPER_SECRET_KEY of Hyper.sh
$ export HYPER_ACCESS_KEY=xxxxx
$ export HYPER_SECRET_KEY=xxxxxx
```

### Watch all events

`accessKey` and `secretKey` are required options

```
$ go run wsclient.go --accessKey $HYPER_ACCESS_KEY  --secretKey $HYPER_SECRET_KEY
connecting to wss://us-west-1.hyper.sh:443/events/ws
connected, watching event now:
{"status":"start","id":"f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179","from":"xjimmyshcn/busybox","Type":"container","Action":"start","Actor":{"ID":"f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179","Attributes":{"":"","exitCode":"0","image":"xjimmyshcn/busybox","name":"test4","sh_hyper_instancetype":"s4","test1":"","test2":"test2","test3":"test3=test3"}},"time":1476375774,"timeNano":1476375774255155116}
{"status":"stop","id":"f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179","from":"xjimmyshcn/busybox","Type":"container","Action":"stop","Actor":{"ID":"f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179","Attributes":{"":"","exitCode":"0","image":"xjimmyshcn/busybox","name":"test4","sh_hyper_instancetype":"s4","test1":"","test2":"test2","test3":"test3=test3"}},"time":1476375778,"timeNano":1476375778304732322}
```

### Output pretty event json

use option `--pretty`

```
$ go run wsclient.go --accessKey $HYPER_ACCESS_KEY  --secretKey $HYPER_SECRET_KEY --pretty
connecting to wss://us-west-1.hyper.sh:443/events/ws
connected, watching event now:
{
  "Action": "start",
  "Actor": {
    "Attributes": {
      "": "",
      "exitCode": "0",
      "image": "xjimmyshcn/busybox",
      "name": "test4",
      "sh_hyper_instancetype": "s4",
      "test1": "",
      "test2": "test2",
      "test3": "test3=test3"
    },
    "ID": "f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179"
  },
  "Type": "container",
  "from": "xjimmyshcn/busybox",
  "id": "f29698cac3f6f66e84790fb12b3e5e4f3455b89b3ff12150ac4d86b8b90d9179",
  "status": "start",
  "time": 1.476375852e+09,
  "timeNano": 1.4763758521916593e+18
}
```

### Watch event with filter

use option `--filter`, support filter by `container,image,label,event`
- **container**: container id or name
- **image**: imageid or name
- **label**: label of container
- **event**: `start|stop`

```
$ go run wsclient.go --accessKey $HYPER_ACCESS_KEY  --secretKey $HYPER_SECRET_KEY  --filter=container=test4,image=busybox,event=stop,label=test1,label=test2=test2
```

# Test filter with util.sh

./util.sh makes start websocket client with filter easier.

## view help of util.sh
```
$ ./util.sh
Usage: ./util.sh <ACTION> [OPTION]

<ACTION>:
 - ps                        : list test container
 - run                       : run test container
 - stop                      : stop test container
 - start                     : start test container
 - rm                        : remove test container
 - test <FILTER> [CASE_NO]   : run test case

<FILTER>:
 - container : use container.lst
 - image     : use image.lst
 - label     : use label.lst
 - event     : use event.lst

[CASE_NO]:
 - <empty>     : show all test case NO.
 - <not empty> : start websocket client to watch with filter

Example:
  ./util.sh run
  ./util.sh watch container
  ./util.sh watch container 1
  ./util.sh stop
```

## config

modify the following parameter in etc/config:

- **G_API_ROUTER**: default is "us-west-1.hyper.sh:443"

## manage test container
```
//run test container
./util.sh run

//list test container
./util.sh ps

//stop test container
./util.sh stop

//start test container
./util.sh start

//remove test client
./util.sh rm
```

## manage test case
```
//list test case NO.
./util.sh watch container

//start specified test client.
./util.sh watch container 1
```


# FAQ:

## wrong Hyper.sh Credential
```
$ go run wsclient.go --accessKey xxx --secretKey xxx
connecting to wss://us-west-1.hyper.sh:443/events/ws
Error:websocket: bad handshake
exit status 1
```

## how to watch docker events via remote api
```
$ curl -g 'http://127.0.0.1:2375/events?filters={"container":{"test":true},"image":{"busybox":true},"label":{"test1":true,"test2=test2":true,"test3=test3=test3":true},"event":{"start":true,"stop":true}}'

{"status":"start","id":"6c0902c750c73d4bee6cecc82b1a6e3f36f625f65cfd5417fdb09e5b9a2f7d16","from":"busybox","Type":"container","Action":"start","Actor":{"ID":"6c0902c750c73d4bee6cecc82b1a6e3f36f625f65cfd5417fdb09e5b9a2f7d16","Attributes":{"image":"busybox","name":"test","sh_hyper_instancetype":"s4","test1":"","test2":"test2","test3":"test3=test3"}},"time":1476419660,"timeNano":1476419660534483726}
{"status":"stop","id":"6c0902c750c73d4bee6cecc82b1a6e3f36f625f65cfd5417fdb09e5b9a2f7d16","from":"busybox","Type":"container","Action":"stop","Actor":{"ID":"6c0902c750c73d4bee6cecc82b1a6e3f36f625f65cfd5417fdb09e5b9a2f7d16","Attributes":{"image":"busybox","name":"test","sh_hyper_instancetype":"s4","test1":"","test2":"test2","test3":"test3=test3"}},"time":1476419662,"timeNano":1476419662997733372}
```
