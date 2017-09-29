package main

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"

	SignUtil "github.com/hyperhq/websocket-client/go/util"

	"github.com/gorilla/websocket"
)

type FlagParam []string

func (f *FlagParam) String() string {
	return "string method"
}

func (f *FlagParam) Set(value string) error {
	*f = strings.Split(value, ",")
	return nil
}

func main() {

	//command line argument
	var filters FlagParam
	var addr = flag.String("addr", "us-west-1.hyper.sh:443", "ApiRouter entrypoint")
	var accessKey = flag.String("accessKey", "", "Hyper.sh Access Key")
	var secretKey = flag.String("secretKey", "", "Hyper.sh Secret Key")
	var region = flag.String("region", "us-west-1", "Hyper.sh region name, could be us-west-1|eu-central-1|RegionOne")
	var pretty = flag.Bool("pretty", false, "Output result json as prettyprint JSON")
	flag.Var(&filters, "filter", "Filter event by container,image,label,event, example 'container=test,image=busybox,label=key=value,event=start'")

	flag.Parse()
	log.SetFlags(0)

	//check accessKey and secretKey
	if *accessKey == "" || *secretKey == "" {
		log.Printf("Please specify 'accessKey' and 'secretKey'!")
		return
	}

	//Example: query parameter - format: "filters={\"param1\":{\"value1\":true,\"value2\":true}}"
	//var queryParam = "filters={\"container\":{\"955fb7fed391d325bed5b7f85c05824e3bd035b0f5d9aa30ca87c6169d075148\":true}}"
	//var queryParam = "filters={\"image\":{\"e02e811dd08fd49e7f6032625495118e63f597eb150403d02e3238af1df240ba\":true}}"
	//var queryParam = "filters={\"event\":{\"start\":true}}"
	//var queryParam = "filters={\"label\":{\"\":true,\"test1\":true,\"test2=test2\":true,\"test3=test3=test3\":true}}"
	var queryParam string = ""

	if filters != nil {
		formattedFilter, err := formatFilter(&filters)
		if err != nil {
			log.Printf("Error: %v", err)
			return
		}
		queryParam = fmt.Sprintf("filters=%s", *formattedFilter)
	}
	var u = url.URL{Scheme: "wss", Host: *addr, Path: "/events/ws", RawQuery: queryParam}

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	//add sign to header
	req, err := http.NewRequest("GET", u.String(), nil)
	log.Printf("connecting to %s://%s%s", req.URL.Scheme, req.Host, req.URL.RequestURI())
	//log.Printf("query: %v", req.URL.Query())
	req.URL = &u
	req = SignUtil.Sign4(*accessKey, *secretKey, req, *region)

	//connect to websocket server
	config := &tls.Config{
		InsecureSkipVerify: true,
	}
	dialer := websocket.Dialer{
		TLSClientConfig: config,
	}

	ws, resp, err := dialer.Dial(u.String(), req.Header)

	if resp.StatusCode == http.StatusSwitchingProtocols {
		log.Print("connected, watching event now:")
	}

	var data []byte
	if resp.ContentLength > 0 {
		defer resp.Body.Close()
		data, _ = ioutil.ReadAll(resp.Body)
	}

	if err != nil {
		log.Fatalf("Error Result:\n status    : %v\n return    : %v", resp.Status, string(data))
	}

	defer ws.Close()

	//process websocket message
	go func() {
		defer ws.Close()
	loop:
		for {
			_, message, err := ws.ReadMessage()
			if err != nil {
				log.Println("Error:", err)
				break loop
			}
			if *pretty {
				//outpu pretty print json
				var dat map[string]interface{}
				if err := json.Unmarshal([]byte(message), &dat); err != nil {
					panic(err)
				}
				b, err := json.MarshalIndent(dat, "", "  ")
				if err != nil {
					panic(err)
				}
				log.Printf("%v\n", string(b[:]))
			} else {
				log.Printf("%s", message)
			}
		}
	}()

	for {
		select {
		case <-interrupt:
			log.Println("Interrupt by Ctrl+C")
			err := ws.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				//log.Println("write close:", err)
				return
			}
			ws.Close()
			return
		}
	}
}

//format filter to json string
func formatFilter(filters *FlagParam) (*string, error) {
	result := map[string]map[string]bool{}
	for _, v := range *filters {
		//log.Printf("[Debug] original filter: %v", v)
		item := strings.SplitN(v, "=", 2)
		lenItem := len(item)
		switch {
		case item[0] == "container" || item[0] == "image" || item[0] == "event" || item[0] == "label":
			if lenItem == 1 {
				return nil, errors.New(fmt.Sprintf("Wrong filter format for [%v]", item[0]))
			} else {
				mm, ok := result[item[0]]
				if !ok {
					mm = make(map[string]bool)
					result[item[0]] = mm
				}
				mm[item[1]] = true
			}
		case item[0] == "":
			return nil, errors.New("filter name can not be empty")
		default:
			return nil, errors.New(fmt.Sprintf("filter only support container,image,label,event"))
		}
	}
	b, _ := json.Marshal(result)
	strResult := string(b)
	return &strResult, nil
}
