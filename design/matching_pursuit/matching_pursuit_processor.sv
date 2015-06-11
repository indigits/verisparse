`include "verisparse.svh"


/***
The source for input A for 
dictionary processor
*/
typedef enum {
  DICT_PROC_INPUT_A_X,
  DICT_PROC_INPUT_A_RESIDUAL,
  DICT_PROC_INPUT_A_DICTIONARY  
}dict_proc_read_a_source_t;

/**
Destination for output A for
dictionary processor
*/
typedef enum {
  DICT_PROC_OUTPUT_A_PROD,
  DICT_PROC_OUTPUT_A_RES
}dict_proc_write_a_dest_t;



interface vs_abs_max_identifier_if(input clock);
    // ports related to max identifier unit
    byte location;
    fp_32_t value;
    logic batch_done;

    modport processor(
        input clock,
        output location,
        output value,
        output batch_done
    );

    modport driver(
        input location,
        input value,
        input batch_done
    );
endinterface


interface vs_clk_rst_bus_if(
    input logic clock, 
    input logic reset_n);



    // ports for state machine of the algorithm
    modport alg_fsm(
        input clock,
        input reset_n
    ); 

endinterface

interface vs_start_done_bus_if ();
    logic start;
    logic done;
    modport processor(
        input start,
        output done);
    modport driver(
        output start,
        input done);
endinterface

module vs_matching_pursuit_main_loop(
    input clock,
    input reset_n,
    interface bus,
    interface x_bus,
    interface residual_bus,
    interface product_bus,
    interface dict_proc_bus,
    interface max_ident_bus
    );

    typedef enum{IDLE, 
        SWEEP_PRE,
        SWEEP,
        IDENTIFY_MAX, 
        UPDATE_SUPPORT, 
        UPDATE_SOLUTION, 
        UPDATE_RESIDUAL
    } states_t;
    typedef enum{
        US_SET_X_READ_ADDR,
        US_READ_X_VALUE,
        US_SET_X_WRITE_ADDR,        
        US_WRITE_X_VALUE,
        US_MOVE_TO_NEXT_STEP

    }update_support_states_t;

    const int cycles = 2;
    int unsigned dummy_counter;
    states_t state = IDLE;
    update_support_states_t update_support_state;
    fp_32_t current_x_value;

    always_ff @(posedge clock) begin
        if (!reset_n) begin
            bus.done <= 0;
            dummy_counter <= cycles;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (bus.start) begin
                        dict_proc_bus.command <= COMPUTE_INNER_PRODUCTS;
                        dict_proc_bus.start <= 1;
                        state <= SWEEP_PRE;
                    end
                    bus.done <= 0;
                end
                SWEEP_PRE: begin
                    // lower the start pin
                    dict_proc_bus.start <= 0;
                    state <= SWEEP;
                end
                SWEEP : begin
                    // wait for inner products to be computed
                    if (dict_proc_bus.done) begin
                        // The loop has been processed
                        state <= IDENTIFY_MAX;
                    end
                end
                IDENTIFY_MAX : begin
                    if (max_ident_bus.batch_done) begin
                        state <= UPDATE_SUPPORT;
                        update_support_state <= US_SET_X_READ_ADDR;
                    end
                end
                UPDATE_SUPPORT : begin
                    case(update_support_state)
                        US_SET_X_READ_ADDR: begin
                            x_bus.read_addr <= max_ident_bus.location;
                            update_support_state <= US_READ_X_VALUE;
                            // $display("current x value: %f",
                            //     vs_fixed_to_real(int'(PE.x_ram.ram[max_ident_bus.location])));
                        end
                        US_READ_X_VALUE : begin
                            current_x_value <= x_bus.read_data;
                            x_bus.write_addr <= max_ident_bus.location;
                            update_support_state <= US_WRITE_X_VALUE;
                        end
                        US_WRITE_X_VALUE : begin
                            x_bus.write_enable <= 1;
                            x_bus.write_data <= current_x_value + max_ident_bus.value;
                            update_support_state <= US_MOVE_TO_NEXT_STEP;
                        end
                        US_MOVE_TO_NEXT_STEP : begin
                            x_bus.write_enable <= 0;
                            state <= UPDATE_SOLUTION;
                            dummy_counter <= cycles;
                        end
                    endcase
                end
                UPDATE_SOLUTION : begin
                    if (dummy_counter == 0) begin
                        // The loop has been processed
                        state <= UPDATE_RESIDUAL;
                        dummy_counter <= cycles;
                        // $display("updated x value: %f",
                        //     vs_fixed_to_real(int'(PE.x_ram.ram[max_ident_bus.location])));
                    end
                    else begin
                        // do some work
                        dummy_counter <= dummy_counter -1;
                        // remain in the state
                        state <= UPDATE_SOLUTION;
                    end
                end
                UPDATE_RESIDUAL : begin
                    if (dummy_counter == 0) begin
                        // The loop has been processed
                        state <= IDLE;
                        bus.done <= 1;
                    end
                    else begin
                        // do some work
                        dummy_counter <= dummy_counter -1;
                        // remain in the state
                        state <= UPDATE_RESIDUAL;
                    end
                end
                default : begin
                    // can't happen. how come here??
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


module vs_matching_pursuit_fsm (
    input clock,
    input reset_n,
    interface bus,
    interface loop_bus,
    interface y_bus,
    interface residual_bus
    );
    parameter M = SIGNAL_SIZE_DEFAULT;
    parameter N = DICTIONARY_SIZE_DEFAULT;
    parameter K = SPARSITY_LEVEL_DEFAULT;

    typedef enum {
    // processor is doing nothing
    IDLE, 
    // the processor is transferring data from y ram to r ram.
    TRANSFERRING_Y_TO_R_PRE, 
    TRANSFERRING_Y_TO_R, 
    TRANSFERRING_Y_TO_R_POST, 
    READY,  // the processor is ready to start iteration
    WORKING // the processor is executing next iteration
    } states_t;

    int unsigned k_counter;
    states_t state = IDLE;

    int transferred_entries = 0;
    bit y_to_r_transferred = 0;

    always_ff @(posedge clock) begin
        if (!reset_n) begin
            bus.done <= 0;
            k_counter <= K;
            loop_bus.start <= 0;
            state <= IDLE;
            y_to_r_transferred <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (bus.start) begin
                        state <= TRANSFERRING_Y_TO_R_PRE;
                        k_counter <= K;
                        transferred_entries <= 0;
                        y_bus.read_addr <= 0;
                        residual_bus.write_enable <= 1;
                    end
                    bus.done <= 0;
                end
                TRANSFERRING_Y_TO_R_PRE: begin
                    state <= TRANSFERRING_Y_TO_R;
                    y_bus.read_addr <= y_bus.read_addr + 1;
                    residual_bus.write_addr <= -1;
                end
                TRANSFERRING_Y_TO_R : begin
                    if (transferred_entries != M) begin
                        // $display("y: %d, %d, r: %d, %d",
                        //     y_bus.read_addr, y_bus.read_data,
                        //     residual_bus.write_addr, residual_bus.write_data);
                        residual_bus.write_data <= y_bus.read_data;
                        y_bus.read_addr <= y_bus.read_addr + 1;
                        residual_bus.write_addr <= residual_bus.write_addr + 1;
                        transferred_entries <= transferred_entries + 1;
                    end
                    else begin
                        y_to_r_transferred <= 1;
                        state <= READY;
                        residual_bus.write_enable <= 0;
                    end                    
                end
                READY : begin
                    if (k_counter == 0) begin
                        // The loop has been processed
                        state <= IDLE;
                        loop_bus.start <= 0;
                        bus.done <= 1;
                    end
                    else begin
                        // indicate the main loop module to start working
                        loop_bus.start <= 1;
                        // move to working state
                        state <= WORKING;
                    end
                end
                WORKING : begin
                    // unset the loop start flag
                    if (loop_bus.start ) loop_bus.start <= 0;
                    if (loop_bus.done == 0) begin
                        // we continue to wait
                        state <= WORKING;
                    end
                    else begin
                        // The current iteration is finished
                        // reduce the number of remaining iterations
                        k_counter <= k_counter - 1;
                        // move on to start the next iteration
                        state <= READY;
                    end
                end
                default : begin
                    // can't happen. how come here??
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


module matching_pursuit_chip(input clock,
        input reset_n);

    bit start = 0;
    bit done;

    vs_sync_ram_bus_if#(REPRESENTATION_ADDR_WIDTH) x_bus(clock);
    vs_sync_ram_bus_if#(SIGNAL_ADDR_WIDTH) y_bus(clock);
    vs_sync_ram_bus_if#(DICTIONARY_ADDR_WIDTH) dict_bus(clock);
    vs_sync_ram_bus_if#(8) product_bus(clock);
    vs_sync_ram_bus_if#(8) residual_bus(clock);


    parameter BATCH_SIZE = SIGNAL_SIZE_DEFAULT;

    vs_single_clock_synchronous_ram #(FP_DATA_BUS_WIDTH, 8) products(
        .clock(clock),
        .write_enable(product_bus.write_enable),
        .read_addr(product_bus.read_addr),
        .write_addr(product_bus.write_addr),
        .in_data(product_bus.write_data),
        .out_data(product_bus.read_data));


    vs_single_clock_synchronous_ram #(FP_DATA_BUS_WIDTH, 8) residuals(
        .clock(clock),
        .write_enable(residual_bus.write_enable),
        .read_addr(residual_bus.read_addr),
        .write_addr(residual_bus.write_addr),
        .in_data(residual_bus.write_data),
        .out_data(residual_bus.read_data));


    vs_single_clock_synchronous_ram #(FP_DATA_BUS_WIDTH) dict_ram(.clock(clock),
        .write_enable(dict_bus.write_enable),
        .read_addr(dict_bus.read_addr),
        .write_addr(dict_bus.write_addr),
        .in_data(dict_bus.read_data),
        .out_data(dict_bus.write_data));
    defparam dict_ram.ADDR_WIDTH = DICTIONARY_ADDR_WIDTH;


    vs_single_clock_synchronous_ram #(FP_DATA_BUS_WIDTH) y_ram(.clock(clock),
        .write_enable(y_bus.write_enable),
        .read_addr(y_bus.read_addr),
        .write_addr(y_bus.write_addr),
        .in_data(y_bus.write_data),
        .out_data(y_bus.read_data));
    defparam y_ram.ADDR_WIDTH = SIGNAL_ADDR_WIDTH;


    vs_single_clock_synchronous_ram #(FP_DATA_BUS_WIDTH) x_ram(.clock(clock),
        .write_enable(x_bus.write_enable),
        .read_addr(x_bus.read_addr),
        .write_addr(x_bus.write_addr),
        .in_data(x_bus.write_data),
        .out_data(x_bus.read_data));
    defparam x_ram.ADDR_WIDTH = REPRESENTATION_ADDR_WIDTH;


    logic[FP_DATA_BUS_WIDTH-1:0]  proc_read_data;
    logic [1:0]proc_read_select = 0;

    vs_mux_3x1 #(FP_DATA_BUS_WIDTH) processor_read_data_mux(proc_read_select,
            residual_bus.read_data, 
            dict_bus.write_data,
            x_bus.read_data,
            proc_read_data
        );


    vs_dict_proc_if dict_proc_bus(clock, reset_n);

    vs_sensing_matrix_processor #(SIGNAL_SIZE_DEFAULT, DICTIONARY_SIZE_DEFAULT, 
        FP_Q_DEFAULT, BATCH_SIZE) dict_processor(
        dict_proc_bus);

    always_comb begin
        residual_bus.read_addr = dict_proc_bus.read_addr;
        dict_proc_bus.read_data = proc_read_data;
        product_bus.write_enable = dict_proc_bus.write_enable;
        product_bus.write_addr = dict_proc_bus.write_addr;
        product_bus.write_data = dict_proc_bus.write_data;
    end


    vs_abs_max_identifier_if max_ident_bus(clock);

    vs_max_identifier #(BATCH_SIZE) max_unit(
        clock, reset_n, 
        product_bus.read_addr, product_bus.read_data,
        max_ident_bus.location, 
        max_ident_bus.value,
        dict_proc_bus.batch_products_transferred,
        max_ident_bus.batch_done
        );


    vs_start_done_bus_if main_loop_bus();

    vs_matching_pursuit_main_loop main_loop(
        clock, reset_n,
        main_loop_bus.processor, 
        x_bus,
        residual_bus, product_bus, dict_proc_bus,
        max_ident_bus.driver);


    vs_start_done_bus_if alg_fsm_bus();

    vs_matching_pursuit_fsm alg_fsm(
        clock, reset_n,
        alg_fsm_bus.processor, 
        main_loop_bus.driver, 
        y_bus.read_write_ports, 
        residual_bus.read_write_ports 
        );

    always_comb begin
        done = alg_fsm_bus.done;
        alg_fsm_bus.start = start;
    end
endmodule


