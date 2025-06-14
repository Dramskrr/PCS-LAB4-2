//#include <limits.h>
//#include <stdint.h>
//#include <asm-generic/errno.h>
#include <cstdlib>
#include <stdio.h>
#include <stdlib.h>
//#include <string.h>
#include <time.h>
#include <cuda_runtime.h>
//#include <stdbool.h>

const long int DEFAULT_ARRAY_SIZE = 134217728;
const int DEFAULT_RUNS = 2;
const int DEFAULT_THREADS = 256;
const int DEFAULT_BLOCKS = 8;

__global__ void BitonicSortStep(float *dev_values, int j, int k)
{
  unsigned int i, ixj; /* Sorting partners: i and ixj */
  i = threadIdx.x + blockDim.x * blockIdx.x;
  ixj = i^j;

  /* The threads with the lowest ids sort the array. */
  if ((ixj)>i) {
    if ((i&k)==0) {
      /* Sort ascending */
      if (dev_values[i]>dev_values[ixj]) {
        /* exchange(i,ixj); */
        float temp = dev_values[i];
        dev_values[i] = dev_values[ixj];
        dev_values[ixj] = temp;
      }
    }
    if ((i&k)!=0) {
      /* Sort descending */
      if (dev_values[i]<dev_values[ixj]) {
        /* exchange(i,ixj); */
        float temp = dev_values[i];
        dev_values[i] = dev_values[ixj];
        dev_values[ixj] = temp;
      }
    }
  }
}

float* CreateArray( const int SIZE) {
    float* float_array = (float*) malloc(sizeof(float) * SIZE);
    for (int i = 0; i < SIZE; i++) {
        float_array[i] = rand()%100;
    }
    return float_array;
}

void PrintArray(const int* array, const int SIZE) {
    for (int i = 0; i < SIZE; i++) {
        printf("%d ",array[i]);
    }
    printf("\n");
}

long int GetEnvArraySize() {
    char* array_size_char = getenv("ARRAY_SIZE");
    long int array_size_int = DEFAULT_ARRAY_SIZE;
    if (array_size_char != NULL) {
        array_size_int = atoi(array_size_char);
    } else {
        printf(
            "Переменная среды ARRAY_SIZE не получена, "
            "используем значение по умолчанию: %ld \n", DEFAULT_ARRAY_SIZE
        );
    }
    return array_size_int;
}

int GetEnvThreads() {
    char* thread_char = getenv("THREADS");
    int thread_int = DEFAULT_THREADS;
    if (thread_char != NULL) {
        thread_int = atoi(thread_char);
    } else {
        printf(
            "Переменная среды THREADS не получена, "
            "используем значение по умолчанию: %d \n", DEFAULT_THREADS
        );
    }
    return thread_int;
}

// int GetEnvBlocks() {
//     char* block_char = getenv("BLOCKS");
//     int block_int = DEFAULT_BLOCKS;
//     if (block_char != NULL) {
//         block_int = atoi(block_char);
//     } else {
//         printf(
//             "Переменная среды BLOCKS не получена, "
//             "используем значение по умолчанию: %d \n", DEFAULT_BLOCKS
//         );
//     }
//     return block_int;
// }

int GetEnvRuns() {
    char* runs_char = getenv("RUNS");
    int runs_int = DEFAULT_RUNS;
    if (runs_char != NULL) {
        runs_int = atoi(runs_char);
    } else {
        printf(
            "Переменная среды RUNS не получена, "
            "используем значение по умолчанию: %d \n", DEFAULT_RUNS
        );
    }
    return runs_int;
}

