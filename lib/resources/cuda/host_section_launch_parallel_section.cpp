({
    // /*{debug_information}*/

    /*{array_command_type}*/ cmd = /*{array_command}*/;

    if (cmd->result == 0) {
        /*{kernel_invocation}*/
        cmd->result = /*{kernel_result}*/;

        /*{free_memory}*/
    }

    variable_size_array_t((void *) cmd->result, /*{result_size}*/);
})