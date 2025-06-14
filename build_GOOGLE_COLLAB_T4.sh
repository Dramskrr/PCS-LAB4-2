#!/bin/bash

g++ main_serial.cpp -o main_serial
nvcc -gencode arch=compute_75,code=sm_75 main_parallel.cu -o main_parallel