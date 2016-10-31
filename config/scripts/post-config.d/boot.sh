#!/bin/bash

/usr/sbin/olsrd -f /etc/olsrd/olsrd.conf -d 0 -nofork &


# tables:
#110 local routes
#111 RtTable
#112 RtTableDefault
#113 Special Table for /1
#114 blackhole table

sleep 5

#Copy local routes only from table main 254 to table 110
ip route show table 254 | grep -Ev ^default | grep -Ev ^blackhole | while read ROUTE ; do
MASK=`echo "${ROUTE}" | awk '{print $1}' | awk -F/ '{print $2}'`
if [ "$MASK" -ne 16 ] ; then
ip route add table 110 $ROUTE
fi
done

#First evaluate local routes
ip rule add from all lookup 110 pref 3

#Private routes to OLSR table
ip rule add to 10.0.0.0/8 table 111 pref 4
ip rule add to 172.16.0.0/12 table 111 pref 4
ip rule add to 192.168.0.0/16 table 111 pref 4

#Ninux IP Addresses to OLSR table
ip rule add to 176.62.53.0/24 table 111 pref 4

#Evaluate blackholes
ip rule add from all table 114 pref 5

#Send traffic of public address to BGP border routers
ip rule add from 176.62.53.0/24 table 113 pref 6

#Lookup default route first from user and then from OLSR
ip rule add from all lookup 254 pref 7
ip rule add from all lookup 112 pref 8

#Blackhole private aggregates
ip route add blackhole 10.0.0.0/8 table 114
ip route add blackhole 172.16.0.0/12 table 114
ip route add blackhole 192.168.0.0/16 table 114

#Blackhole Ninux aggregate
ip route add blackhole 176.62.53.0/24 table 114

# http://stackoverflow.com/questions/696839/how-do-i-write-a-bash-script-to-restart-a-process-if-it-dies
until olsrd; do
    echo "olsrd crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
# old script
#while true; do
#    /config/olsrd/olsrd.mips64r2 -f /config/olsrd/olsrd.conf -d 0 -nofork
#    sleep 60
#done

