
/**
Various implementations for computing the max
*/

`include "verisparse.svp"


module max_fp32(
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


module abs_max_fp32(
    input clock,
    input resetN,
    input fp_32_t value,
    output fp_32_t max_value);

    fp_32_t abs_value;
    assign abs_value = value < 0 ? -value : value;

    always_ff @(posedge clock) begin
        if (! resetN) begin
            max_value <= 0;
        end
        else begin
            max_value <= max_value > abs_value ?  max_value : abs_value;
        end
    end
endmodule

