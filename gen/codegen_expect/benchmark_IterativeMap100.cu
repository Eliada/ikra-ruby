#include <stdio.h>
#include <assert.h>
#include <chrono>
#include <vector>
#include <algorithm>

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

/* ----- BEGIN Environment (lexical variables) ----- */
// environment_struct must be defined later
typedef struct environment_struct environment_t;
/* ----- END Environment (lexical variables) ----- */


/* ----- BEGIN Forward declarations ----- */
typedef struct result_t result_t;
/* ----- END Forward declarations ----- */

// Define program result variable. Also contains benchmark numbers.
result_t *program_result;

// Variables for measuring time
chrono::high_resolution_clock::time_point start_time;
chrono::high_resolution_clock::time_point end_time;

/* ----- BEGIN Macros ----- */
#define timeStartMeasure() start_time = chrono::high_resolution_clock::now();

#define timeReportMeasure(result_var, variable_name) \
end_time = chrono::high_resolution_clock::now(); \
result_var->time_##variable_name = result_var->time_##variable_name + chrono::duration_cast<chrono::microseconds>(end_time - start_time).count();
/* ----- END Macros ----- */
struct indexed_struct_4_lt_int_int_int_int_gt_t
{
    int field_0;
int field_1;
int field_2;
int field_3;
};

/* ----- BEGIN Structs ----- */
struct variable_size_array_t {
    void *content;
    int size;

    variable_size_array_t(void *content_ = NULL, int size_ = 0) : content(content_), size(size_) { }; 

    static const variable_size_array_t error_return_value;
};

// error_return_value is used in case a host section terminates abnormally
const variable_size_array_t variable_size_array_t::error_return_value = 
    variable_size_array_t(NULL, 0);

/* ----- BEGIN Union Type ----- */
typedef union union_type_value {
    obj_id_t object_id;
    int int_;
    float float_;
    bool bool_;
    void *pointer;
    variable_size_array_t variable_size_array;

    __host__ __device__ union_type_value(int value) : int_(value) { };
    __host__ __device__ union_type_value(float value) : float_(value) { };
    __host__ __device__ union_type_value(bool value) : bool_(value) { };
    __host__ __device__ union_type_value(void *value) : pointer(value) { };
    __host__ __device__ union_type_value(variable_size_array_t value) : variable_size_array(value) { };

    __host__ __device__ static union_type_value from_object_id(obj_id_t value)
    {
        return union_type_value(value);
    }

    __host__ __device__ static union_type_value from_int(int value)
    {
        return union_type_value(value);
    }

    __host__ __device__ static union_type_value from_float(float value)
    {
        return union_type_value(value);
    }

    __host__ __device__ static union_type_value from_bool(bool value)
    {
        return union_type_value(value);
    }

    __host__ __device__ static union_type_value from_pointer(void *value)
    {
        return union_type_value(value);
    }

    __host__ __device__ static union_type_value from_variable_size_array_t(variable_size_array_t value)
    {
        return union_type_value(value);
    }
} union_v_t;

typedef struct union_type_struct
{
    class_id_t class_id;
    union_v_t value;

    __host__ __device__ union_type_struct(
        class_id_t class_id_ = 0, union_v_t value_ = union_v_t(0))
        : class_id(class_id_), value(value_) { };

    static const union_type_struct error_return_value;
} union_t;

// error_return_value is used in case a host section terminates abnormally
const union_type_struct union_t::error_return_value = union_type_struct(0, union_v_t(0));
/* ----- END Union Type ----- */

typedef struct result_t {
    variable_size_array_t result;
    int last_error;

    uint64_t time_setup_cuda;
    uint64_t time_prepare_env;
    uint64_t time_kernel;
    uint64_t time_free_memory;
    uint64_t time_transfer_memory;
    uint64_t time_allocate_memory;

    // Memory management
    vector<void*> *device_allocations;
} result_t;
/* ----- END Structs ----- */

