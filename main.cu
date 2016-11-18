#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <time.h>


const int N = 100;
const int M = 100;

__global__ void matrixAdd(int* A, int* B, int* C){
	//Posicion del thread
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int j = blockIdx.y * blockDim.y + threadIdx.y;

	int pos = i * N + j;

	if(i < N && j < M && (N*M) <= 1024){
		C[pos] = A[pos] + B[pos];
	}


}

/*
void sumarVectores(int* A, int* B, int* C, int num_elements){
	//Posicion del thread
	//int i = blockIdx.x * blockDim.x + threadIdx.x;


	for(int i=0; i<num_elements; i++){
		C[i] = A[i] + B[i];
	}
}*/

void fError(cudaError_t err){
	if(err != cudaSuccess){
		printf("Ha ocurrido un error con codigo: %s\n", cudaGetErrorString(err));
	}
}


int main(){


	//Reservar espacio en memoria HOST


	int h_A[N][M];
	int h_B[N][M];
	int h_C[N][M];


	//int * h_A = (int*)malloc(num_elements * sizeof(int));
	//int * h_B = (int*)malloc(num_elements * sizeof(int));
	//int * h_C = (int*)malloc(num_elements * sizeof(int));

	/*if(h_A == NULL || h_B == NULL || h_C == NULL){
		printf("Error al reservar memoria para los vectores HOST");
		exit(1);
	}*/





	//Inicializar elementos de los vectores
	for(int i=0; i<N; i++){
		for(int j=0; j<M; j++){
			h_A[i][j] = 1;
			h_B[i][j] = i;
		}
	}

	cudaError_t err;

	int size = N * M * sizeof(int);
	//int size_col = M * sizeof(int);

	int * d_A = NULL;


	err = cudaMalloc((void **)(&d_A), size);

	fError(err);

	//for(int i=0; i<M; i++){
		//cudaMalloc((void**)(&d_A[i]), size_col);
		cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	//}


	//err = cudaMalloc((void **)*&d_A, size)

	int * d_B = NULL;
	err = cudaMalloc((void **)(&d_B), size);
	fError(err);

	//for(int i=0; i<M; i++){
		//cudaMalloc((void**)(&d_B[i]), size_col);
		cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);
	//}

	int * d_C = NULL;
	err = cudaMalloc((void **)(&d_C), size);
	fError(err);

	//for(int i=0; i<M; i++){
		//cudaMalloc((void**)(&d_C[i]), size_col);
		cudaMemcpy(d_C, h_C, size, cudaMemcpyHostToDevice);
	//}

	//Copiamos a GPU DEVICE
	//err = cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	//err = cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);
	//err = cudaMemcpy(d_C, h_C, size, cudaMemcpyHostToDevice);

	//int HilosPorBloque = 512;

	int hilos = 256;
	int bloques = (N * M + hilos - 1) / hilos;
	dim3 HilosPorBloque(16,16,1);
	//int BloquesPorGrid = (N * M + HilosPorBloque -1) / HilosPorBloque;

	dim3 BloquesPorGrid(bloques, bloques);

	cudaError_t Err;

	//Lanzamos el kernel y medimos tiempos
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start, 0);


	matrixAdd<<<BloquesPorGrid, HilosPorBloque>>>(reinterpret_cast<int*>(&d_A), reinterpret_cast<int*>(&d_B), reinterpret_cast<int*>(&d_C));
	Err = cudaGetLastError();
	fError(Err);


	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);
	float tiempo_reserva_host;
	cudaEventElapsedTime(&tiempo_reserva_host, start, stop);


	printf("Tiempo de suma vectores DEVICE: %f\n", tiempo_reserva_host);

	cudaEventDestroy(start);
	cudaEventDestroy(stop);


	for(int i=0; i<N*M; i++){
		printf("%d\n", d_C[i]);
		printf("\n");
	}


	//Copiamos a CPU el vector C
	err = cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);



}







