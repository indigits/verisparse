`include "verisparse.svh"

/**
This module provides various functions
related to the sensing matrix.

- Loading the sensing matrix in an in-built memory
- Computing inner product of all columns in 
  sensing matrix with a given residual.
- Computing the approximation using the selected atoms of sensing matrix.
*/
module vs_sensing_matrix_processor #(parameter ROWS=64, 
    parameter COLUMNS=256,
    parameter Q=15,
    parameter BATCH_SIZE=ROWS) (
    input logic clock,    // Clock
    input logic reset_n,  // Asynchronous reset active low
    /*
    This port is used to specify the address for reading
    data from the input memory.

    For computing inner products, this is read address
    for memory holding residual.
    */
    output logic [7:0] read_addr,
    /*
    This port is used to load data from input memory.

    For computing inner products, this is input data
    port for reading residual values.

    For loading the sensing matrix, this port
    acts as the input port for sensing matrix 
    cells. Sensing matrix is read in column wise.
    Address generation is not the responsibility
    of this unit.
    */
    input logic[FP_DATA_BUS_WIDTH-1:0]  read_data,
    output logic prod_write_enable,
    output logic [7:0] write_addr,
    output logic[FP_DATA_BUS_WIDTH-1:0]  write_data,
    input vs_sensing_matrix_command_t command,
    input logic start, 
    output logic done,
    output bit batch_products_transferred
);

    parameter BATCHES = COLUMNS / BATCH_SIZE;

    typedef enum {
    IDLE,  // the module is doing nothing

    // states for computing inner product

    RESIDUAL_LOAD_DELAY, // one cycle required for introducing the delay for loading from residual memory
    COMPUTE_PRODUCT, // mac units are in action and inner products are being computed
    CAPTURE_PRODUCTS, // inner products are being transferred to local registers
    WAIT_PROD_TRANSFER, // inner products are still being transferred to RAM.


    // states for loading sensing matrix
    LOAD_MATRIX
    } states_t;



    fp_32_t phi[ROWS][COLUMNS];
    fp_32_t batch_products[BATCH_SIZE];
    fp_32_t a_in[BATCH_SIZE];
    fp_32_t b_in[BATCH_SIZE];
    fp_32_t result[BATCH_SIZE];

    logic reset_macs_n;
    states_t state = IDLE;
    int batch  = 0;
    int batch_column_start = 0;
    int row = 0;
    bit batch_compute_done = 0;
    int write_row = 0;
    int phi_row = 0;
    int phi_col = 0;

    always_comb begin
        batch_column_start  = batch * BATCH_SIZE;
    end


    generate
        genvar i;
        for (i=0; i < BATCH_SIZE; ++i) begin : macs
            vs_fp_mac#(Q) mac(clock, reset_macs_n, a_in[i], b_in[i], result[i]);
        end
    endgenerate

    always_ff @(posedge clock) begin
        if (!reset_n) begin
            state <= IDLE;
            reset_macs_n <= 0;
            row <= 0;
            read_addr <= 0;
            done <= 0;
            write_row <= 0;
        end
        else begin
            reset_macs_n <= 1;
            batch_compute_done <= 0;
            case (state) 
                IDLE: begin
                    reset_macs_n <= 0;
                    done <= 0;
                    if(start) begin
                        case(command)
                            COMPUTE_INNER_PRODUCTS: begin
                                state <= RESIDUAL_LOAD_DELAY;
                                batch <= 0;
                            end
                            LOAD_SENSING_MATRIX : begin
                                state <= LOAD_MATRIX;
                            end
                        endcase
                    end
                end
                /*************************************************
                Implementation of computation of inner product
                **************************************************/
                RESIDUAL_LOAD_DELAY : begin
                    // reset all mac units
                    reset_macs_n <= 0;
                    read_addr<= read_addr + 1;
                    state <= COMPUTE_PRODUCT;
                end
                COMPUTE_PRODUCT : begin
                    if (row == ROWS) begin
                        row <= 0;
                        read_addr <= 0;
                        state <= CAPTURE_PRODUCTS;
                    end
                    else begin
                        //$display("read_addr: %d, read_data: %d", read_addr, read_data);
                        for (int i=0;i < BATCH_SIZE; ++i) begin
                            a_in[i] <= phi[row][batch_column_start+i];
                            b_in[i] <= read_data;
                        end
                        row <= row + 1;
                        read_addr<= read_addr + 1;
                    end
                end
                CAPTURE_PRODUCTS : begin
                    // transfer all mac results immediately
                    for (int i=0;i < BATCH_SIZE; ++i) begin
                        batch_products[i] <= result[i];
                    end
                    // indicate that a batch of inner products has been computed
                    batch_compute_done <= 1;
                    // indicate that inner products haven't yet been transferred to RAM.
                    batch_products_transferred <= 0;
                    if (batch == BATCHES-1)  begin
                        batch <= 0;
                        state <= WAIT_PROD_TRANSFER;
                    end
                    else begin
                        batch <= batch + 1;
                        state <= RESIDUAL_LOAD_DELAY;
                        read_addr <= 0;
                    end
                end
                WAIT_PROD_TRANSFER : begin
                    if (batch_products_transferred == 1) begin 
                        state <= IDLE;
                        done <= 1;
                    end
                end
                /*************************************************
                Implementation of loading of sensing matrix
                **************************************************/
                LOAD_MATRIX : begin : lm
                    phi[phi_row][phi_col] <= read_data;
                    if (phi_row == ROWS - 1) begin : a
                        // move on to next row
                        phi_row <= 0;
                        if (phi_col == COLUMNS -1 ) begin
                            /*
                            Matrix loading has been completed.
                            It's time to go back to IDLE state.
                            */
                            state <= IDLE;
                            done <= 1;
                            phi_col <= 0;
                        end
                        else begin
                            // next column
                            phi_col <= phi_col + 1;
                        end
                    end : a
                    else begin : b
                        phi_row <= phi_row + 1;
                    end : b
                end : lm
            endcase
        end
    end

    // This block is responsible for transferring inner product data
    // into RAM
    always_ff @(posedge clock) begin
        if (batch_compute_done == 1) begin
            write_row <= 0;
            prod_write_enable <= 1;
            batch_products_transferred <= 0;
            if (batch == 1) write_addr <= -1;
        end
        if (write_row == BATCH_SIZE) begin
            prod_write_enable <= 0;
        end
        else begin
            prod_write_enable <= 1;
            write_data <= batch_products[write_row];
            write_addr <= write_addr + 1;
            write_row <= write_row + 1;
            if (write_row == BATCH_SIZE - 1) begin
                batch_products_transferred <= 1;
            end
        end
    end

endmodule
