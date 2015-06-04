`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;

module test_single_port_ram;

    logic clock;
    logic write_enable;
    logic [15:0] addr;
    logic [7:0] in_data; 
    logic [7:0] out_data;

    vs_single_port_ram uut(clock, write_enable, addr, in_data, out_data);

    initial begin
        // a fixed number of clock cycles
        repeat (200) #50 clock = ~clock;
    end

    task automatic write_ram_contents(int num_bytes);
        addr = 0;
        write_enable = 1;
        in_data = 0;
        repeat (num_bytes) @(posedge clock) begin
            in_data <= in_data + 1;
            addr <= addr + 1;
            $display("Writing: address: %04x, data: %04x", addr, in_data);
        end
        write_enable = 0;
        @(posedge clock);
    endtask

    task automatic print_ram_contents(int num_bytes);
        `TEST_SET_START
        $display("Reading contents of RAM via data bus: ");
        addr = 0;
        repeat (num_bytes+1) @(posedge clock) begin
            //$display("address: %04x, data: %04x", addr, out_data);
            if (addr != 0) begin
                `TEST_SET_EQUAL(out_data, addr - 1);
            end
            addr <= addr + 1;
        end
        `TEST_SET_SUMMARIZE("RAM_contents_data_bus")
    endtask

    task automatic print_ram_contents_direct(int num_bytes);
        `TEST_SET_START
        $display("Printing contents of RAM directly: ");
        for (int i=0; i < num_bytes; ++i) begin
            //$display("address: %04x, data: %04x", i, uut.ram[i]);
            `TEST_SET_EQUAL(i, uut.ram[i]);
        end
        `TEST_SET_SUMMARIZE("print_ram_contents_direct")
    endtask

    task automatic read_single_byte(input logic [15:0] address);
        $display("Reading single byte:");
        @(posedge clock)  begin
            // at the next clock edge, the addr bits will be set
            addr <= address;
        end
        @(posedge clock) begin
            // addr bits have been set. After the clock edge, 
            // they will be transferred to the RAM's read register.
        end
        @(posedge clock) begin
            // We are now ready to read the contents.
            //$display("address: %04x, data: %04x", address, out_data);
            `TEST_EQUAL("read_single_byte_delay", address, out_data);
        end
    endtask

    task automatic read_single_byte_delay(input logic [15:0] address);
        $display("Reading single byte via delay:");
        addr = address;
        @(posedge clock);
        #10;
        `TEST_EQUAL("read_single_byte_delay", address, out_data);
        //$display("address: %04x, data: %04x", address, out_data);
    endtask

    initial begin
        int counter = 0;
        clock=1;
        addr = 0;
        write_ram_contents(10);
        print_ram_contents(10);
        print_ram_contents_direct(10);
        read_single_byte(5);
        read_single_byte_delay(3);
    end

    always @(posedge clock) begin
        // read the data on the bus
        //$display("time: %05d, address: %04x, data: %04x", $time, addr, out_data);
    end

endmodule
