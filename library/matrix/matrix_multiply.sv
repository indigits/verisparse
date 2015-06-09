`include "verisparse.svh"



module vs_fp_mat_mul_cell#(parameter Q=15) (
    input clock,
    input reset_n,
    input fp_32_t a_in,
    input fp_32_t b_in,
    input fp_64_t c_in,
    output fp_32_t a_out,
    output fp_32_t b_out,
    output fp_32_t c_out);

    assign a_out = a_in;

    always_ff @(posedge clock)
        if (~reset_n) begin
            c_out <= 0;
            b_out <= 0;
        end
        else begin
            c_out <= fp_64_t'(a_in * b_in) + c_in;
            b_out <= b_in;
        end
endmodule


module vs_matrix_mul #(parameter Q=15, parameter N=3) (
    );
    parameter num_cells = 3*N - 2; 
endmodule



module vs_inner_prod_step_cell(
    input clock,
    input reset_n,
    input fp_32_t a_in,
    input fp_32_t x_in,
    input fp_64_t y_in,
    output fp_32_t x_out,
    output fp_64_t y_out
    );
    always_ff @(posedge clock)
        if (~reset_n) begin
            x_out <= 0;
            y_out <= 0;
        end
        else begin
            y_out <= fp_64_t'(a_in * x_in) + y_in;
            x_out <= x_in;
        end
endmodule


/*
This provides the systolic array for computing 
y  = A x 

Individual equations

y_1 = a_11 * x_1 + a_12 * x_2.
y_2 = a_21 * x_1 + a_22 * x_2.

Number of bands = 2 * 2 -  1 = 3.
Number of array cells required = 3.

From left to right, the cells are numbered as 1, 2, 3.
*/
module vs_fp_2x2_matrix_vector_mul_array#(parameter Q=15)(
    input clock,
    input reset_n,
    input fp_32_t a_in[3],
    input fp_32_t x_in,
    output fp_32_t y_out
    );
    fp_64_t y0 = 0;
    fp_64_t y_link[3];
    fp_32_t x_link[3];


    vs_inner_prod_step_cell cell_0(clock, reset_n, a_in[0], 
        x_in, y_link[1], x_link[0], y_link[2]);
    vs_inner_prod_step_cell cell_1(clock, reset_n, a_in[1], 
        x_link[0], y_link[0], x_link[1], y_link[1]);
    vs_inner_prod_step_cell cell_2(clock, reset_n, a_in[2],
        x_link[1], y0, x_link[2], y_link[0]);

    always_comb begin
        y_out = y_link[2] >> Q;
    end

endmodule


/*
This provides the systolic array for computing 
y  = A x 

Individual equations

y_1 = a_11 * x_1 + a_12 * x_2 + a_13 * x_3 + a_14 * x_4.
y_2 = a_21 * x_1 + a_22 * x_2 + a_23 * x_3 + a_24 * x_4.
y_3 = a_31 * x_1 + a_32 * x_2 + a_33 * x_3 + a_34 * x_4.
y_4 = a_41 * x_1 + a_42 * x_2 + a_43 * x_3 + a_44 * x_4.

Number of bands = 2 * 4 -  1 = 7.
Number of array cells required = 7.

From left to right, the cells are numbered as 
0, 1, 2, 3, 4, 5, 6, 7.
*/
module vs_fp_4x4_matrix_vector_mul_array#(parameter Q=15)(
    input clock,
    input reset_n,
    input fp_32_t a_in[7],
    input fp_32_t x_in,
    output fp_32_t y_out
    );
    fp_64_t y0 = 0;
    fp_64_t y_link[7];
    fp_32_t x_link[7];


    vs_inner_prod_step_cell cell_0(clock, reset_n, a_in[0], 
        x_in, y_link[5], x_link[0], y_link[6]);

    vs_inner_prod_step_cell cell_1(clock, reset_n, a_in[1], 
        x_link[0], y_link[4], x_link[1], y_link[5]);
    
    vs_inner_prod_step_cell cell_2(clock, reset_n, a_in[2],
        x_link[1], y_link[3], x_link[2], y_link[4]);

    vs_inner_prod_step_cell cell_3(clock, reset_n, a_in[3],
        x_link[2], y_link[2], x_link[3], y_link[3]);

    vs_inner_prod_step_cell cell_4(clock, reset_n, a_in[4],
        x_link[3], y_link[1], x_link[4], y_link[2]);

    vs_inner_prod_step_cell cell_5(clock, reset_n, a_in[5],
        x_link[4], y_link[0], x_link[5], y_link[1]);

    vs_inner_prod_step_cell cell_6(clock, reset_n, a_in[6],
        x_link[5], y0, x_link[6], y_link[0]);

    always_comb begin
        y_out = y_link[6] >> Q;
    end

endmodule


module vs_fp_square_matrix_vector_mul_array#(parameter Q=15, parameter N=4)(
    input clock,
    input reset_n,
    input fp_32_t a_in[2*N - 1],
    input fp_32_t x_in,
    output fp_32_t y_out
    );
    parameter NUM_BANDS = 2 * N - 1;
    fp_64_t y0 = 0;
    fp_64_t y_link[NUM_BANDS];
    fp_32_t x_link[NUM_BANDS];

    vs_inner_prod_step_cell cell_0(clock, reset_n, a_in[0], 
        x_in, y_link[NUM_BANDS-2], x_link[0], y_link[NUM_BANDS-1]);


    vs_inner_prod_step_cell cell_6(clock, reset_n, a_in[NUM_BANDS-1],
        x_link[NUM_BANDS-2], y0, x_link[NUM_BANDS-1], y_link[0]);

    generate
        genvar i;
        for (i=1; i < NUM_BANDS-1; i = i + 1) begin : gen
            vs_inner_prod_step_cell cell_i(clock, reset_n, a_in[i], 
                x_link[i-1], y_link[NUM_BANDS-i-2], 
                x_link[i], y_link[NUM_BANDS-i-1]);
        end
    endgenerate

    always_comb begin
        y_out = y_link[NUM_BANDS-1] >> Q;
    end
endmodule
