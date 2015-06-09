`include "verisparse.svh"

/**
Interface for single clock synchronous ram.
*/
interface vs_sync_ram_bus_if#(
    parameter DATA_WIDTH=8,
    parameter ADDR_WIDTH=FP_DATA_BUS_WIDTH)(
    input logic clock);

    logic [(DATA_WIDTH-1):0] read_addr;
    logic[ADDR_WIDTH-1:0]  read_data;

    logic write_enable;
    logic [(DATA_WIDTH-1):0] write_addr;
    logic[ADDR_WIDTH-1:0]  write_data;

    modport ram_ports(
        input write_enable,
        input read_addr,
        input write_addr,
        input write_data,
        output read_data
    );

    modport reader_ports(
        output read_addr,
        input read_data
        );

    modport writer_ports(
        output write_enable,
        output write_addr,
        output write_data
        );

    modport read_write_ports(
        output read_addr,
        input read_data,
        output write_enable,
        output write_addr,
        output write_data
        );
endinterface



/**

 
The synchronous read works as follows:
- Set the read address before the clock edge
- At the clock edge the data is transferred from RAM
  to out_data.
- After the clock (or at next clock edge), it can be read. 


*/

module vs_single_clock_synchronous_ram 
    #(parameter DATA_WIDTH=8,
      parameter ADDR_WIDTH=16)(
      input clock, 
      input write_enable,
      input [(ADDR_WIDTH -1):0] write_addr,
      input [(ADDR_WIDTH -1):0] read_addr,
      input [(DATA_WIDTH-1):0] in_data, 
      output logic [(DATA_WIDTH-1):0] out_data
      );

    // The RAM variable
    reg [DATA_WIDTH -1:0] ram[2**ADDR_WIDTH -1:0];

    always_ff @(posedge clock) begin
        if (write_enable) ram[write_addr] <= in_data;
        // If read_addr == write_addr, we return old data        
        out_data <= ram[read_addr];
    end
endmodule

