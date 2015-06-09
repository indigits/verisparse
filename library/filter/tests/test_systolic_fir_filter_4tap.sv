`include "verisparse.svh"

module test_systolic_fir_filter_4tap;

    logic clock;
    bit resetN = 1;
    fp_32_t x;
    fp_32_t y;

    int clock_count = 0;

    fp_32_t data[99:0] = '{ 100{1} };

    systolic_fir_filter_4tap uut(clock, resetN, x, y);

    initial begin
        x = 0;
        clock = 0;
        resetN = 1;

        // generate reset
        #100 resetN = 0;
        #100 resetN = 1;
    end

    always #50 clock = ~clock;

    always @(posedge clock) begin
        if (resetN == 0) assign x = 0;
        else x = data[clock_count];
        deassign x;
    end

    always @(posedge clock) begin
        clock_count <= clock_count + 1;
        if (clock_count == 50) $stop;
    end

    always @(negedge clock) begin
        //$display("x: %d, y: %d, clock_count: %d", x, y, clock_count);
        if (clock_count < 20) begin
            $display("w0 : %0d, w1: %0d, w2: %0d, w3: %0d, clock: %0d, reset: %b, pe0 state: %s, pe0 clock: %0d",
                uut.pe0.weight, 
                uut.pe1.weight, 
                uut.pe2.weight, 
                uut.pe3.weight,
                clock_count,
                resetN,
                uut.pe0.state.name,
                uut.pe0.clock_count);
        end
    end

endmodule
