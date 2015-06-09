`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;




module test_counter;
    timeunit 10ps;
    timeprecision 1ps;
    parameter N = 16;

    logic clock = 1;
    logic reset_n = 0;
    logic [(N-1):0] out;

    vs_up_counter#(N) counter_up  (clock, reset_n, out);

    initial begin
        // reset the chip
        reset_n  = 0;
        @(posedge clock);
        // remove reset
        reset_n  = 1;
    end

    initial begin
        // a fixed number of clock cycles
        repeat (20000) #5 clock = ~clock;
    end

    always @(posedge clock) begin
        $display("time: %d, value: %d", $time, out);
    end

endmodule
