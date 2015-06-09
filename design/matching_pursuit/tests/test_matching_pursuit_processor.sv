

module test_matching_pursuit_processor;

    logic clock = 1;
    bit reset_n = 0;
    int clock_count = 0;

    matching_pursuit_chip PE(clock, reset_n);
    matching_pursuit_io IO(clock, reset_n);

    initial begin
        // generate reset
        PE.start = 0;
    end

    // clock implementation
    always
        #10 clock = ~clock;


    always_ff @(negedge clock) begin
        // count clock
        clock_count <= clock_count + 1;
        //$display("clock: %0d, time: %0t", clock_count, $time);
        // // force stop the simulation
        // if (clock_count == 200) $stop;
        // // check if processor is done.
        // if (PE.done == 1) $stop;
    end

endmodule
