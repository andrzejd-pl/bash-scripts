# bash_scripts

## Table of content

1. [network](#network)
    1. [turn_on_custom_gateway](#turnoncustomgateway)

## network

### turn_on_custom_gateway

#### description

The script creates a gateway on a machine that is connected to two different networks. It automatically manages a gateway.

I wrote this script to automatically create a gateway in my local network. I use this to create a backup connection when my internet was gone. I tested 

The script detects when an interface is connected and then add rules to `iptables` and create/update a route to use as the primary route. When the incoming interface is down, it cleans up the rules.
It works in the infinity loop.

***It must run with root priviliges!!!!***

#### examples

- with params
```bash
./turn_on_custom_gateway.sh eth0 wlan0 192.168.0.1 20 10 2
```

- with default params
```bash
./turn_on_custom_gateway.sh
```

#### params

```bash
./turn_on_custom_gateway.sh INTERFACE_IN INTERFACE_OUT BASE_FOREIGN_GATEWAY ROUTE_METRIC SLEEP_INIT_WAIT SLEEP_LOOP
```

- `INTERFACE_IN` - define a interface which will be used as default gateway in the machine; default value: `eth1`
- `INTERFACE_OUT` - define a interface which will be used to share connection from `INTERFACE_IN`; default value: `eth0`
- `BASE_FOREIGN_GATEWAY` - define which IP from `INTERFACE_IN` network will be used to share connection; default value: `172.20.10.1`
- `ROUTE_METRIC` - define a priorit for record in routing table; if you want to interface as primary connection fill this whit small value; when you want use only to connect 2 networks use a value greaten than default route; default value: `50`
- `SLEEP_INIT_WAIT` - default value: `10`
- `SLEEP_LOOP` - default value: `2`
