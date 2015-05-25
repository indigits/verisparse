
/**
This design assumes that fixed point number is
represented using 2's complement notation
where Q denotes the number of fractional bits
and N denotes the total number of bits.

http://en.wikipedia.org/wiki/Fixed-point_arithmetic

http://en.wikipedia.org/wiki/Q_(number_format)#Math_operations

*/
`include "verisparse.svp"


module vs_fp_add#(parameter Q=15) (
    input fp_32_t a,
    input fp_32_t  b,
    output fp_32_t sum);

    assign sum = a + b;

endmodule

module vs_fp_sub#(parameter Q=15) (
    input fp_32_t a,
    input fp_32_t  b,
    output fp_32_t sum);

    assign sum = a - b;

endmodule


/// Saturated addition
module vs_fp_sadd #(parameter Q=15) (
    input fp_32_t a,
    input fp_32_t b,
    output fp_32_t sum);

    fp_64_t tmp;

    const fp_64_t INT_MAX = 32'h7FFFFFFF;
    const fp_64_t INT_MIN = -32'h7FFFFFFF;
    always_comb begin
        tmp = a + b;
        if (tmp > INT_MAX) begin
            tmp = INT_MAX;
        end
        if (tmp < INT_MIN) begin
            tmp = INT_MIN;
        end
        sum = fp_32_t' (tmp);
    end
endmodule


module vs_fp_mul#(parameter Q=15) (
    input fp_32_t a,
    input fp_32_t b,
    output fp_32_t sum);

    fp_64_t tmp;
    always_comb begin
        tmp = fp_64_t' (a * b);
        tmp = tmp >> Q;
        sum = fp_32_t' (tmp);
    end
endmodule