struct array_command_1 {
    // Ikra::Symbolic::ArrayIndexCommand
    indexed_struct_4_lt_int_int_int_int_gt_t *result;
    __host__ __device__ array_command_1(indexed_struct_4_lt_int_int_int_int_gt_t *result = NULL) : result(result) { }
};
struct array_command_2 {
    // Ikra::Symbolic::ArrayCombineCommand
    int *result;
    array_command_1 *input_0;
    __host__ __device__ array_command_2(int *result = NULL, array_command_1 *input_0 = NULL) : result(result), input_0(input_0) { }
};
struct array_command_4 {
    // Ikra::Symbolic::ArrayIndexCommand
    indexed_struct_4_lt_int_int_int_int_gt_t *result;
    __host__ __device__ array_command_4(indexed_struct_4_lt_int_int_int_int_gt_t *result = NULL) : result(result) { }
};
struct array_command_3 {
    // Ikra::Symbolic::ArrayCombineCommand
    int *result;
    array_command_2 *input_0;
    array_command_4 *input_1;
    __host__ __device__ array_command_3(int *result = NULL, array_command_2 *input_0 = NULL, array_command_4 *input_1 = NULL) : result(result), input_0(input_0), input_1(input_1) { }
};
struct array_command_7 {
    // Ikra::Symbolic::FixedSizeArrayInHostSectionCommand
    int *result;
    variable_size_array_t input_0;
    __host__ __device__ array_command_7(int *result = NULL, variable_size_array_t input_0 = variable_size_array_t::error_return_value) : result(result), input_0(input_0) { }
    int size() { return input_0.size; }
};
struct array_command_8 {
    // Ikra::Symbolic::ArrayCombineCommand
    int *result;
    array_command_7 *input_0;
    array_command_4 *input_1;
    __host__ __device__ array_command_8(int *result = NULL, array_command_7 *input_0 = NULL, array_command_4 *input_1 = NULL) : result(result), input_0(input_0), input_1(input_1) { }
};
struct environment_struct
{
};

// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_3 = ((indices.field_1 % 4));
        (_temp_var_3 == 0 ? indices.field_0 : (_temp_var_3 == 1 ? indices.field_1 : (_temp_var_3 == 2 ? indices.field_2 : (_temp_var_3 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif


__global__ void kernel_1(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}





// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_4 = ((indices.field_1 % 4));
        (_temp_var_4 == 0 ? indices.field_0 : (_temp_var_4 == 1 ? indices.field_1 : (_temp_var_4 == 2 ? indices.field_2 : (_temp_var_4 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif



// TODO: There should be a better to check if _block_k_3_ is already defined
#ifndef _block_k_3__func
#define _block_k_3__func
__device__ int _block_k_3_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_5 = ((({ int _temp_var_6 = ((({ int _temp_var_7 = ((i % 4));
        (_temp_var_7 == 0 ? indices.field_0 : (_temp_var_7 == 1 ? indices.field_1 : (_temp_var_7 == 2 ? indices.field_2 : (_temp_var_7 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_6 == 0 ? indices.field_0 : (_temp_var_6 == 1 ? indices.field_1 : (_temp_var_6 == 2 ? indices.field_2 : (_temp_var_6 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_5 == 0 ? indices.field_0 : (_temp_var_5 == 1 ? indices.field_1 : (_temp_var_5 == 2 ? indices.field_2 : (_temp_var_5 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_3(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_3_(_env_, _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2})), ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_8_ is already defined
#ifndef _block_k_8__func
#define _block_k_8__func
__device__ int _block_k_8_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_8 = ((({ int _temp_var_9 = ((({ int _temp_var_10 = ((i % 4));
        (_temp_var_10 == 0 ? indices.field_0 : (_temp_var_10 == 1 ? indices.field_1 : (_temp_var_10 == 2 ? indices.field_2 : (_temp_var_10 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_9 == 0 ? indices.field_0 : (_temp_var_9 == 1 ? indices.field_1 : (_temp_var_9 == 2 ? indices.field_2 : (_temp_var_9 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_8 == 0 ? indices.field_0 : (_temp_var_8 == 1 ? indices.field_1 : (_temp_var_8 == 2 ? indices.field_2 : (_temp_var_8 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_5(environment_t *_env_, int _num_threads_, int *_result_, int *_array_7_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_8_(_env_, _array_7_[_tid_], ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_13 = ((indices.field_1 % 4));
        (_temp_var_13 == 0 ? indices.field_0 : (_temp_var_13 == 1 ? indices.field_1 : (_temp_var_13 == 2 ? indices.field_2 : (_temp_var_13 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif


__global__ void kernel_8(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}





// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_14 = ((indices.field_1 % 4));
        (_temp_var_14 == 0 ? indices.field_0 : (_temp_var_14 == 1 ? indices.field_1 : (_temp_var_14 == 2 ? indices.field_2 : (_temp_var_14 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif



// TODO: There should be a better to check if _block_k_3_ is already defined
#ifndef _block_k_3__func
#define _block_k_3__func
__device__ int _block_k_3_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_15 = ((({ int _temp_var_16 = ((({ int _temp_var_17 = ((i % 4));
        (_temp_var_17 == 0 ? indices.field_0 : (_temp_var_17 == 1 ? indices.field_1 : (_temp_var_17 == 2 ? indices.field_2 : (_temp_var_17 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_16 == 0 ? indices.field_0 : (_temp_var_16 == 1 ? indices.field_1 : (_temp_var_16 == 2 ? indices.field_2 : (_temp_var_16 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_15 == 0 ? indices.field_0 : (_temp_var_15 == 1 ? indices.field_1 : (_temp_var_15 == 2 ? indices.field_2 : (_temp_var_15 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_10(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_3_(_env_, _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2})), ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_8_ is already defined
#ifndef _block_k_8__func
#define _block_k_8__func
__device__ int _block_k_8_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_18 = ((({ int _temp_var_19 = ((({ int _temp_var_20 = ((i % 4));
        (_temp_var_20 == 0 ? indices.field_0 : (_temp_var_20 == 1 ? indices.field_1 : (_temp_var_20 == 2 ? indices.field_2 : (_temp_var_20 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_19 == 0 ? indices.field_0 : (_temp_var_19 == 1 ? indices.field_1 : (_temp_var_19 == 2 ? indices.field_2 : (_temp_var_19 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_18 == 0 ? indices.field_0 : (_temp_var_18 == 1 ? indices.field_1 : (_temp_var_18 == 2 ? indices.field_2 : (_temp_var_18 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_12(environment_t *_env_, int _num_threads_, int *_result_, int *_array_14_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_8_(_env_, _array_14_[_tid_], ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_23 = ((indices.field_1 % 4));
        (_temp_var_23 == 0 ? indices.field_0 : (_temp_var_23 == 1 ? indices.field_1 : (_temp_var_23 == 2 ? indices.field_2 : (_temp_var_23 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif


__global__ void kernel_15(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}





// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_24 = ((indices.field_1 % 4));
        (_temp_var_24 == 0 ? indices.field_0 : (_temp_var_24 == 1 ? indices.field_1 : (_temp_var_24 == 2 ? indices.field_2 : (_temp_var_24 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif



// TODO: There should be a better to check if _block_k_3_ is already defined
#ifndef _block_k_3__func
#define _block_k_3__func
__device__ int _block_k_3_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_25 = ((({ int _temp_var_26 = ((({ int _temp_var_27 = ((i % 4));
        (_temp_var_27 == 0 ? indices.field_0 : (_temp_var_27 == 1 ? indices.field_1 : (_temp_var_27 == 2 ? indices.field_2 : (_temp_var_27 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_26 == 0 ? indices.field_0 : (_temp_var_26 == 1 ? indices.field_1 : (_temp_var_26 == 2 ? indices.field_2 : (_temp_var_26 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_25 == 0 ? indices.field_0 : (_temp_var_25 == 1 ? indices.field_1 : (_temp_var_25 == 2 ? indices.field_2 : (_temp_var_25 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_17(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_3_(_env_, _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2})), ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_8_ is already defined
#ifndef _block_k_8__func
#define _block_k_8__func
__device__ int _block_k_8_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_28 = ((({ int _temp_var_29 = ((({ int _temp_var_30 = ((i % 4));
        (_temp_var_30 == 0 ? indices.field_0 : (_temp_var_30 == 1 ? indices.field_1 : (_temp_var_30 == 2 ? indices.field_2 : (_temp_var_30 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_29 == 0 ? indices.field_0 : (_temp_var_29 == 1 ? indices.field_1 : (_temp_var_29 == 2 ? indices.field_2 : (_temp_var_29 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_28 == 0 ? indices.field_0 : (_temp_var_28 == 1 ? indices.field_1 : (_temp_var_28 == 2 ? indices.field_2 : (_temp_var_28 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_19(environment_t *_env_, int _num_threads_, int *_result_, int *_array_21_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_8_(_env_, _array_21_[_tid_], ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_33 = ((indices.field_1 % 4));
        (_temp_var_33 == 0 ? indices.field_0 : (_temp_var_33 == 1 ? indices.field_1 : (_temp_var_33 == 2 ? indices.field_2 : (_temp_var_33 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif


__global__ void kernel_22(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}





// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_34 = ((indices.field_1 % 4));
        (_temp_var_34 == 0 ? indices.field_0 : (_temp_var_34 == 1 ? indices.field_1 : (_temp_var_34 == 2 ? indices.field_2 : (_temp_var_34 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif



// TODO: There should be a better to check if _block_k_3_ is already defined
#ifndef _block_k_3__func
#define _block_k_3__func
__device__ int _block_k_3_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_35 = ((({ int _temp_var_36 = ((({ int _temp_var_37 = ((i % 4));
        (_temp_var_37 == 0 ? indices.field_0 : (_temp_var_37 == 1 ? indices.field_1 : (_temp_var_37 == 2 ? indices.field_2 : (_temp_var_37 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_36 == 0 ? indices.field_0 : (_temp_var_36 == 1 ? indices.field_1 : (_temp_var_36 == 2 ? indices.field_2 : (_temp_var_36 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_35 == 0 ? indices.field_0 : (_temp_var_35 == 1 ? indices.field_1 : (_temp_var_35 == 2 ? indices.field_2 : (_temp_var_35 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_24(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_3_(_env_, _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2})), ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_8_ is already defined
#ifndef _block_k_8__func
#define _block_k_8__func
__device__ int _block_k_8_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_38 = ((({ int _temp_var_39 = ((({ int _temp_var_40 = ((i % 4));
        (_temp_var_40 == 0 ? indices.field_0 : (_temp_var_40 == 1 ? indices.field_1 : (_temp_var_40 == 2 ? indices.field_2 : (_temp_var_40 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_39 == 0 ? indices.field_0 : (_temp_var_39 == 1 ? indices.field_1 : (_temp_var_39 == 2 ? indices.field_2 : (_temp_var_39 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_38 == 0 ? indices.field_0 : (_temp_var_38 == 1 ? indices.field_1 : (_temp_var_38 == 2 ? indices.field_2 : (_temp_var_38 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_26(environment_t *_env_, int _num_threads_, int *_result_, int *_array_28_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_8_(_env_, _array_28_[_tid_], ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_45 = ((indices.field_1 % 4));
        (_temp_var_45 == 0 ? indices.field_0 : (_temp_var_45 == 1 ? indices.field_1 : (_temp_var_45 == 2 ? indices.field_2 : (_temp_var_45 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif


__global__ void kernel_29(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}





// TODO: There should be a better to check if _block_k_2_ is already defined
#ifndef _block_k_2__func
#define _block_k_2__func
__device__ int _block_k_2_(environment_t *_env_, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    {
        return (((indices.field_0 + indices.field_1)) % ((((indices.field_3 + ({ int _temp_var_46 = ((indices.field_1 % 4));
        (_temp_var_46 == 0 ? indices.field_0 : (_temp_var_46 == 1 ? indices.field_1 : (_temp_var_46 == 2 ? indices.field_2 : (_temp_var_46 == 3 ? indices.field_3 : NULL)))); }))) + 7)));
    }
}

#endif



// TODO: There should be a better to check if _block_k_3_ is already defined
#ifndef _block_k_3__func
#define _block_k_3__func
__device__ int _block_k_3_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_47 = ((({ int _temp_var_48 = ((({ int _temp_var_49 = ((i % 4));
        (_temp_var_49 == 0 ? indices.field_0 : (_temp_var_49 == 1 ? indices.field_1 : (_temp_var_49 == 2 ? indices.field_2 : (_temp_var_49 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_48 == 0 ? indices.field_0 : (_temp_var_48 == 1 ? indices.field_1 : (_temp_var_48 == 2 ? indices.field_2 : (_temp_var_48 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_47 == 0 ? indices.field_0 : (_temp_var_47 == 1 ? indices.field_1 : (_temp_var_47 == 2 ? indices.field_2 : (_temp_var_47 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_31(environment_t *_env_, int _num_threads_, int *_result_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_3_(_env_, _block_k_2_(_env_, ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2})), ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}



// TODO: There should be a better to check if _block_k_8_ is already defined
#ifndef _block_k_8__func
#define _block_k_8__func
__device__ int _block_k_8_(environment_t *_env_, int i, indexed_struct_4_lt_int_int_int_int_gt_t indices)
{
    
    
    
    {
        return (((((((i % 938)) + ((i / 97)))) % 97717)) + ((((({ int _temp_var_50 = ((({ int _temp_var_51 = ((({ int _temp_var_52 = ((i % 4));
        (_temp_var_52 == 0 ? indices.field_0 : (_temp_var_52 == 1 ? indices.field_1 : (_temp_var_52 == 2 ? indices.field_2 : (_temp_var_52 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_51 == 0 ? indices.field_0 : (_temp_var_51 == 1 ? indices.field_1 : (_temp_var_51 == 2 ? indices.field_2 : (_temp_var_51 == 3 ? indices.field_3 : NULL)))); }) % 4));
        (_temp_var_50 == 0 ? indices.field_0 : (_temp_var_50 == 1 ? indices.field_1 : (_temp_var_50 == 2 ? indices.field_2 : (_temp_var_50 == 3 ? indices.field_3 : NULL)))); }) * ((i % 7)))) % 99)));
    }
}

#endif


__global__ void kernel_33(environment_t *_env_, int _num_threads_, int *_result_, int *_array_35_)
{
    int _tid_ = threadIdx.x + blockIdx.x * blockDim.x;

    if (_tid_ < _num_threads_)
    {

        
        _result_[_tid_] = _block_k_8_(_env_, _array_35_[_tid_], ((indexed_struct_4_lt_int_int_int_int_gt_t) {_tid_ / 500000, (_tid_ / 1000) % 500, (_tid_ / 2) % 500, (_tid_ / 1) % 2}));
    }
}


#undef checkErrorReturn
#define checkErrorReturn(result_var, expr) \
if (result_var->last_error = expr) \
{\
    cudaError_t error = cudaGetLastError();\
    printf("!!! Cuda Failure %s:%d (%i): '%s'\n", __FILE__, __LINE__, expr, cudaGetErrorString(error));\
    cudaDeviceReset();\
    return variable_size_array_t::error_return_value;\
}

variable_size_array_t _host_section__(environment_t *host_env, environment_t *dev_env, result_t *program_result)
{
    array_command_2 * x = new array_command_2();
    int i;
    union_t _ssa_var_old_data_2;
    union_t _ssa_var_y_4;
    union_t _ssa_var_old_data_3;
    union_t _ssa_var_y_1;
    {
        _ssa_var_y_1 = union_t(10, union_v_t::from_pointer((void *) x));
        _ssa_var_old_data_2 = union_t(10, union_v_t::from_pointer((void *) x));
        for (i = 0; i <= (500 - 1); i++)
        {
            _ssa_var_old_data_3 = _ssa_var_y_1;
            _ssa_var_y_4 = union_t(12, union_v_t::from_pointer((void *) new array_command_8(NULL, new array_command_7(NULL, ({
                variable_size_array_t _polytemp_result_1;
                {
                    union_t _polytemp_expr_2 = _ssa_var_y_1;
                    switch (_polytemp_expr_2.class_id)
                    {
                        case 10: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_1 = ({
                            // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]
                        
                            array_command_2 * cmd = (array_command_2 *) _polytemp_expr_2.value.pointer;
                        
                            if (cmd->result == 0) {
                                    timeStartMeasure();
                            int * _kernel_result_2;
                            checkErrorReturn(program_result, cudaMalloc(&_kernel_result_2, (sizeof(int) * 10000000)));
                            program_result->device_allocations->push_back(_kernel_result_2);
                            timeReportMeasure(program_result, allocate_memory);
                            timeStartMeasure();
                            kernel_1<<<39063, 256>>>(dev_env, 10000000, _kernel_result_2);
                            checkErrorReturn(program_result, cudaPeekAtLastError());
                            checkErrorReturn(program_result, cudaThreadSynchronize());
                            timeReportMeasure(program_result, kernel);
                                cmd->result = _kernel_result_2;
                        
                                
                            }
                        
                            variable_size_array_t((void *) cmd->result, 10000000);
                        }); break;
                        case 11: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_1 = ({
                            // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]: [SendNode: [SendNode: [SendNode: [LVarReadNode: _ssa_var_y_1].__call__()].to_command()].pmap([HashNode: {<:with_index> => [BeginNode: {<true>}]}])]
                        
                            array_command_3 * cmd = (array_command_3 *) _polytemp_expr_2.value.pointer;
                        
                            if (cmd->result == 0) {
                                    timeStartMeasure();
                            int * _kernel_result_4;
                            checkErrorReturn(program_result, cudaMalloc(&_kernel_result_4, (sizeof(int) * 10000000)));
                            program_result->device_allocations->push_back(_kernel_result_4);
                            timeReportMeasure(program_result, allocate_memory);
                            timeStartMeasure();
                            kernel_3<<<39063, 256>>>(dev_env, 10000000, _kernel_result_4);
                            checkErrorReturn(program_result, cudaPeekAtLastError());
                            checkErrorReturn(program_result, cudaThreadSynchronize());
                            timeReportMeasure(program_result, kernel);
                                cmd->result = _kernel_result_4;
                        
                                
                            }
                        
                            variable_size_array_t((void *) cmd->result, 10000000);
                        }); break;
                        case 12: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_1 = ({
                            // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]: [SendNode: [SendNode: [SendNode: [LVarReadNode: _ssa_var_y_1].__call__()].to_command()].pmap([HashNode: {<:with_index> => [BeginNode: {<true>}]}])]
                        
                            array_command_8 * cmd = (array_command_8 *) _polytemp_expr_2.value.pointer;
                        
                            if (cmd->result == 0) {
                                    timeStartMeasure();
                            int * _kernel_result_6;
                            checkErrorReturn(program_result, cudaMalloc(&_kernel_result_6, (sizeof(int) * 10000000)));
                            program_result->device_allocations->push_back(_kernel_result_6);
                            timeReportMeasure(program_result, allocate_memory);
                            timeStartMeasure();
                            kernel_5<<<39063, 256>>>(dev_env, 10000000, _kernel_result_6, ((int *) ((int *) cmd->input_0->input_0.content)));
                            checkErrorReturn(program_result, cudaPeekAtLastError());
                            checkErrorReturn(program_result, cudaThreadSynchronize());
                            timeReportMeasure(program_result, kernel);
                                cmd->result = _kernel_result_6;
                        
                                
                            }
                        
                            variable_size_array_t((void *) cmd->result, 10000000);
                        }); break;
                    }
                }
                _polytemp_result_1;
            })))));
            ({
                bool _polytemp_result_41;
                {
                    union_t _polytemp_expr_42 = _ssa_var_old_data_3;
                    switch (_polytemp_expr_42.class_id)
                    {
                        case 10: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_41 = ({
                            array_command_2 * cmd_to_free = (array_command_2 *) _polytemp_expr_42.value.pointer;
                        
                            timeStartMeasure();
                            bool freed_memory = false;
                        
                            if (cmd_to_free->result != 0) {
                                checkErrorReturn(program_result, cudaFree(cmd_to_free->result));
                        
                                // Remove from list of allocations
                                program_result->device_allocations->erase(
                                    std::remove(
                                        program_result->device_allocations->begin(),
                                        program_result->device_allocations->end(),
                                        cmd_to_free->result),
                                    program_result->device_allocations->end());
                        
                                freed_memory = true;
                            }
                        
                            timeReportMeasure(program_result, free_memory);
                            
                            freed_memory;
                        }); break;
                        case 11: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_41 = ({
                            array_command_3 * cmd_to_free = (array_command_3 *) _polytemp_expr_42.value.pointer;
                        
                            timeStartMeasure();
                            bool freed_memory = false;
                        
                            if (cmd_to_free->result != 0) {
                                checkErrorReturn(program_result, cudaFree(cmd_to_free->result));
                        
                                // Remove from list of allocations
                                program_result->device_allocations->erase(
                                    std::remove(
                                        program_result->device_allocations->begin(),
                                        program_result->device_allocations->end(),
                                        cmd_to_free->result),
                                    program_result->device_allocations->end());
                        
                                freed_memory = true;
                            }
                        
                            timeReportMeasure(program_result, free_memory);
                            
                            freed_memory;
                        }); break;
                        case 12: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_41 = ({
                            array_command_8 * cmd_to_free = (array_command_8 *) _polytemp_expr_42.value.pointer;
                        
                            timeStartMeasure();
                            bool freed_memory = false;
                        
                            if (cmd_to_free->result != 0) {
                                checkErrorReturn(program_result, cudaFree(cmd_to_free->result));
                        
                                // Remove from list of allocations
                                program_result->device_allocations->erase(
                                    std::remove(
                                        program_result->device_allocations->begin(),
                                        program_result->device_allocations->end(),
                                        cmd_to_free->result),
                                    program_result->device_allocations->end());
                        
                                freed_memory = true;
                            }
                        
                            timeReportMeasure(program_result, free_memory);
                            
                            freed_memory;
                        }); break;
                    }
                }
                _polytemp_result_41;
            });
            _ssa_var_y_1 = _ssa_var_y_4;
            _ssa_var_old_data_2 = _ssa_var_old_data_3;
        }
        i--;
        return ({
            variable_size_array_t _polytemp_result_43;
            {
                union_t _polytemp_expr_44 = _ssa_var_y_1;
                switch (_polytemp_expr_44.class_id)
                {
                    case 10: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_43 = ({
                        // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]
                    
                        array_command_2 * cmd = (array_command_2 *) _polytemp_expr_44.value.pointer;
                    
                        if (cmd->result == 0) {
                                timeStartMeasure();
                        int * _kernel_result_30;
                        checkErrorReturn(program_result, cudaMalloc(&_kernel_result_30, (sizeof(int) * 10000000)));
                        program_result->device_allocations->push_back(_kernel_result_30);
                        timeReportMeasure(program_result, allocate_memory);
                        timeStartMeasure();
                        kernel_29<<<39063, 256>>>(dev_env, 10000000, _kernel_result_30);
                        checkErrorReturn(program_result, cudaPeekAtLastError());
                        checkErrorReturn(program_result, cudaThreadSynchronize());
                        timeReportMeasure(program_result, kernel);
                            cmd->result = _kernel_result_30;
                    
                            
                        }
                    
                        variable_size_array_t((void *) cmd->result, 10000000);
                    }); break;
                    case 11: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_43 = ({
                        // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]: [SendNode: [SendNode: [SendNode: [LVarReadNode: _ssa_var_y_1].__call__()].to_command()].pmap([HashNode: {<:with_index> => [BeginNode: {<true>}]}])]
                    
                        array_command_3 * cmd = (array_command_3 *) _polytemp_expr_44.value.pointer;
                    
                        if (cmd->result == 0) {
                                timeStartMeasure();
                        int * _kernel_result_32;
                        checkErrorReturn(program_result, cudaMalloc(&_kernel_result_32, (sizeof(int) * 10000000)));
                        program_result->device_allocations->push_back(_kernel_result_32);
                        timeReportMeasure(program_result, allocate_memory);
                        timeStartMeasure();
                        kernel_31<<<39063, 256>>>(dev_env, 10000000, _kernel_result_32);
                        checkErrorReturn(program_result, cudaPeekAtLastError());
                        checkErrorReturn(program_result, cudaThreadSynchronize());
                        timeReportMeasure(program_result, kernel);
                            cmd->result = _kernel_result_32;
                    
                            
                        }
                    
                        variable_size_array_t((void *) cmd->result, 10000000);
                    }); break;
                    case 12: /* [Ikra::Symbolic::ArrayCombineCommand, size = 10000000] (Ikra::Symbolic::ArrayCommand) */ _polytemp_result_43 = ({
                        // [Ikra::Symbolic::ArrayCombineCommand, size = 10000000]: [SendNode: [SendNode: [SendNode: [LVarReadNode: _ssa_var_y_1].__call__()].to_command()].pmap([HashNode: {<:with_index> => [BeginNode: {<true>}]}])]
                    
                        array_command_8 * cmd = (array_command_8 *) _polytemp_expr_44.value.pointer;
                    
                        if (cmd->result == 0) {
                                timeStartMeasure();
                        int * _kernel_result_34;
                        checkErrorReturn(program_result, cudaMalloc(&_kernel_result_34, (sizeof(int) * 10000000)));
                        program_result->device_allocations->push_back(_kernel_result_34);
                        timeReportMeasure(program_result, allocate_memory);
                        timeStartMeasure();
                        kernel_33<<<39063, 256>>>(dev_env, 10000000, _kernel_result_34, ((int *) ((int *) cmd->input_0->input_0.content)));
                        checkErrorReturn(program_result, cudaPeekAtLastError());
                        checkErrorReturn(program_result, cudaThreadSynchronize());
                        timeReportMeasure(program_result, kernel);
                            cmd->result = _kernel_result_34;
                    
                            
                        }
                    
                        variable_size_array_t((void *) cmd->result, 10000000);
                    }); break;
                }
            }
            _polytemp_result_43;
        });
    }
}

#undef checkErrorReturn
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
    program_result = new result_t();
    program_result->device_allocations = new vector<void*>();

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
        /* Allocate device environment and copy over struct */
    environment_t *dev_env;

    timeStartMeasure();
    checkErrorReturn(program_result, cudaMalloc(&dev_env, sizeof(environment_t)));
    timeReportMeasure(program_result, allocate_memory);

    timeStartMeasure();
    checkErrorReturn(program_result, cudaMemcpy(dev_env, host_env, sizeof(environment_t), cudaMemcpyHostToDevice));
    timeReportMeasure(program_result, transfer_memory);
    


    /* Copy back memory and set pointer of result */
    program_result->result = ({
    variable_size_array_t device_array = _host_section__(host_env, dev_env, program_result);
    int * tmp_result = (int *) malloc(sizeof(int) * device_array.size);

    timeStartMeasure();
    checkErrorReturn(program_result, cudaMemcpy(tmp_result, device_array.content, sizeof(int) * device_array.size, cudaMemcpyDeviceToHost));
    timeReportMeasure(program_result, transfer_memory);

    variable_size_array_t((void *) tmp_result, device_array.size);
});

    /* Free device memory */
    timeStartMeasure();

    for (
        auto device_ptr = program_result->device_allocations->begin(); 
        device_ptr < program_result->device_allocations->end(); 
        device_ptr++)
    {
        checkErrorReturn(program_result, cudaFree(*device_ptr));
    }

    delete program_result->device_allocations;

    timeReportMeasure(program_result, free_memory);

    return program_result;
}
