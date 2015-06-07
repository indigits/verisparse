
/**
Various implementations for computing the max
*/

`include "verisparse.svh"


module vs_max_fp32(
    input clock,
    input resetN,
    input fp_32_t value,
    output fp_32_t max_value);

    const fp_32_t INT_MIN = -32'h7FFFFFFF;

    always_ff @(posedge clock) begin
        if (! resetN) begin
            max_value <= INT_MIN;
        end
        else begin
            max_value <= max_value > value ?  max_value : value;
        end
    end
endmodule


/**
Computes the absolute maximum of a series of values
**/
module vs_abs_max_fp32(
    input clock,
    input resetN,
    input fp_32_t value,
    output fp_32_t max_value,
    output bit cur_value_is_max);

    // stores the absolute value of current value
    fp_32_t abs_value;
    always_comb begin
        // computation of absolute value
        abs_value = (value < 0) ? -value : value;
    end

    always_ff @(posedge clock) begin
        if (! resetN) begin
            max_value <= 0;
        end
        else begin
            //$display("cur: %d, max: %d", abs_value, max_value);
            if (max_value > abs_value) begin
                cur_value_is_max <= 0;
            end
            else begin
                max_value <= abs_value;
                cur_value_is_max <= 1;
            end
        end
    end
endmodule

