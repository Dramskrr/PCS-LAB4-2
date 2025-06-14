#!/bin/bash

export ARRAY_SIZE_CONFIG=500000000
export RUNS_CONFIG=1
export THREADS_CONFIG=1
export BLOCKS_CONFIG=1

sed -i "3,+0 s|.*|export ARRAY_SIZE=$ARRAY_SIZE_CONFIG|g" serial.sh
sed -i "4,+0 s|.*|export RUNS=$RUNS_CONFIG|g" serial.sh

sed -i "3,+0 s|.*|export ARRAY_SIZE=$ARRAY_SIZE_CONFIG|g" parallel.sh
sed -i "4,+0 s|.*|export RUNS=$RUNS_CONFIG|g" parallel.sh
sed -i "5,+0 s|.*|export THREADS=$THREADS_CONFIG|g" parallel.sh
sed -i "6,+0 s|.*|export BLOCKS=$BLOCKS_CONFIG|g" parallel.sh

if [ $THREADS_CONFIG -lt 2 ]; then
    ./serial.sh
else
    ./parallel.sh
fi