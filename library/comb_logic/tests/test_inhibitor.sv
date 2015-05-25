`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;

module test_inhibitor;

    logic out, in, enable_l;

    inhibitor dut(out, in, enable_l);

    initial begin
        in = 1;
        enable_l = 1;
        #10;
        `TEST_EQUAL("Inhibitor", out, 0);
        $display("in: %b, enable_l: %b, out: %b", in , enable_l, out);
        enable_l = 0;  
        #10;
        `TEST_EQUAL("Inhibitor", out, 1);
        $display("in: %b, enable_l: %b, out: %b", in , enable_l, out);
        in = 0;
        #10;
        `TEST_EQUAL("Inhibitor", out, 0);
        $display("in: %b, enable_l: %b, out: %b", in , enable_l, out);
    end

endmodule
