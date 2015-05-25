`include "verisparse.svp"


module matching_pursuit_main_loop(input clock,
    input resetN,
    input start,
    output logic done);

    typedef enum{IDLE, SWEEP, UPDATE_SUPPORT, 
    UPDATE_SOLUTION, UPDATE_RESIDUAL} states_t;
    const int cycles = 2;
    int unsigned dummy_counter;
    states_t state = IDLE;

    always_ff @(posedge clock) begin
        if (!resetN) begin
            done <= 0;
            dummy_counter <= cycles;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SWEEP;
                        dummy_counter <= cycles;
                    end
                    done <= 0;
                end
                SWEEP : begin
                    if (dummy_counter == 0) begin
                        // The loop has been processed
                        state <= UPDATE_SUPPORT;
                        dummy_counter <= cycles;
                    end
                    else begin
                        // do some work
                        dummy_counter <= dummy_counter -1;
                        // remain in the state
                        state <= SWEEP;
                    end
                end
                UPDATE_SUPPORT : begin
                    if (dummy_counter == 0) begin
                        // The loop has been processed
                        state <= UPDATE_SOLUTION;
                        dummy_counter <= cycles;
                    end
                    else begin
                        // do some work
                        dummy_counter <= dummy_counter -1;
                        // remain in the state
                        state <= UPDATE_SUPPORT;
                    end
                end
                UPDATE_SOLUTION : begin
                    if (dummy_counter == 0) begin
                        // The loop has been processed
                        state <= UPDATE_RESIDUAL;
                        dummy_counter <= cycles;
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
                        done <= 1;
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


module matching_pursuit_processor (input clock,
        input resetN,
        input start,
        output logic done);
    parameter M = SIGNAL_SIZE_DEFAULT;
    parameter N = DICTIONARY_SIZE_DEFAULT;
    parameter K = SPARSITY_LEVEL_DEFAULT;

    typedef enum {IDLE, 
    READY,  // the processor is ready to start iteration
    WORKING // the processor is executing next iteration
    } states_t;

    int unsigned k_counter;
    logic loop_start;
    logic loop_done;
    states_t state = IDLE;

    // y = Phi * x
    fp_32_t x[N];
    fp_32_t y[M];
    fp_32_t Phi[M][N];

    matching_pursuit_main_loop main_loop(clock, resetN, loop_start, loop_done);

    always_ff @(posedge clock) begin
        if (!resetN) begin
            done <= 0;
            k_counter <= K;
            loop_start <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= READY;
                        k_counter <= K;
                    end
                    done <= 0;
                end
                READY : begin
                    if (k_counter == 0) begin
                        // The loop has been processed
                        state <= IDLE;
                        loop_start <= 0;
                        done <= 1;
                    end
                    else begin
                        // indicate the main loop module to start working
                        loop_start <= 1;
                        // move to working state
                        state <= WORKING;
                    end
                end
                WORKING : begin
                    // unset the loop start flag
                    if (loop_start ) loop_start <= 0;
                    if (loop_done == 0) begin
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
        input resetN);

    bit start = 0;
    wire done;

    pursuit_bus_t bus;

    matching_pursuit_processor processor(clock, resetN, start, done);
    single_clock_synchronous_ram dict_ram(.clock(clock),
        .write_enable(bus.dict.write_enable),
        .read_addr(bus.dict.read_addr),
        .write_addr(bus.dict.write_addr),
        .in_data(bus.dict.read_data),
        .out_data(bus.dict.write_data));
    single_clock_synchronous_ram y_ram(.clock(clock),
        .write_enable(bus.y.write_enable),
        .read_addr(bus.y.read_addr),
        .write_addr(bus.y.write_addr),
        .in_data(bus.y.read_data),
        .out_data(bus.y.write_data));
    single_clock_synchronous_ram x_ram(.clock(clock),
        .write_enable(bus.x.write_enable),
        .read_addr(bus.x.read_addr),
        .write_addr(bus.x.write_addr),
        .in_data(bus.x.read_data),
        .out_data(bus.x.write_data));
    defparam dict_ram.ADDR_WIDTH = DICTIONARY_ADDR_WIDTH;
    defparam y_ram.ADDR_WIDTH = SIGNAL_ADDR_WIDTH;
    defparam x_ram.ADDR_WIDTH = REPRESENTATION_ADDR_WIDTH;

endmodule


