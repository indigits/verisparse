`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;


module test_matrix_multiply;


    logic clock = 1;
    logic reset_n = 0;

    fp_32_t a_2x2_in[3];
    fp_32_t x_in;
    fp_32_t y2_out;
    fp_32_t y4_out;
    vs_fp_2x2_matrix_vector_mul_array #(0) uut2 (clock, reset_n,
        a_2x2_in, x_in, y2_out);

    fp_32_t a_4x4_in[7];
    // vs_fp_4x4_matrix_vector_mul_array #(0) uut4 (clock, reset_n,
    //     a_4x4_in, x_in, y4_out);

    vs_fp_square_matrix_vector_mul_array#(0, 4) uut4 (clock, reset_n,
        a_4x4_in, x_in, y4_out);


    initial begin
        // a fixed number of clock cycles
        repeat (200) #50 clock = ~clock;
    end


    task automatic test_2x2_matrix_vector_mul_array;
        fp_32_t a[2][2];
        fp_32_t x[2] = {5, 10};
        fp_32_t y[2];
        a[0][0] = 1;
        a[0][1] = 2;
        a[1][0] = 3;
        a[1][1] = 4;
        // lower the reset pin
        reset_n = 0;
        a_2x2_in[0] = 0;
        a_2x2_in[1] = 0;
        a_2x2_in[2] = 0;
        // wait for next clock edge for reset to happen
        @(posedge clock);
        print_uut2_state(0);
        // remove the reset
        reset_n = 1;
        // feed in the new value
        x_in = x[0];

        @(posedge clock);
        print_uut2_state(1);
        x_in = 0;
        a_2x2_in[0] = 0;
        a_2x2_in[1] = a[0][0];
        a_2x2_in[2] = 0;

        @(posedge clock);
        print_uut2_state(2);
        x_in = x[1];
        a_2x2_in[0] = a[0][1];
        a_2x2_in[1] = 0;
        a_2x2_in[2] = a[1][0];

        @(posedge clock);
        print_uut2_state(3);
        x_in = 0;
        a_2x2_in[0] = 0;
        a_2x2_in[1] = a[1][1];
        a_2x2_in[2] = 0;

        @(posedge clock);
        print_uut2_state(4);
        a_2x2_in[0] = 0;
        a_2x2_in[1] = 0;
        a_2x2_in[2] = 0;
        y[0] = y2_out;

        @(posedge clock);
        print_uut2_state(5);
        @(posedge clock);
        print_uut2_state(6);
        y[1] = y2_out;

        $display("y[0]: %d, y[1]: %d", y[0], y[1]);
    endtask

    task automatic print_uut2_state(int i);
        $write("[%2d]  ", i);
        $write("a0: %4d, a1: %4d, a2: %4d      ", 
            uut2.a_in[0], uut2.a_in[1], uut2.a_in[2]);

        $write("x0: %4d, x1: %4d, x2: %4d, x3: %4d      ",
            uut2.x_in, uut2.x_link[0], uut2.x_link[1], uut2.x_link[2]);
        
        $write("y1: %4d, y2: %4d, y3: %4d",
            uut2.y_link[0], uut2.y_link[1], uut2.y_link[2]);
        $display("");
    endtask 



    task automatic test_4x4_matrix_vector_mul_array;
        fp_32_t a[4][4];
        fp_32_t x[4] = {1, 2, 3, 4};
        fp_32_t y[4];
        int cnt = 0;
        a[0][0] = 1;
        a[0][1] = 2;
        a[0][2] = 3;
        a[0][3] = 4;

        a[1][0] = 2;
        a[1][1] = 4;
        a[1][2] = 6;
        a[1][3] = 8;

        a[2][0] = 3;
        a[2][1] = 6;
        a[2][2] = 9;
        a[2][3] = 12;

        a[3][0] = 4;
        a[3][1] = 8;
        a[3][2] = 12;
        a[3][3] = 16;

        // lower the reset pin
        reset_n = 0;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = 0;
        a_4x4_in[3] = 0;
        a_4x4_in[4] = 0;
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;
        // wait for next clock edge for reset to happen
        @(posedge clock);
        print_uut4_state(cnt++);
        // remove the reset
        reset_n = 1;
        // feed in the new value
        x_in = x[0];

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = x[1];

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = 0;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = 0;
        a_4x4_in[3] = a[0][0];
        a_4x4_in[4] = 0;
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = x[2];
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = a[0][1];
        a_4x4_in[3] = 0;
        a_4x4_in[4] = a[1][0];
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = 0;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = a[0][2];
        a_4x4_in[2] = 0;
        a_4x4_in[3] = a[1][1];
        a_4x4_in[4] = 0;
        a_4x4_in[5] = a[2][0];
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = x[3];
        a_4x4_in[0] = a[0][3];
        a_4x4_in[1] = 0;
        a_4x4_in[2] = a[1][2];
        a_4x4_in[3] = 0;
        a_4x4_in[4] = a[2][1];
        a_4x4_in[5] = 0;
        a_4x4_in[6] = a[3][0];

        @(posedge clock);
        print_uut4_state(cnt++);
        x_in = 0;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = a[1][3];
        a_4x4_in[2] = 0;
        a_4x4_in[3] = a[2][2];
        a_4x4_in[4] = 0;
        a_4x4_in[5] = a[3][1];
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        y[0] = y4_out;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = a[2][3];
        a_4x4_in[3] = 0;
        a_4x4_in[4] = a[3][2];
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;
        
        @(posedge clock);
        print_uut4_state(cnt++);
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = 0;
        a_4x4_in[3] = a[3][3];
        a_4x4_in[4] = 0;
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);
        y[1] = y4_out;
        a_4x4_in[0] = 0;
        a_4x4_in[1] = 0;
        a_4x4_in[2] = 0;
        a_4x4_in[3] = 0;
        a_4x4_in[4] = 0;
        a_4x4_in[5] = 0;
        a_4x4_in[6] = 0;

        @(posedge clock);
        print_uut4_state(cnt++);

        @(posedge clock);
        print_uut4_state(cnt++);
        y[2] = y4_out;

        @(posedge clock);
        print_uut4_state(cnt++);

        @(posedge clock);
        print_uut4_state(cnt++);
        y[3] = y4_out;

        $display("y[0]: %d, y[1]: %d, y[2]: %d, y[3]: %d", 
            y[0], y[1], y[2], y[3]);
    endtask

    task automatic print_uut4_state(int i);
        $write("[%2d]  ", i);
        $write("a0: %2d, a1: %2d, a2: %2d, a3: %2d, a4: %2d, a5: %2d, a6: %2d      ", 
            uut4.a_in[0], uut4.a_in[1], uut4.a_in[2],
            uut4.a_in[3], uut4.a_in[4], uut4.a_in[5],
            uut4.a_in[6]
            );

        $write("x_in: %2d, x0: %2d, x1: %2d, x2: %2d, x3: %2d, x4: %2d, x5: %2d, x6: %2d      ",
            uut4.x_in, uut4.x_link[0], 
            uut4.x_link[1], uut4.x_link[2], uut4.x_link[3],
            uut4.x_link[4], uut4.x_link[5], uut4.x_link[6]
            );
        
        $write("y0: %2d, y1: %2d, y2: %2d, y3: %2d, y4: %2d, y5: %2d, y6: %2d",
            uut4.y_link[0], uut4.y_link[1], uut4.y_link[2],
            uut4.y_link[3], uut4.y_link[4], uut4.y_link[5],
            uut4.y_link[6]
            );
        $display("");
    endtask 


    initial begin
        //test_2x2_matrix_vector_mul_array();
        test_4x4_matrix_vector_mul_array();
    end

endmodule
