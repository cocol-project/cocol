#!/bin/bash

let startPort=3001
let amount=$(($1 - 1))

brave file:///home/cris/Projects/crystal/cocol/explorer/index.html
./cocol -p 3000 -m --max-connections 1000 &
sleep 0.5

for ((i=0;i<=$amount;i++));
do
    # ../cocol -p $(($startPort + $i)) -a $(($startApiPort + $i)) > /dev/null 2>&1 &
    ./cocol -p $(($startPort + $i)) --max-connections $2 &
    echo $i
    sleep 0.2
done

trap ctrl_c INT
function ctrl_c() {
    killall cocol
}

sleep 1d
