`include "definitions.svp"

module test;
    instruction_t test_word;
    logic[31:0] alu_out;
    logic clock = 0;
    ALU dut (.IW (test_word), .result(alu_out), .clock(clock));

    // implement the clock
    always #10 clock = ~clock;

    initial begin
        @(negedge clock)
        test_word.a = 5;
        test_word.b = 7;
        test_word.opcode = ADD;
        @(negedge clock)
        $display("alu_out=%d (expected 12)", alu_out);
        $finish;
    end

endmodule
