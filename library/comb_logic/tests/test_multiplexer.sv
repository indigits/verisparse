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


module test_demultiplexer;
   logic select_1bit;
    logic [1:0] select_2bit;

    logic [3:0] in_data;
    logic [3:0] out_data[6];

    vs_demux_1x2 #(4) dut_demux_1x2(select_1bit, 
        in_data, out_data[0], out_data[1]);

    vs_demux_1x4 #(4) dut_demux_1x4(select_2bit, 
        in_data, out_data[2], 
        out_data[3], out_data[4], 
        out_data[5]);

    initial begin
        `TEST_SET_START
        in_data = 3;
        for (int i=0; i< 2; ++i) begin
            select_1bit = i;
            #1;
            for (int j=0; j < 2; ++j) begin
                if (i == j) begin
                    `TEST_SET_EQUAL(out_data[j], in_data);
                end
                else begin
                    `TEST_SET_EQUAL(out_data[j], 0);
                end
            end
        end
        for (int i=0; i< 4; ++i) begin
            select_2bit = i;
            #1;
            for (int j=0; j < 4; ++j) begin
                if (i == j) begin
                    `TEST_SET_EQUAL(out_data[j+2], in_data);
                end
                else begin
                    `TEST_SET_EQUAL(out_data[j+2], 0);
                end
            end
        end

        `TEST_SET_SUMMARIZE("Demultiplexer")
    end
endmodule   
