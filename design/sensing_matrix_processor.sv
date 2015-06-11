`include "verisparse.svh"



interface vs_dict_proc_if(
    input logic clock,// Clock
    input logic reset_n// Asynchronous reset active low
    );

    /*
    This port is used to specify the address for reading
    data from the input memory.

    For computing inner products, this is read address
    for memory holding residual.
    */
    logic [7:0] read_addr;
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
    logic[FP_DATA_BUS_WIDTH-1:0]  read_data;

    logic write_enable;
    logic [7:0] write_addr;
    logic[FP_DATA_BUS_WIDTH-1:0]  write_data;

    vs_dict_proc_command_t command;
    logic start; 
    logic done;
    logic batch_products_transferred;



    modport processor(
        input clock, input reset_n,
        input start, output done,


        output read_addr, input read_data,

        output write_enable, write_addr, write_data,

        input command,
        output batch_products_transferred
        );

    modport driver(
        output start, input done,

        input read_addr, output read_data,

        input write_enable, write_addr, write_data,

        output command,
        input batch_products_transferred
        );

endinterface


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
    vs_dict_proc_if.processor bus
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
            vs_fp_mac#(Q) mac(bus.clock, reset_macs_n, a_in[i], b_in[i], result[i]);
        end
    endgenerate

    always_ff @(posedge bus.clock) begin
        if (!bus.reset_n) begin
            state <= IDLE;
            reset_macs_n <= 0;
            row <= 0;
            bus.read_addr <= 0;
            bus.done <= 0;
            write_row <= 0;
            bus.batch_products_transferred <= 0;
        end
        else begin
            reset_macs_n <= 1;
            batch_compute_done <= 0;
            bus.batch_products_transferred <= 0;
            case (state) 
                IDLE: begin
                    reset_macs_n <= 0;
                    bus.done <= 0;
                    if(bus.start) begin
                        case(bus.command)
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
                    bus.read_addr<= bus.read_addr + 1;
                    state <= COMPUTE_PRODUCT;
                end
                COMPUTE_PRODUCT : begin
                    if (row == ROWS) begin
                        row <= 0;
                        bus.read_addr <= 0;
                        state <= CAPTURE_PRODUCTS;
                    end
                    else begin
                        //$display("read_addr: %d, read_data: %d", read_addr, read_data);
                        for (int i=0;i < BATCH_SIZE; ++i) begin
                            a_in[i] <= phi[row][batch_column_start+i];
                            b_in[i] <= bus.read_data;
                        end
                        row <= row + 1;
                        bus.read_addr<= bus.read_addr + 1;
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
                    bus.batch_products_transferred <= 0;
                    if (batch == BATCHES-1)  begin
                        batch <= 0;
                        state <= WAIT_PROD_TRANSFER;
                    end
                    else begin
                        batch <= batch + 1;
                        state <= RESIDUAL_LOAD_DELAY;
                        bus.read_addr <= 0;
                    end
                end
                WAIT_PROD_TRANSFER : begin
                    if (bus.batch_products_transferred == 1) begin 
                        state <= IDLE;
                        bus.done <= 1;
                        // down this signal. only meant for one clock.
                        bus.batch_products_transferred <= 0;
                    end
                end
                /*************************************************
                Implementation of loading of sensing matrix
                **************************************************/
                LOAD_MATRIX : begin : lm
                    phi[phi_row][phi_col] <= bus.read_data;
                    if (phi_row == ROWS - 1) begin : a
                        // move on to next row
                        phi_row <= 0;
                        if (phi_col == COLUMNS -1 ) begin
                            /*
                            Matrix loading has been completed.
                            It's time to go back to IDLE state.
                            */
                            state <= IDLE;
                            bus.done <= 1;
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
    always_ff @(posedge bus.clock) begin
        if (COMPUTE_INNER_PRODUCTS == bus.command) begin
            if (batch_compute_done == 1) begin
                write_row <= 0;
                bus.write_enable <= 1;
                bus.batch_products_transferred <= 0;
                if (batch == 1) bus.write_addr <= -1;
            end
            if (bus.write_enable == 1) begin
                if (write_row == BATCH_SIZE) begin
                    bus.write_enable <= 0;
                end
                else begin
                    bus.write_data <= batch_products[write_row];
                    bus.write_addr <= bus.write_addr + 1;
                    write_row <= write_row + 1;
                    if (write_row == (BATCH_SIZE - 1)) begin
                        bus.batch_products_transferred <= 1;
                        // $display("batch completed, write_row: %d, write_addr: %d: write_data: %d", 
                        //     write_row, write_addr, write_data);
                    end
                end
            end
        end
    end

endmodule


module vs_max_identifier #(parameter BATCH_SIZE=64) (
    input logic clock,    // Clock
    input logic reset_n,  // Asynchronous reset active low
    output logic [7:0] read_addr,
    input logic[FP_DATA_BUS_WIDTH-1:0]  read_data,
    output byte location,
    // output from max unit
    output fp_32_t max_value,
    input logic start, 
    output bit batch_done
);

    typedef enum {
        IDLE,
        MEM_DELAY,
        GET_COUNT,
        COMPUTE_MAX
    } states_t;

    states_t state = IDLE;
    // number of elements processed so far
    int counter = 0;
    // input to max unit
    fp_32_t cur_value;
    // number of elements processed in the batch
    fp_32_t batch_counter = 0;
    // stores the absolute value of current value
    fp_32_t abs_value;
    // stores the absolute max value
    fp_32_t abs_max_value;
    always_comb begin
        // computation of absolute value
        abs_value = (cur_value < 0) ? -cur_value : cur_value;
    end

    always_ff @(posedge clock) begin
        if (~reset_n) begin
            read_addr <= 0;
            location <= 0;
            state <= IDLE;
            max_value <= 0;
            cur_value <= 0;
        end
        else begin
            case(state) 
                IDLE: begin
                    if (start) begin
                        state <= MEM_DELAY;
                        if (read_addr == 0) begin
                        end
                        else begin
                        end
                        batch_counter <= 0;
                        batch_done <= 0;
                    end
                end
                MEM_DELAY : begin
                    read_addr<= read_addr + 1;
                    state <= COMPUTE_MAX;
                end
                COMPUTE_MAX : begin
                    //$display("addr: %d, max: %d", read_addr, fp_32_t'(read_data));
                    cur_value <= fp_32_t'(read_data);
                    if (abs_value > abs_max_value) begin
                        location <= counter - 1;
                        abs_max_value <= abs_value;
                        max_value <= cur_value;
                    end
                    counter <= counter + 1;
                    if (batch_counter == BATCH_SIZE-1) begin
                        // This batch has been processed
                        state <= IDLE;
                        batch_done <= 1;
                    end
                    else begin
                        // next address
                        read_addr <= read_addr + 1;
                        batch_counter <= batch_counter + 1;
                    end
                end
            endcase
        end
    end

endmodule
