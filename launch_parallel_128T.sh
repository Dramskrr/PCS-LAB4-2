#!/bin/bash

sed -i "15,+0 s|.*|export THREADS_CONFIG=128|g" launch.sh

./launch.sh