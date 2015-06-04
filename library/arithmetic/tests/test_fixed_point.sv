`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;



module test_fixed_point;
    parameter Q = 15;
    fp_32_t a, b;
    fp_32_t add_result;
    fp_32_t sub_result;

    // instantiate the units under test
    vs_fp_add #(Q) uut_add (
        .a(a), .b(b), .result(add_result)
        );
    vs_fp_sub #(Q) uut_sub (
        .a(a), .b(b), .result(sub_result)
        );

    task automatic test_add_sub();
        `TEST_SET_START
        a = 10 << Q;
        b = 20 << Q;
        #1;
        //$display("a: %x, b: %x, sum: %x", a, b, add_result);
        `TEST_SET_EQUAL(add_result, 30<<Q);
        `TEST_SET_EQUAL(sub_result, -10<<Q);
        a = 10 << Q;
        b = -20 << Q;
        #1;
        `TEST_SET_EQUAL(add_result, -10<<Q);
        `TEST_SET_EQUAL(sub_result, 30<<Q);
        a = 20 << Q;
        b = -10 << Q;
        #1;
        `TEST_SET_EQUAL(add_result, 10<<Q);
        `TEST_SET_EQUAL(sub_result, 30<<Q);
        a = -20 << Q;
        b = -10 << Q;
        #1;
        `TEST_SET_EQUAL(add_result, -30<<Q);
        `TEST_SET_EQUAL(sub_result, -10<<Q);
        `TEST_SET_SUMMARIZE("sum")
    endtask

    initial begin
        test_add_sub();
    end

endmodule
