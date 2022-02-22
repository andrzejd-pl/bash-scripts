#!/bin/bash

INTERFACE_IN='eth1'
INTERFACE_OUT='eth0'
BASE_FOREIGN_GATEWAY='172.20.10.1'
ROUTE_METRIC=50
SLEEP_INIT_WAIT=10
SLEEP_LOOP=2

if [ ! -z $1 ]; then INTERFACE_IN=$1; fi
if [ ! -z $2 ]; then INTERFACE_OUT=$2; fi
if [ ! -z $3 ]; then BASE_FOREIGN_GATEWAY=$3; fi
if [ ! -z $4 ]; then ROUTE_METRIC=$4; fi
if [ ! -z $5 ]; then SLEEP_INIT_WAIT=$5; fi
if [ ! -z $6 ]; then SLEEP_LOOP=$6; fi

count_routes () {
	if [ -z $2 ]; then
		ip route show default dev $1 | wc -l
	else
		ip route show default dev $1 metric $2 | wc -l
	fi
}

add_iptables () {
	if [ ! `iptables -S POSTROUTUNG -t nat | grep ${1}` ]; then
		iptables -t nat -A POSTROUTING -o ${1} -j MASQUERADE
	fi
	if [ ! `iptables -S FORWARD | grep -E '\-A[ ]FORWARD[ ]\-m[ ]conntrack[ ]\-\-ctstate[ ]RELATED\,ESTABLISHED[ ]\-j[ ]ACCEPT'` ]; then
		iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	fi
	if [ ! `iptables -S FORWARD | grep ${1}` ]; then
		iptables -A FORWARD -i ${2} -o ${1} -j ACCEPT
	fi
}

turn_on_gateway () {
	ip route add default via $3 dev $1 metric $4
	echo "NEW ROUTE ADDED"

	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo "ALLOW TO PORT FORWARDING"

	add_iptables $1 $2
	echo "ADD NAT TO IPTABLES"

}

while true; do
	sleep $SLEEP_LOOP

	if [ -f /sys/class/net/$INTERFACE_IN/carrier ] && [ -f /sys/class/net/$INTERFACE_IN/operstate ] && [ `grep "1" /sys/class/net/$INTERFACE_IN/carrier` ] && [ `grep -E '(up)|(unknown)' /sys/class/net/$INTERFACE_IN/operstate` ]; then
		echo "CONNECTED"
		sleep $SLEEP_INIT_WAIT
	else
		echo "DISCONNECTED"
		continue
	fi

	ROUTE_EXIST=`count_routes ${INTERFACE_IN} ${ROUTE_METRIC}`
	ANY_ROUTE_EXIST=`count_routes ${INTERFACE_IN}`

	if [ $ROUTE_EXIST -eq 0 ] && [ $ANY_ROUTE_EXIST -eq 0 ]; then
		turn_on_gateway $INTERFACE_IN $INTERFACE_OUT $BASE_FOREIGN_GATEWAY $ROUTE_METRIC
	elif [ $ANY_ROUTE_EXIST -gt 0 ] && [ $ROUTE_EXIST -eq 0 ]; then
		ip route del default dev $INTERFACE_IN
		echo "REMOVE OLD ROUTE"
		turn_on_gateway $INTERFACE_IN $INTERFACE_OUT $BASE_FOREIGN_GATEWAY $ROUTE_METRIC
	else
		echo "NOTHING TO DO"
	fi
done

exit 0