void CheckCudaError(cudaError_t err){
    if (err != cudaSuccess) {
        fprintf(stderr, "Fail (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void PrintArray(const float* array, const int SIZE) {
    for (int i = 0; i < SIZE; i++) {
        printf("%f ",array[i]);
    }
    printf("\n");
}

void CheckSort(float *array, const int SIZE){
    for (int i = 1; i < SIZE-1; i++){
        if (array[i] > array[i+1]){
            printf("Сортировка неверная!");
            return;
        }
    }
    printf("Сортировка верная!\n");
}

int main(int argc, char** argv) {
    // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;

    srand(time(0));
    //srand(1);
    const long int ARRAY_SIZE = GetEnvArraySize();
    const int RUNS = GetEnvRuns();
    const int THREADS = GetEnvThreads();
    //const int BLOCKS = GetEnvBlocks();

    if ((ARRAY_SIZE & (ARRAY_SIZE - 1)) != 0){
        printf("Размер массива не является степенью 2!\n");
        exit(EXIT_FAILURE);
    }
    const int BLOCKS = (ARRAY_SIZE / THREADS);

    printf("\n\nПараллельная программа\n");
    printf("Размер массива: %ld\n", ARRAY_SIZE);
    printf("Выполнений: %d\n", RUNS);
    printf("Потоков в блоке: %d\n", THREADS);
    printf("Блоков (ДЛЯ ДАННОГО ЗАДАНИЯ НАСТРОЙКА КОЛ-ВА БЛОКОВ ИГНОРИРУЕТСЯ,\n\
            ПРОГРАММА САМА ВЫСЧИТАЛА НУЖНОЕ КОЛИЧЕСТВО БЛОКОВ НА ОСНОВЕ КОЛ-ВА ПОТОКОВ): %d\n", BLOCKS);
    
    // Таймер
    struct timespec begin, end;
    double exec_time = 0.0;
    double data_allocation_time = 0.0;

    // Цикл выполнения задачи и подсчёта времени её выполнения
    for (int i = 0; i < RUNS; i++) {

        // Массив хоста с данными
        float* host_float_array = NULL;
        host_float_array = CreateArray(ARRAY_SIZE);

        clock_gettime(CLOCK_REALTIME, &begin); // Начало таймера

        // Выделение глобальной памяти под массив, который будет передан GPU
        float* device_float_array = NULL;
        err = cudaMalloc(&device_float_array, ARRAY_SIZE * sizeof(float));
        CheckCudaError(err);
        //printf("Глоб массив выделен\n");
        
        //Копирование массива в GPU
        err = cudaMemcpy(device_float_array,
                         host_float_array,
                         ARRAY_SIZE * sizeof(float),
                         cudaMemcpyHostToDevice
                        );
        CheckCudaError(err);
        //printf("Глоб массив скопирован\n");

        clock_gettime(CLOCK_REALTIME, &end); // Конец таймера
        data_allocation_time += (double)(end.tv_sec - begin.tv_sec) + (double)(end.tv_nsec - begin.tv_nsec)/1e9;
        clock_gettime(CLOCK_REALTIME, &begin); // Начало таймера
        
        // Выполнение задачи
        // CUDA код позаимствован из
        // https://gist.github.com/mre/1392067
        int j = 0;
        int k = 0;
        /* Major step */
        for (k = 2; k <= ARRAY_SIZE; k <<= 1) {
            /* Minor step */
            for (j=k>>1; j>0; j=j>>1) {
                BitonicSortStep<<<BLOCKS, THREADS>>>(device_float_array, j, k);
            }
        }
        cudaDeviceSynchronize();
        err = cudaGetLastError();
        CheckCudaError(err);
        //printf("Задача выполнена\n");

        clock_gettime(CLOCK_REALTIME, &end); // Конец таймера
        exec_time += (double)(end.tv_sec - begin.tv_sec) + (double)(end.tv_nsec - begin.tv_nsec)/1e9;
        clock_gettime(CLOCK_REALTIME, &begin); // Начало таймера

        // Берём результат от GPU
        err = cudaMemcpy(host_float_array,
                         device_float_array,
                         ARRAY_SIZE * sizeof(float),
                         cudaMemcpyDeviceToHost
                        );
        CheckCudaError(err);
        //printf("Результат получен\n");
        
        // Освобождаем глобальную память GPU
        err = cudaFree(device_float_array);
        CheckCudaError(err);
        //printf("Память очищена\n");

        clock_gettime(CLOCK_REALTIME, &end); // Конец таймера
        data_allocation_time += (double)(end.tv_sec - begin.tv_sec) + (double)(end.tv_nsec - begin.tv_nsec)/1e9;
        
        CheckSort(host_float_array, ARRAY_SIZE);

        free(host_float_array);
    }

    double mean_data_alloc_time = data_allocation_time / RUNS;
    double mean_exec_time = exec_time / RUNS;
    printf("Общее время выделения памяти, передачи данных и финального счёта: %f сек. \n", data_allocation_time);
    printf("Среднее время выделения памяти передачи данных и финального счёта: %f сек. \n\n", mean_data_alloc_time);
    printf("Общее время выполнения кода на GPU: %f сек. \n", exec_time);
    printf("Среднее время выполнения кода на GPU: %f сек. \n\n", mean_exec_time );
    printf("Общее время выполнения: %f сек. \n", exec_time + data_allocation_time);
    printf("Среднее время выполнения: %f сек.", mean_exec_time + mean_data_alloc_time);

    return 0;
}
