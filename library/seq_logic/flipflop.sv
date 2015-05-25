/***

Implementation of a D flipflop

*/

module vs_d_flipflop(output logic q, 
    input logic d, clock);
    
    always_ff @(posedge clock)
        q <= d;
endmodule


/***
D flip-flop with asynchronous reset
*/
module vs_d_flipflop_async_r(output logic q, 
    input logic d, clock, reset_n);
    
    always_ff @(posedge clock, negedge reset_n)
        if (~reset_n)
            q <= '0;
        else
            q <= d;
endmodule

/***
D flip-flop with asynchronous set, reset
*/
module vs_d_flipflop_async_sr(output logic q, 
    input logic d, clock, reset_n, set_n);
    
    always_ff @(posedge clock, negedge reset_n, negedge set_n)
        if (~set_n)
            q <= '1;
        else if (~reset_n)
            q <= '0;
        else
            q <= d;
endmodule


/***
D flip-flop with synchronous reset
*/
module vs_d_flipflop_sync_r(output logic q, 
    input logic d, clock, reset_n);
    
    always_ff @(posedge clock)
        if (~reset_n)
            q <= '0;
        else
            q <= d;
endmodule


/***
D flip-flop with synchronous set, reset
*/
module vs_d_flipflop_sync_sr(output logic q, 
    input logic d, clock, reset_n, set_n);
    
    always_ff @(posedge clock)
        if (~set_n)
            q <= '1;
        else if (~reset_n)
            q <= '0;
        else
            q <= d;
endmodule

/***
D flip-flop with enable
*/
module vs_d_flipflop_sync_r(output logic q, 
    input logic d, clock, enable);
    
    always_ff @(posedge clock)
        if (enable)
            q <= d;
endmodule
