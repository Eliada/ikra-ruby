    timeStartMeasure();
    /*{type}*/ * /*{name}*/;
    checkErrorReturn(program_result, cudaMalloc(&/*{name}*/, /*{bytes}*/));
    program_result->device_allocations->push_back(/*{name}*/);
    timeReportMeasure(program_result, allocate_memory);
