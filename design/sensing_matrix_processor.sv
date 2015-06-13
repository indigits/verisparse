`include "verisparse.svh"

//`define DICT_PROC_DEBUG


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
    COMPUTING_PRODUCT, // mac units are in action and inner products are being computed
    CAPTURING_PRODUCTS, // inner products are being transferred to local registers
    WAIT_PROD_TRANSFER, // inner products are still being transferred to RAM.
    LOADING_ATOM_SCALE_FACTOR, // loading the atom index and scale factor.
    SUBTRACTING_SCALED_ATOM_FROM_DATA, // subtracting a scaled atom from data
    // states for loading sensing matrix
    LOADING_MATRIX
    } states_t;

    typedef enum{
        LASF_LOAD_ATOM_LOCATION,
        LASF_LOAD_ATOM_SCALE_FACTOR
    } lasf_states_t;

    typedef enum{
        SSAFD_A,
        SSAFD_B,
        SSAFD_C,
        SSAFD_D
    }ssafd_states_t;

    fp_32_t phi[ROWS][COLUMNS];
    fp_32_t batch_products[BATCH_SIZE];
    fp_32_t a_in[BATCH_SIZE];
    fp_32_t b_in[BATCH_SIZE];
    fp_32_t result[BATCH_SIZE];

    /**
    Current command to be executed by the processor
    */
    vs_dict_proc_command_t current_command;

    logic reset_macs_n;


    states_t state = IDLE;
    lasf_states_t lasf_state;
    // State for the process of subtracting a scaled atom from data
    ssafd_states_t ssafd_state;

    int batch  = 0;
    int batch_column_start = 0;
    int row = 0;
    bit batch_compute_done = 0;
    int write_row = 0;
    int phi_row = 0;
    int phi_col = 0;

    int atom_index;
    fp_32_t atom_scale_factor;

    always_comb begin
        batch_column_start  = batch * BATCH_SIZE;
    end

    // implements result = a - scale * b;
    function automatic fp_32_t scale_sub(fp_32_t a, fp_32_t b, fp_32_t scale);
        fp_64_t  a2 = fp_64_t'(a);
        fp_64_t scale2 = fp_64_t'(scale);
        fp_64_t b2 = fp_64_t'(b);
        a2 = a2 - ((scale2*b2) >> Q);
        //$display("DP: a: %f, b: %f, a': %f", vs_fixed_to_real(a), 
        //    vs_fixed_to_real(b), vs_fixed_to_real(fp_32_t'(a2)));
        return fp_32_t'(a2);
    endfunction

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
            case (state) 
                IDLE: begin
                    reset_macs_n <= 0;
                    bus.done <= 0;
                    row <= 0;
                    bus.read_addr <= 0;
                    if(bus.start) begin
                        current_command <= bus.command;
                        case(bus.command)
                            COMPUTE_INNER_PRODUCTS: begin
`ifdef DICT_PROC_DEBUG
                                $display("DP: Initiating inner product computation");
`endif
                                state <= RESIDUAL_LOAD_DELAY;
                                batch <= 0;
                            end
                            LOAD_SENSING_MATRIX : begin
                                state <= LOADING_MATRIX;
                            end
                            LOAD_ATOM_SCALE_FACTOR : begin
`ifdef DICT_PROC_DEBUG
                                $display("DP: Loading atom scale factor");
`endif
                                state <= LOADING_ATOM_SCALE_FACTOR;
                                lasf_state <= LASF_LOAD_ATOM_LOCATION;
                            end
                            SUBTRACT_SCALED_ATOM_FROM_DATA : begin
                                state <= SUBTRACTING_SCALED_ATOM_FROM_DATA;
                                ssafd_state <= SSAFD_A;
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
                    state <= COMPUTING_PRODUCT;
                end
                COMPUTING_PRODUCT : begin
                    if (row == ROWS) begin
                        row <= 0;
                        bus.read_addr <= 0;
                        state <= CAPTURING_PRODUCTS;
`ifdef DICT_PROC_DEBUG
                        $display("DP: Inner product batch computation completed.");
`endif
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
                CAPTURING_PRODUCTS : begin
                    // transfer all mac results immediately
                    for (int i=0;i < BATCH_SIZE; ++i) begin
