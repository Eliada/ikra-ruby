extern "C" EXPORT result_t *launch_kernel(environment_t */*{host_env_var_name}*/)
{
    // Variables for measuring time
    chrono::high_resolution_clock::time_point start_time;
    chrono::high_resolution_clock::time_point end_time;

    // CUDA Initialization
    result_t *program_result = (result_t *) malloc(sizeof(result_t));
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
timeStartMeasure();
/*{prepare_environment}*/
timeReportMeasure(program_result, prepare_env);


    /* Launch all kernels */
timeStartMeasure();
/*{launch_all_kernels}*/
timeReportMeasure(program_result, kernel);


    /* Copy back memory and set pointer of result */
/*{copy_back_to_host}*/

    /* Free device memory */
    timeStartMeasure();

    for (
        auto device_ptr = program_result->device_allocations->begin(); 
        device_ptr < program_result->device_allocations->end(); 
        device_ptr++)
    {
        cudaFree(*device_ptr);
    }

    delete program_result->device_allocations;

    timeReportMeasure(program_result, free_memory);

    return program_result;
}
