
`include "verisparse.svh"
module matching_pursuit_io(input clock,
        input resetN);

    initial begin
        reset_chip();
        load_sensing_matrix_and_signal();
        print_y_ram();
        print_x_ram();
        print_dict_ram(10, 10);
        load_dictionary_in_processor_direct();
        print_phi_in_matrix_processor(10, 10);
        show_time();
        start_chip();
        wait_for_y_to_r_transfer();
        while (!PE.done) begin
            wait_for_loop_iteration();
        end
        wait_for_chip();
    end

    function automatic void load_sensing_matrix_and_signal();

        integer x_file_id;
        integer y_file_id;
        integer dict_file_id;

        integer x_byte_count;
        integer y_byte_count;
        integer dict_byte_count;

        uint8_t x_buffer[0:(1<<REPRESENTATION_ADDR_WIDTH) - 1];
        uint8_t y_buffer[0:(1<<SIGNAL_ADDR_WIDTH) - 1];
        uint8_t dict_buffer[0:(1<<DICTIONARY_ADDR_WIDTH) - 1];
        fp_32_t dword;

        x_file_id = $fopen("data/pursuit/problem_0/x.bin", "rb");
        x_byte_count = $fread(x_buffer, x_file_id);
        $fclose(x_file_id);

        // load signal into RAM
        y_file_id = $fopen("data/pursuit/problem_0/y.bin", "rb");
        y_byte_count = $fread(y_buffer, y_file_id);
        $fclose(y_file_id);

        // Load dictionary into RAM
        dict_file_id = $fopen("data/pursuit/problem_0/dict.bin", "rb");
        dict_byte_count = $fread(dict_buffer, dict_file_id);
        $fclose(dict_file_id);


        // Load data into RAMs.
        for (int i=0;i < y_byte_count; i = i + 4) begin
            dword =  y_buffer[i];
            dword = (dword << 8)  | y_buffer[i+1]; 
            dword = (dword << 8)  | y_buffer[i+2]; 
            dword = (dword << 8)  | y_buffer[i+3]; 
            PE.y_ram.ram[i>>2] = dword;
        end
        for (int i=0;i < dict_byte_count; i = i + 4) begin
            dword =  dict_buffer[i];
            dword = (dword << 8)  | dict_buffer[i+1]; 
            dword = (dword << 8)  | dict_buffer[i+2]; 
            dword = (dword << 8)  | dict_buffer[i+3]; 
            PE.dict_ram.ram[i >> 2] = dword;
        end
        for (int i=0;i < (1<<REPRESENTATION_ADDR_WIDTH) ; ++i) begin
            PE.x_ram.ram[i] = 0;
        end
    endfunction

    function automatic void print_y_ram();
        $display("Printing Y RAM contents:");
        for (int i = 0; i < SIGNAL_SIZE_DEFAULT; ++i) begin
            if ((i & 'hf) == 0) begin
                $write("\n");
            end
            $write("%f ", vs_fixed_to_real(int'(PE.y_ram.ram[i]) ));
        end
        $write("\n");
    endfunction

    function automatic void print_x_ram();
        $display("Printing X RAM contents:");
        for (int i = 0; i < DICTIONARY_SIZE_DEFAULT; ++i) begin
            if ((i & 'hf) == 0) begin
                $write("\n");
            end
            $write("%f ", vs_fixed_to_real(int'(PE.x_ram.ram[i]) ));
        end
        $write("\n");
    endfunction

    function automatic void print_r_ram();
        for (int i = 0; i < SIGNAL_SIZE_DEFAULT; ++i) begin
            if ((i & 'hf) == 0) begin
                $write("\n");
            end
            $write("%f ", vs_fixed_to_real(int'(PE.residuals.ram[i]) ));
        end
        $write("\n");
    endfunction

    function automatic void print_inner_product_ram();
        for (int i = 0; i < DICTIONARY_SIZE_DEFAULT; ++i) begin
            if ((i & 'hf) == 0) begin
                $write("\n");
            end
            $write("%f ", vs_fixed_to_real(int'(PE.products.ram[i]) ));
        end
        $write("\n");
    endfunction

    function  automatic void print_max_ident_result();
        $display("Max value: %f", vs_fixed_to_real(int'(PE.max_ident_bus.value)));
        $display("Max location: %d", PE.max_ident_bus.location);
    endfunction :  print_max_ident_result

    function automatic void print_dict_ram(int rows, int cols);
        $display("Printing dictionary contents: %d x %d", rows, cols);
        for (int r=0; r < rows; ++r) begin
            for (int c=0; c < cols ; ++c) begin
                int index = c * SIGNAL_SIZE_DEFAULT + r;
                int dword = int'(PE.dict_ram.ram[index]);
                $write("%3.6f   ", vs_fixed_to_real(dword));
            end
            $write("\n");
        end
        $write("\n");
    endfunction

    function automatic void load_dictionary_in_processor_direct();
        $display("Loading dictionary into processor directly");
        for (int r=0; r < SIGNAL_SIZE_DEFAULT; ++r) begin
            for (int c=0; c < DICTIONARY_SIZE_DEFAULT ; ++c) begin
                int index = c * SIGNAL_SIZE_DEFAULT + r;
                PE.dict_processor.phi[r][c] = PE.dict_ram.ram[index];
            end
        end
        $display("Dictionary load completed");
    endfunction

    task automatic load_dictionary_in_processor_via_bus();
        $display("Loading matrix into processor via bus");
        // load the sensing matrix
        PE.dict_proc_bus.command = LOAD_SENSING_MATRIX;
        // we need to provide data from the sensing matrix
        PE.proc_read_select = 1;
        PE.dict_bus.read_addr = 0;
        @(posedge clock);
        // initiate transfer of sensing matrix
        PE.dict_proc_bus.start = 1;
        // wait for next clock edge
        @(posedge clock);
        $display("Start signal sent for loading matrix");
        PE.dict_proc_bus.start = 0;
        while (!PE.dict_proc_bus.done) begin
            PE.dict_bus.read_addr = PE.dict_bus.read_addr + 1;
            $write(".");
            if ((PE.dict_bus.read_addr & 'h3f) == 0) $write("\n");
            // $display("read addr: %d, data: %d, %d", 
            //     phi_read_addr, phi_out_data, 
            //     proc_read_data);
            @(posedge clock);
        end
        // the computation must have started
        // wait for the computation to complete
        // wait(PE.dict_proc_done);
        // now verify everything.
        $display("Matrix load completed");
    endtask

    function automatic void print_phi_in_matrix_processor(int rows, int cols);
        $display("Printing dictionary contents in processor: %d x %d", rows, cols);
        for (int r=0; r < rows; ++r) begin
            for (int c=0; c < cols ; ++c) begin
                int dword = int'(PE.dict_processor.phi[r][c]);
                $write("%3.6f   ", vs_fixed_to_real(dword));
            end
            $write("\n");
        end
        $write("\n");
    endfunction


    task automatic reset_chip();
        $display("Resetting the chip");
        show_time();
        @(posedge clock);
        show_time();
        test_matching_pursuit_processor.reset_n = 0;
        @(posedge clock);
        test_matching_pursuit_processor.reset_n = 1;
        $display("Reset completed");
        show_time();
    endtask

    task automatic start_chip();
        $display("Starting the chip");
        // Now signal start
        PE.start = 1;
        // Now lower start bit
        @(posedge clock);
        PE.start = 0;   
        $display("Start completed");
        show_time();
    endtask

    task automatic wait_for_y_to_r_transfer();
        $display("Waiting for Y to R transfer");
        wait(PE.alg_fsm.y_to_r_transferred);
        $display("Y to R transfer completed.");
        show_time();
        $write("Displaying residual ram:");
        print_r_ram();
    endtask 

    task automatic wait_for_chip();
        $display("Waiting for chip to finish the job");
        wait (PE.done);
        $display("Chip work completed.");
        show_time();
    endtask

    task automatic wait_for_loop_iteration();
        wait(PE.main_loop_bus.done);
        $display("Iteration completed.");
        show_time();
        $display("Printing inner products.");
        print_inner_product_ram();
        print_max_ident_result();
        // wait for the loop done pin to go low.
        wait(~PE.main_loop_bus.done);
    endtask 

    function  void show_time();
        $display("Time: %d,  clock %d", $time, 
            test_matching_pursuit_processor.clock_count);     
     endfunction :  show_time 

    function void display_processor_state();
        $display("  k=%0d state: %s, loop state: %s", 
            PE.alg_fsm.k_counter, 
            PE.alg_fsm.state.name, 
            PE.main_loop.state.name);
    endfunction

endmodule
