#!/bin/bash

CAPFILE=$1

for port in 55000 55001 55002 55003; do
  START_TIME=$(tcpdump -r $CAPFILE -tt -n src port 8888 and dst port $port 2> /dev/null | head -1 | awk '{print $1}')
  END_TIME=$(tcpdump -r $CAPFILE  -tt -n src port 8888 and dst port $port 2> /dev/null | tail -1 | awk '{print $1}')
  NUM_PACKETS=$(tcpdump -r $CAPFILE  -tt -n src port 8888 and dst port $port 2> /dev/null | wc -l | awk '{print $1}')
  if [[ $NUM_PACKETS == 0 ]]; then
    echo "No packets on port $port"
  else
    SECS=$(echo "print $END_TIME - $START_TIME" | python)
    PPS=$(echo "print $NUM_PACKETS/($END_TIME - $START_TIME)" | python)
    echo "Port $port: $NUM_PACKETS packets in $SECS seconds = $PPS"
  fi
done
