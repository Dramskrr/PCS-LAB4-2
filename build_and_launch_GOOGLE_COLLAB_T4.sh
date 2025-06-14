#!/bin/bash

./build_GOOGLE_COLLAB_T4.sh
./launch_serial.sh
./launch_parallel_128T.sh
./launch_parallel_512T.sh
./launch_parallel_1024T.sh