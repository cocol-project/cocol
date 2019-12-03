#!/bin/bash

(( startPort=3001 ))
(( nodes=$(($1 - 1)) ))
(( miner=$2 ))

./cocol -p 3000 -m --max-connections 300 &> /dev/null &
sleep 1

for ((i=1;i<=nodes;i++));
do
    # ../cocol -p $(($startPort + $i)) -a $(($startApiPort + $i)) > /dev/null 2>&1 &
    ./cocol -p $((startPort + i)) --max-connections 5 1>> /tmp/cocol.log &
    echo $i
    sleep 0.2
done

for ((i=1;i<=miner;i++));
do
    # ../cocol -p $(($startPort + $i)) -a $(($startApiPort + $i)) > /dev/null 2>&1 &
    ./cocol -p $((4000 + i)) --max-connections 5 --miner 1>> /tmp/cocol.log &
    echo $i
    sleep 0.2
done

trap ctrl_c INT
function ctrl_c() {
    killall cocol
}

sleep 1d
