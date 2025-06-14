// #include <limits.h>
// #include <stdint.h>
// #include <asm-generic/errno.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <stdio.h>
#include <stdlib.h>
// #include <string.h>
#include <time.h>
// #include <stdbool.h>

// АЛГОРИТМ ПРИНИМАЕТ ТОЛЬКО РАЗМЕР МАССИВА, ЯВЛЯЮЩИЙСЯ СТЕПЕНЬЮ 2!
const long int DEFAULT_ARRAY_SIZE = 65536;
const int DEFAULT_RUNS = 10;

float *CreateArray(const long int SIZE) {
  float *float_array = (float *)malloc(sizeof(float) * SIZE);
  for (long int i = 0; i < SIZE; i++) {
    float_array[i] = rand() % 100;
  }
  return float_array;
}

void PrintArray(const float *array, const int SIZE) {
  for (int i = 0; i < SIZE; i++) {
    printf("%f ", array[i]);
  }
  printf("\n");
}

long int GetEnvArraySize() {
  char *array_size_char = getenv("ARRAY_SIZE");
  long int array_size_int = DEFAULT_ARRAY_SIZE;
  if (array_size_char != NULL) {
    array_size_int = atoi(array_size_char);
  } else {
    printf("Переменная среды ARRAY_SIZE не получена, "
           "используем значение по умолчанию: %ld \n",
           DEFAULT_ARRAY_SIZE);
  }
  return array_size_int;
}

int GetEnvRuns() {
  char *runs_char = getenv("RUNS");
  int runs_int = DEFAULT_RUNS;
  if (runs_char != NULL) {
    runs_int = atoi(runs_char);
  } else {
    printf("Переменная среды RUNS не получена, "
           "используем значение по умолчанию: %d \n",
           DEFAULT_RUNS);
  }
  return runs_int;
}

void compare(float* a, float* b)
{
    float A = *a;
    float B = *b;
    if (A > B)
    {
        *a = B;
        *b = A;
    }
}

void bitonic(float *mem, int N) {
  int K = log2(N);
  int d = 1 << K;
  for (int n = 0; n < d >> 1; n++) {
    compare(&mem[n], &mem[d - n - 1]);
  }
  K--;
  if (K <= 0) {
    return;
  }
  for (int k = K; k > 0; k--) {
    d = 1 << k;
    for (int m = 0; m < N; m += d) {
      for (int n = 0; n < d >> 1; n++) {
        compare(&mem[m + n], &mem[m + (d >> 1) + n]);
      }
    }
  }
}

void BitonicSort(float *mem, int N) {
  float *map = new float[N];
  for (int n = 0; n < N; n++) {
    map[n] = mem[n];
  }
  int K = log2(N);
  for (int k = 1; k <= K; k++) {
    int d = 1 << k;
    for (int n = 0; n < N; n += d) {
      float *map_ptr = &map[n];
      bitonic(map_ptr, d);
    }
  }
  for (int n = 0; n < N; n++) {
    mem[n] = map[n];
  }
  delete[] map;
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

int main(int argc, char **argv) {
  printf("Последовательная программа\n");
  srand(time(0));
  // srand(1);
  const long int ARRAY_SIZE = GetEnvArraySize();
  const int RUNS = GetEnvRuns();

  if ((ARRAY_SIZE & (ARRAY_SIZE - 1)) != 0){
    printf("Размер массива не является степенью 2!\n");
    exit(EXIT_FAILURE);
  }

  printf("Размер массива: %ld\n", ARRAY_SIZE);
  printf("Выполнений: %d\n", RUNS);

  // Таймер
  struct timespec begin, end;
  double exec_time = 0.0;

  // Цикл выполнения задачи и подсчёта времени её выполнения
  for (int i = 0; i < RUNS; i++) {

    float *float_array = NULL;
    float_array = CreateArray(ARRAY_SIZE);

    clock_gettime(CLOCK_REALTIME, &begin); // Начало таймера

    // Код позаимствован из
    // https://github.com/nickjillings/bitonic-sort/blob/master/BitonicSort.cpp
    BitonicSort(float_array, ARRAY_SIZE);

    clock_gettime(CLOCK_REALTIME, &end); // Конец таймера
    exec_time += (double)(end.tv_sec - begin.tv_sec) +
                 (double)(end.tv_nsec - begin.tv_nsec) / 1e9;

    CheckSort(float_array, ARRAY_SIZE);

    free(float_array);
  }

  double mean_exec_time = exec_time / RUNS;
  printf("Общее время выполнения: %f сек. \n", exec_time);
  printf("Среднее время выполнения: %f сек.", mean_exec_time);

  return 0;
}
