#include <stdio.h>
#include <assert.h>
#include <chrono>

#include <helper_cuda.h>
#include <helper_cuda_gl.h>

using namespace std;


/* ----- BEGIN Shared Library Export ----- */
// taken from http://stackoverflow.com/questions/2164827/explicitly-exporting-shared-library-functions-in-linux

#if defined(_MSC_VER)
    //  Microsoft 
    #define EXPORT __declspec(dllexport)
    #define IMPORT __declspec(dllimport)
#elif defined(_GCC)
    //  GCC
    #define EXPORT __attribute__((visibility("default")))
    #define IMPORT
#else
    //  do nothing and hope for the best?
    #define EXPORT
    #define IMPORT
    #pragma warning Unknown dynamic link import/export semantics.
#endif
/* ----- END Shared Library Export ----- */

/* ----- BEGIN Class Type ----- */
typedef int obj_id_t;
typedef int class_id_t;
/* ----- END Class Type ----- */

/* ----- BEGIN Union Type ----- */
typedef union union_type_value {
    obj_id_t object_id;
    int int_;
    float float_;
    bool bool_;
} union_v_t;

typedef struct union_type_struct
{
    class_id_t class_id;
    union_v_t value;
} union_t;
/* ----- END Union Type ----- */


/* ----- BEGIN Environment (lexical variables) ----- */
// environment_struct must be defined later
typedef struct environment_struct environment_t;
/* ----- END Environment (lexical variables) ----- */

struct environment_struct
{
    int l2_size;
    int * l2_a;
    int * l2_b;
};
__device__ int _block_k_2_(environment_t *_env_, int index)
{
    
    int i;
    int result;
    int y;
    int x;
    int * lex_b = _env_->l2_b;
    int * lex_a = _env_->l2_a;
    int lex_size = _env_->l2_size;
    {
        x = ((index % lex_size));
        y = ((index / lex_size));
        result = 0;
        for (i = 0; i <= (lex_size - 1); i++)
        {
            result = ((result + ((lex_a[((((y * lex_size)) + i))] * lex_b[((((i * lex_size)) + x))]))));
        }
        i--;
        return result;
    }
}


__global__ void kernel_5(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, _tid_);
    }
}


typedef struct result_t {
    int *result;
    int last_error;

    uint64_t time_setup_cuda;
    uint64_t time_prepare_env;
    uint64_t time_kernel;
    uint64_t time_free_memory;
} result_t;

#define checkErrorReturn(result_var, expr) \
if (result_var->last_error = expr) \
{\
    cudaError_t error = cudaGetLastError();\
    printf("!!! Cuda Failure %s:%d (%i): '%s'\n", __FILE__, __LINE__, expr, cudaGetErrorString(error));\
    cudaDeviceReset();\
    return result_var;\
}

#define timeStartMeasure() start_time = chrono::high_resolution_clock::now();

#define timeReportMeasure(result_var, variable_name) \
end_time = chrono::high_resolution_clock::now(); \
result_var->time_##variable_name = chrono::duration_cast<chrono::microseconds>(end_time - start_time).count();

extern "C" EXPORT result_t *launch_kernel(environment_t *host_env)
{
    // Variables for measuring time
    chrono::high_resolution_clock::time_point start_time;
    chrono::high_resolution_clock::time_point end_time;

    // CUDA Initialization
    result_t *program_result = (result_t *) malloc(sizeof(result_t));

    timeStartMeasure();

    cudaError_t cudaStatus = cudaSetDevice(0);

    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed! Do you have a CUDA-capable GPU installed?\n");
        program_result->last_error = -1;
        return program_result;
    }

    checkErrorReturn(program_result, cudaFree(0));

    timeReportMeasure(program_result, setup_cuda);


    /* Prepare environment */
timeStartMeasure();

    void * temp_ptr_l2_a = host_env->l2_a;
    checkErrorReturn(program_result, cudaMalloc((void **) &host_env->l2_a, 22500));
    checkErrorReturn(program_result, cudaMemcpy(host_env->l2_a, temp_ptr_l2_a, 22500, cudaMemcpyHostToDevice));

    void * temp_ptr_l2_b = host_env->l2_b;
    checkErrorReturn(program_result, cudaMalloc((void **) &host_env->l2_b, 22500));
    checkErrorReturn(program_result, cudaMemcpy(host_env->l2_b, temp_ptr_l2_b, 22500, cudaMemcpyHostToDevice));
    /* Allocate device environment and copy over struct */
    environment_t *dev_env;
    checkErrorReturn(program_result, cudaMalloc(&dev_env, sizeof(environment_t)));
    checkErrorReturn(program_result, cudaMemcpy(dev_env, host_env, sizeof(environment_t), cudaMemcpyHostToDevice));

timeReportMeasure(program_result, prepare_env);

    /* Launch all kernels */
timeStartMeasure();
    int * _kernel_result_6;
    checkErrorReturn(program_result, cudaMalloc(&_kernel_result_6, (sizeof(int) * 5625)));
    int * _kernel_result_6_host = (int *) malloc((sizeof(int) * 5625));
    kernel_5<<<11, 512>>>(dev_env, 5625, _kernel_result_6);
    checkErrorReturn(program_result, cudaPeekAtLastError());
    checkErrorReturn(program_result, cudaThreadSynchronize());

    checkErrorReturn(program_result, cudaMemcpy(_kernel_result_6_host, _kernel_result_6, (sizeof(int) * 5625), cudaMemcpyDeviceToHost));

timeReportMeasure(program_result, kernel);

    /* Free device memory */
timeStartMeasure();
    checkErrorReturn(program_result, cudaFree(_kernel_result_6));

timeReportMeasure(program_result, free_memory);

    program_result->result = _kernel_result_6_host;
    return program_result;
}
