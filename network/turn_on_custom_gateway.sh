#!/bin/bash

add_iptables () {
	if [ ! `iptables -S POSTROUTUNG -t nat | grep eth1` ]; then
		iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
	fi
	if [ ! `iptables -S FORWARD | grep -E '\-A[ ]FORWARD[ ]\-m[ ]conntrack[ ]\-\-ctstate[ ]RELATED\,ESTABLISHED[ ]\-j[ ]ACCEPT'` ]; then
		iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	fi
	if [ ! `iptables -S FORWARD | grep eth1` ]; then
		iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
	fi
}

turn_on_gateway () {
	ip route add default via 172.20.10.1 dev eth1 metric 50
	echo "NEW ROUTE ADDED"

	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo "ALLOW TO PORT FORWARDING"

	add_iptables
	echo "ADD NAT TO IPTABLES"

}

while true; do
	sleep 2

	if [ -f /sys/class/net/eth1/carrier ] && [ -f /sys/class/net/eth1/operstate ] && [ `grep "1" /sys/class/net/eth1/carrier` ] && [ `grep -E '(up)|(unknown)' /sys/class/net/eth1/operstate` ]; then
		echo "CONNECTED"
	else
		echo "DISCONNECTED"
		continue
	fi

	ROUTE_EXIST=`ip route show default dev eth1 metric 50 | wc -l`
	ANY_ROUTE_EXIST=`ip route show default dev eth1 | wc -l`

	if [ $ROUTE_EXIST -eq 0 ] && [ $ANY_ROUTE_EXIST -eq 0 ]; then
		turn_on_gateway
	elif [ $ANY_ROUTE_EXIST -gt 0 ] && [ $ROUTE_EXIST -eq 0 ]; then
		ip route del default dev eth1
		echo "REMOVE OLD ROUTE"
		turn_on_gateway
	else
		echo "NOTHING TO DO"
	fi

	sleep 2

done

exit 0
