
/***

Implementation of an SR latch (Set Reset latch)

*/
module vs_sr_latch(output wire q, qbar, 
    input logic set, reset);
    always_latch  
        unique case ({reset, set})
            2'b00 : {q, qbar} <= 2'b11;
            // reset = 0, set = 1
            2'b01 : {q, qbar} <= 2'b10;
            // reset = 1, set = 0
            2'b10 : {q, qbar} <= 2'b01;
            // if both set and reset are 1, then the 
            // previous values are retained.
            default; 
        endcase

endmodule


/***

Implementation of a D latch

*/

module vs_d_latch(output logic q, 
    input logic d, enable);
    
    always_latch
        if (enable) q <= d;

endmodule


