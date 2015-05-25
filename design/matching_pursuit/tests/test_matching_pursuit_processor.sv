

module test_matching_pursuit_processor;

    logic clock = 0;
    bit resetN = 0;
    int clock_count = 0;

    matching_pursuit_chip PE(clock, resetN);
    matching_pursuit_io IO(clock, resetN);

    initial begin
        // generate reset
        PE.start = 0;
        resetN = 0;
        clock = 1;
        // deactivate reset
        #100 resetN = 1; 
        // Now signal start
        PE.start = 1;
        // Now lower start bit
        #100 PE.start = 0;    
    end
    // clock implementation
    always #50 clock = ~clock;

    always_ff @(posedge clock) begin
        // count clock
        clock_count <= clock_count + 1;
        // force stop the simulation
        if (clock_count == 200) $stop;
        // check if processor is done.
        if (PE.done == 1) $stop;
    end

    always @(negedge clock) begin
        $display("clock: %0d, time: %0t", clock_count, $time);
        $display("  k=%0d state: %s, loop state: %s", PE.processor.k_counter, 
            PE.processor.state.name, 
            PE.processor.main_loop.state.name);
    end
endmodule
