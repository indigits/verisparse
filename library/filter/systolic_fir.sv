
`include "verisparse.svh"

/**

The design doesn't look predictable. We need more control.

There should be a pass through mode where y_out is zero and x_out = x_in.
There should be a load mode where weight = x_in.
There should be a x_reset where x_out = 0 for all processing elements.
There should be normal mode where y = x_in * weight + y_in.

Why do we need to hold y in register? 

*/

module systolic_fir_pe #(parameter FIR_FILTER_LENGTH = 4) (
    input clock,
    input resetN,
    input fp_32_t x_in,
    input fp_32_t y_in,
    output fp_32_t x_out,
    output fp_32_t y_out
    );

    // states of the machine
    typedef enum {IDLE, WEIGHT_INPUT, MAIN, DELAY} state_t;

    state_t state = IDLE;

    fp_32_t weight;
    fp_32_t y;

    byte clock_count;


    always_ff @(posedge clock) begin
        if (! resetN) begin
            state <= WEIGHT_INPUT;
            x_out <= 0;
            y_out <= 0;
            clock_count <= 0;
        end
        else begin
            case (state) 
                IDLE : begin
                    state <= IDLE;
                    x_out <= 0;
                    y_out <= 0;
                end
                WEIGHT_INPUT  : begin
                    if (clock_count < FIR_FILTER_LENGTH) begin
                        state <= WEIGHT_INPUT;
                        clock_count <= clock_count + 1;
                        x_out <= x_in;
                        y_out <= 0;
                    end
                    else begin
                        state <= MAIN;
                        weight <= x_in;
                        x_out <= x_in;
                        y_out <= 0;
                    end
                end
                MAIN : begin
                    state <= DELAY;
                    x_out <= x_in;
                    // compute the output value
                    y <= y_in + weight * x_in;
                end
                DELAY : begin
                    state <= MAIN;
                    x_out <= x_in;
                    y_out <= y;
                end
                default : begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule


module systolic_fir_filter_4tap(
    input clock,
    input resetN,
    input fp_32_t x_in, 
    output fp_32_t y_out
    );
    
    // chain of processing element instances
    fp_32_t x_out0, x_out1, x_out2, x_out;
    fp_32_t y_out0, y_out1, y_out2;
    systolic_fir_pe pe0 (clock, resetN, x_in, 0, x_out0, y_out0);
    systolic_fir_pe pe1 (clock, resetN, x_out0, y_out0, x_out1, y_out1);
    systolic_fir_pe pe2 (clock, resetN, x_out1, y_out1, x_out2, y_out2);
    systolic_fir_pe pe3 (clock, resetN, x_out2, y_out2, x_out, y_out);
endmodule
