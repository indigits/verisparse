// if addr_width = 10, then we have memory of size 1024*1024.
module square_single_clock_synchronous_ram 
    #(parameter DATA_WIDTH=8,
      parameter ADDR_WIDTH=12)(
      input clock, 
      input write_enable,
      input [(ADDR_WIDTH -1):0] x, y,
      input [(DATA_WIDTH-1):0] in_data, 
      output logic [(DATA_WIDTH-1):0] out_data
      );

    // The RAM variable
    reg [DATA_WIDTH -1:0] ram[2**(2*ADDR_WIDTH) -1:0];
    reg[(ADDR_WIDTH -1):0] x_reg, y_reg;

    always_ff @(posedge clock) begin
        if (write_enable) ram[{x, y}] <= in_data;
        x_reg <= x;
        y_reg <= y;
    end
    // continuous assignment implies
    // READ returns NEW data.
    assign out_data <= ram[{x, y}];
endmodule

