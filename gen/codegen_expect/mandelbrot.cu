#include <stdio.h>
#include <assert.h>

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
    int l1_hx_res;
    float l1_magnify;
    int l1_hy_res;
    int l1_iter_max;
    int l2_inverted;
};
__device__ int _block_k_1_(environment_t *_env_, int j)
{
    float xx;
    int iter;
    float y;
    float x;
    float cy;
    float cx;
    int hy;
    int hx;
    int lex_iter_max = _env_->l1_iter_max;
    int lex_hy_res = _env_->l1_hy_res;
    float lex_magnify = _env_->l1_magnify;
    int lex_hx_res = _env_->l1_hx_res;
    {
        hx = ((j % lex_hx_res));
        hy = ((j / lex_hx_res));
        cx = ((((((((((((float) hx) / ((float) lex_hx_res))) - 0.5)) / lex_magnify)) * 3.0)) - 0.7));
        cy = ((((((((((float) hy) / ((float) lex_hy_res))) - 0.5)) / lex_magnify)) * 3.0));
        x = 0.0;
        y = 0.0;
        for (iter = 0; iter <= lex_iter_max; iter++)
        {
            {
                xx = ((((((x * x)) - ((y * y)))) + cx));
                y = ((((((2.0 * x)) * y)) + cy));
                x = xx;
                if (((((((x * x)) + ((y * y)))) > 100)))
                {
                    break;
                }
            }
        }
        iter--;
        {
            return (iter % 256);
        }
    }
}


__device__ int _block_k_2_(environment_t *_env_, int color)
{
    int lex_inverted = _env_->l2_inverted;
    if (((lex_inverted == 1)))
    {
        {
            {
                return (255 - color);
            }
        }
    }
    else
    {
        {
            return color;
        }
    }
}


__global__ void kernel(environment_t *_env_, int *_result_)
{
    int t_id = threadIdx.x + blockIdx.x * blockDim.x;

    if (t_id < 40000)
    {
        _result_[t_id] = _block_k_2_(_env_, _block_k_1_(_env_, threadIdx.x + blockIdx.x * blockDim.x));
    }
}


typedef struct result_t {
    int *result;
    int last_error;
} result_t;

#define checkErrorReturn(result_var, expr) \
if (result_var->last_error = expr) \
{\
    cudaError_t error = cudaGetLastError();\
    printf("!!! Cuda Failure %s:%d (%i): '%s'\n", __FILE__, __LINE__, expr, cudaGetErrorString(error));\
    cudaDeviceReset();\
    return result_var;\
}

extern "C" EXPORT result_t *launch_kernel(environment_t *host_env)
{
    // CUDA Initialization
    result_t *kernel_result = (result_t *) malloc(sizeof(result_t));

    cudaError_t cudaStatus = cudaSetDevice(0);

    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed! Do you have a CUDA-capable GPU installed?\n");
        kernel_result->last_error = -1;
        return kernel_result;
    }

    checkErrorReturn(kernel_result, cudaFree(0));

    /* Modify host environment to contain device pointers addresses */
    

    /* Allocate device environment and copy over struct */
    environment_t *dev_env;
    checkErrorReturn(kernel_result, cudaMalloc(&dev_env, sizeof(environment_t)));
    checkErrorReturn(kernel_result, cudaMemcpy(dev_env, host_env, sizeof(environment_t), cudaMemcpyHostToDevice));

    int *host_result = (int *) malloc(sizeof(int) * 40000);
    int *device_result;
    checkErrorReturn(kernel_result, cudaMalloc(&device_result, sizeof(int) * 40000));
    
    dim3 dim_grid(157, 1, 1);
    dim3 dim_block(256, 1, 1);

    kernel<<<dim_grid, dim_block>>>(dev_env, device_result);

    checkErrorReturn(kernel_result, cudaPeekAtLastError());
    checkErrorReturn(kernel_result, cudaThreadSynchronize());

    checkErrorReturn(kernel_result, cudaMemcpy(host_result, device_result, sizeof(int) * 40000, cudaMemcpyDeviceToHost));
    checkErrorReturn(kernel_result, cudaFree(dev_env));

    kernel_result->result = host_result;
    return kernel_result;
}
