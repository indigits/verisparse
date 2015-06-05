`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;



module test_fixed_point;
    parameter Q = 15;
    fp_32_t a, b;
    fp_32_t add_result;
    fp_32_t sub_result;
    fp_32_t mul_result;
    fp_32_t a_out, b_out;
    logic clock = 1;
    logic reset_n;
    fp_32_t mac_result;

    // instantiate the units under test
    vs_fp_add #(Q) uut_add (
        .a(a), .b(b), .result(add_result)
        );
    vs_fp_sub #(Q) uut_sub (
        .a(a), .b(b), .result(sub_result)
        );
    vs_fp_mul #(Q) uut_mul (
        .a(a), .b(b), .result(mul_result)
        );
    vs_fp_mac #(Q) uut_mac (
        .clock(clock),
        .reset_n(reset_n),
        .a_in(a), .b_in(b), 
        .a_out(a_out), .b_out(b_out),
        .result(mac_result)
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
        `TEST_SET_SUMMARIZE("test_add_sub")
    endtask

    task automatic test_mul();
        `TEST_SET_START
        int n = 8;
        a = (1 << n) << Q;
        b = (1 << n) << Q;
        #1;
        $display("a: %x, b: %x, product: %x, tmp: %x", 
            a, b, mul_result, uut_mul.tmp);
        `TEST_SET_EQUAL(mul_result, (1 << (2*n))<<Q);
        `TEST_SET_SUMMARIZE("test_mul")
    endtask

    task automatic test_mac();
        `TEST_SET_START
        fp_32_t as[] = {1, 2, 3, 4, 5, 4, 3, 2, 1};
        fp_32_t bs[] = {1, 2, 3, 4, 5, 4, 3, 2, 1};
        fp_32_t results[] = {0, 1, 5, 14, 30, 55, 71, 80, 84, 85};
        const int n = as.size;
        reset_n = 0;
        a = 0;
        b = 0;
        @(posedge clock);
        #10;
        // At this point the MAC unit has been reset.
        `TEST_SET_EQUAL(uut_mac.c, 0);
        reset_n = 1;
        // update data in Q format
        for (int i=0; i < n; ++i) begin
            as[i] = as[i] << Q;
            bs[i] = bs[i] << Q;
        end
        for (int i=0; i < n; ++i) begin
            // wait for the next clock cycle
            @(posedge clock);
            // load data
            a = as[i];
            b = bs[i];
            #10;
            `TEST_SET_EQUAL((mac_result >> Q), results[i]);
            //$display("uut_mac.c: %x mac_result: %d", uut_mac.c, (mac_result >> Q));
        end
        @(posedge clock);
        #10;
        `TEST_SET_EQUAL((mac_result >> Q), results[n]);
        `TEST_SET_SUMMARIZE("test_mac")
    endtask

    initial begin
        test_add_sub();
        test_mul();
        test_mac();
    end

    initial begin
        // a fixed number of clock cycles
        repeat (2000) #50 clock = ~clock;
    end

endmodule
