#!/bin/bash

g++ main_serial.cpp -o main_serial
nvcc -gencode arch=compute_35,code=sm_35 main_parallel.cu -o main_parallel