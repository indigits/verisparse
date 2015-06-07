`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;

module test_multiplexer;


    logic select_1bit;
    logic [1:0] select_2bit;

    logic [3:0] in_data[4];
    logic [3:0] out_data[2];

    vs_mux_2x1 #(4) dut_mux2x1(select_1bit, 
        in_data[0], in_data[1], out_data[0]);

    vs_mux_4x1 #(4) dut_mux4x1(select_2bit, 
        in_data[0], in_data[1], 
        in_data[2], in_data[3], 
        out_data[1]);

    initial begin
        `TEST_SET_START
        for (int i=0;i < 4; ++i) begin
            in_data[i] = (i+1)*2;
        end
        #10;
        
        select_1bit = 0;
        #10;
        $display("out0 : %d", out_data[0]);
        `TEST_SET_EQUAL(out_data[0], 2);
        
        select_1bit = 1;
        #10;
        $display("out0 : %d", out_data[0]);
        `TEST_SET_EQUAL(out_data[0], 4);


        for (int i=0; i < 4; ++i) begin
            select_2bit = i;
            #10;
            $display("out1 : %d", out_data[1]);
            `TEST_SET_EQUAL(out_data[1], (i+1)*2);
        end

        `TEST_SET_SUMMARIZE("Multiplexer")
    end

endmodule
