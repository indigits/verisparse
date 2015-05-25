/**

This module implements a queue based on shift registers.

The queue has a maximum size and data width.

The number of shift registers is equal to the queue size.

Queue can be empty or nonempty.

On the input side the queue works with
- a data bus from which a new item is read
- an indicator which tell if the data bus is ready with new data.

On the input side, the queue maintains a flag which indicates if 
the queue is full. This is called a back pressure flag. 
If it is 1, then the queue is full and cannot accept new data.
If it is 0, then queue is willing to accept new data.
 

On the output side the queue has
- a data bus through which a new item from the front of the queue is popped.
- an indicator which tells that the queue has presented a new data from front.

On the output side the queue also receives a flag which tells if
the receiver is ready to pop something from queue or not. This is
the output back pressure pin. If the pin is 1, then nothing can be
popped from the queue. If the pin is 0, then the data from queue
can be popped out (if available).

The queue has two states
- EMPTY
- NONEMPTY


When the queue is empty
- Nothing can be popped from queue. out_valid is false.
- If input is valid then one item can be pushed into the queue.
*/

module shift_register_queue #(
    parameter DATA_WIDTH=8, 
    QUEUE_DEPTH=10) 
    (
        input clock,
        input resetN,
        
        // ports for pushing data into the queue
        input [DATA_WIDTH-1:0] in_data, // input data
        input in_valid, // whether input data is valid
        output logic in_back_pressure, // whether queue is ready to accept new data

        // ports for popping data from the queue
        output logic[DATA_WIDTH-1:0] out_data,
        output logic out_valid, 
        input out_back_pressure // whether receiver is ready to accept data
    );
    // calculate the number of bits required to 
    // represent the address of the RAM for 
    // keeping the contents of queue
    parameter ADDR_WIDTH = 
        (  (((QUEUE_DEPTH))         == 0)? 0 
         : (((QUEUE_DEPTH -1) >> 0) == 0)? 0
         : (((QUEUE_DEPTH -1) >> 1) == 0)? 1
         : (((QUEUE_DEPTH -1) >> 2) == 0)? 2
         : (((QUEUE_DEPTH -1) >> 3) == 0)? 3
         : (((QUEUE_DEPTH -1) >> 4) == 0)? 4
         : (((QUEUE_DEPTH -1) >> 5) == 0)? 5
         : (((QUEUE_DEPTH -1) >> 6) == 0)? 6
         : (((QUEUE_DEPTH -1) >> 7) == 0)? 7
         : (((QUEUE_DEPTH -1) >> 8) == 0)? 8
         : (((QUEUE_DEPTH -1) >> 9) == 0)? 9
         :                                 16);

    // Space for keeping contents of the queue
    reg [DATA_WIDTH -1:0] ram[QUEUE_DEPTH -1:0];

    typedef enum {EMPTY, NONEMPTY} queue_states_t;

    // address of the front of the queue
    reg [ADDR_WIDTH-1:0] queue_front_addr, next_queue_front_addr;

    // current state of the queue. next state of the queue.
    queue_states_t state, next_state;

    // indicates if queue is full or not
    wire queue_full;
    // indicates if queue front address is 0 (0 or 1 element in queue)
    wire addr_is_zero;
    // indicates if shift registers need to transfer or not
    bit shift_enable = 0;

    assign queue_full = (queue_front_addr == QUEUE_DEPTH - 1);
    assign addr_is_zero = (queue_front_addr == 0);
    // output is valid if queue is non-empty
    assign out_valid = (state == EMPTY)? 0 : 1;
    // read data from the front of the queue.
    assign out_data = ram[queue_front_addr];
    // indicate to input that queue can't accept more data
    assign in_back_pressure = queue_full;

    always_ff @(posedge clock or negedge resetN) begin
        if (!resetN) begin
            state <= EMPTY;
            queue_front_addr <= 0;
            shift_enable <= 0;
        end
        else begin
            // update state and next address
            state <= next_state;
            queue_front_addr <= next_queue_front_addr;
        end
    end


    // carry out shift register logic
    always_ff @(posedge clock) begin
        if (shift_enable) begin
            for (int a=QUEUE_DEPTH-1; a > 0; a = a - 1) begin
                ram[a] <= ram[a-1];
            end
            // read new data into the first register
            ram[0] <= in_data;
        end
    end

    // combinational finite state machine
    always_comb begin
        case (state) 
            EMPTY : begin : empty_states
                if (in_valid) begin
                    // new data can be put inside queue
                    shift_enable <= 1;
                    next_queue_front_addr <= 0;
                    next_state <= NONEMPTY;
                end
                else begin
                    // queue is empty and no data pending
                    shift_enable <= 0;
                    next_queue_front_addr <= 0;
                    next_state <= EMPTY;
                end
            end : empty_states
            NONEMPTY: begin: non_empty_state
                if (queue_full) begin
                    if (out_back_pressure) begin
                        // we cannot pop out anything yet.
                        shift_enable <= 0;
                        next_queue_front_addr <= queue_front_addr;
                        next_state <= NONEMPTY;
                    end
                    else begin
                        // one item from queue being read out
                        shift_enable <= 0;
                        next_queue_front_addr <= queue_front_addr -1;
                        next_state <= NONEMPTY;
                    end
                end
                else begin
                    if (in_valid && out_back_pressure) begin
                        // we can push one item but can't pop anything
                        shift_enable <= 1;
                        next_queue_front_addr <= queue_front_addr + 1;
                        next_state <= NONEMPTY;
                    end
                    else if (in_valid && ! out_back_pressure) begin
                        // we can push one and pop one
                        shift_enable <= 1;
                        next_queue_front_addr <= queue_front_addr;
                        next_state <= NONEMPTY;
                    end
                    else if (!in_valid && out_back_pressure) begin
                        // idle no push no pop
                        shift_enable <= 0;
                        next_queue_front_addr <= queue_front_addr;
                        next_state <= NONEMPTY;
                    end
                    else if (!in_valid && !out_back_pressure) begin
                        // no push, one pop
                        shift_enable <= 0;
                        next_queue_front_addr <= addr_is_zero ? 0 : queue_front_addr - 1;
                        next_state <= addr_is_zero ? EMPTY : NONEMPTY;
                    end
                end
            end: non_empty_state
        endcase
    end


endmodule