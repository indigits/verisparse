module dual_port_single_clock_ram 
    #(parameter DATA_WIDTH=8,
      parameter ADDR_WIDTH=16)(
      input clock, 
      input write_enable_a,
      input write_enable_b,
      input [(ADDR_WIDTH -1):0] addr_a,
      input [(ADDR_WIDTH -1):0] addr_b,
      input [(DATA_WIDTH-1):0] in_a, 
      input [(DATA_WIDTH-1):0] in_b, 
      output logic [(DATA_WIDTH-1):0] out_a,
      output logic [(DATA_WIDTH-1):0] out_b
      );

    // The RAM variable
    reg [DATA_WIDTH -1:0] ram[2**ADDR_WIDTH -1:0];

    // port A
    always_ff @(posedge clock) begin
        if (write_enable_a) 
        begin
          ram[addr_a] <= in_a;
          out_a <= in_a;
        end
        else out_a <= ram[addr_a];
    end

    // port B
    always_ff @(posedge clock) begin
        if (write_enable_b) 
        begin
          ram[addr_b] <= in_b;
          out_b <= in_b;
        end
        else out_b <= ram[addr_b];
    end

endmodule

