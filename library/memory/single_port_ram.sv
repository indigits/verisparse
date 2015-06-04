/***
  Read from the RAM happens with one cycle delay.

  Here is how it proceeds.
  - address bits are set.
  - at the next clock edge, they are transferred to addr_reg.
  - after this they are available for reading.
 */
module vs_single_port_ram 
    #(parameter DATA_WIDTH=8,
      parameter ADDR_WIDTH=16)(
      input clock, 
      input write_enable,
      input [(ADDR_WIDTH -1):0] addr,
      input [(DATA_WIDTH-1):0] in_data, 
      output logic [(DATA_WIDTH-1):0] out_data
      );

    // The RAM variable
    reg [DATA_WIDTH -1:0] ram[2**ADDR_WIDTH -1:0];
    reg[(ADDR_WIDTH -1):0] addr_reg;

    always_ff @(posedge clock) begin
        if (write_enable) ram[addr] <= in_data;
        addr_reg <= addr;
    end
    // continuous assignment implies
    // READ returns NEW data.
    // Natural behavior of TriMatrix memory
    // blocks in single port mode
    assign out_data = ram[addr_reg];
endmodule