`ifdef DICT_PROC_DEBUG
                    // $display("DP: product[%d] %f.", batch_column_start+i,
                    //     vs_fixed_to_real(result[i]));
`endif                        batch_products[i] <= result[i];
                    end
`ifdef DICT_PROC_DEBUG
                    $display("DP: Inner product batch capture completed.");
`endif
                    // indicate that a batch of inner products has been computed
                    batch_compute_done <= 1;
                    if (batch == BATCHES-1)  begin
                        batch <= 0;
                        state <= WAIT_PROD_TRANSFER;
`ifdef DICT_PROC_DEBUG
                        $display("DP: Waiting for final product transfers to complete.");
`endif
                    end
                    else begin
                        batch <= batch + 1;
                        state <= RESIDUAL_LOAD_DELAY;
`ifdef DICT_PROC_DEBUG
                        $display("DP: Moving on to next batch.");
`endif
                        bus.read_addr <= 0;
                    end
                end
                WAIT_PROD_TRANSFER : begin
                    if (bus.batch_products_transferred == 1) begin 
                        state <= IDLE;
                        bus.done <= 1;
                        // down this signal. only meant for one clock.
                        bus.batch_products_transferred <= 0;
`ifdef DICT_PROC_DEBUG
                        $display("DP: All inner products transferred.");
`endif
                    end
                end
                /*************************************************
                Implementation of loading of sensing matrix
                **************************************************/
                LOADING_MATRIX : begin : lm
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
                LOADING_ATOM_SCALE_FACTOR : begin : lasf
                    case(lasf_state) 
                        LASF_LOAD_ATOM_LOCATION : begin
                            atom_index <= bus.read_data;
                            lasf_state <= LASF_LOAD_ATOM_SCALE_FACTOR;
                        end
                        LASF_LOAD_ATOM_SCALE_FACTOR : begin
                            state <= IDLE;
                            atom_scale_factor <= bus.read_data;
                            bus.done <= 1;
                        end
                    endcase
                end : lasf
                SUBTRACTING_SCALED_ATOM_FROM_DATA : begin
                    case (ssafd_state) 
                        SSAFD_A: begin
                            bus.read_addr <= 0;
                            bus.write_addr <= -1;
                            bus.write_enable <= 1;
                            ssafd_state <= SSAFD_B;
                            row <= 0;
                        end
                        SSAFD_B : begin
                            bus.read_addr <= bus.read_addr + 1;
                            ssafd_state <= SSAFD_C;
                        end
                        SSAFD_C : begin 
                            bus.read_addr <= bus.read_addr + 1;
                            bus.write_data <= scale_sub(fp_32_t'(bus.read_data), phi[row][atom_index], atom_scale_factor);
                            bus.write_addr <= bus.write_addr + 1;
                            row <= row + 1;
                            if (row == ROWS - 1) begin
                                ssafd_state <= SSAFD_D;
                            end
                        end
                        SSAFD_D : begin
                            state <= IDLE;
                            bus.write_enable <= 0;
                            bus.done <= 1;
                        end
                    endcase 
                end
            endcase
        end
    end

    // This block is responsible for transferring inner product data
    // into RAM
    always_ff @(posedge bus.clock) begin
        if (COMPUTE_INNER_PRODUCTS == current_command) begin
            bus.batch_products_transferred <= 0;
            if (batch_compute_done == 1) begin
                write_row <= 0;
                bus.write_enable <= 1;
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
`ifdef DICT_PROC_DEBUG
                        $display("DPT: batch completed, write_row: %d, write_addr: %d: write_data: %d", 
                            write_row, bus.write_addr, bus.write_data);
`endif
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
            abs_max_value <= 0;
            batch_counter <= 0;
            counter <= 0;
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
                    // $display("DP_MAX: addr: %d, cur: %f", 
                    //     read_addr, vs_fixed_to_real(fp_32_t'(read_data)));
                    cur_value <= fp_32_t'(read_data);
                    if (abs_value > abs_max_value) begin
                        location <= counter - 1;
                        abs_max_value <= abs_value;
                        max_value <= cur_value;
                        // $display("DP_MAX NEW: %d, %f", counter -1 , 
                        //     vs_fixed_to_real(cur_value));
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
