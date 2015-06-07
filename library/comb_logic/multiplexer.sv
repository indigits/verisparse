
/**
Different kinds of multiplexers
*/

module vs_mux_2x1#(parameter WIDTH=1) (
    input logic select,
    input logic [WIDTH-1:0] d_in_0,
    input logic [WIDTH-1:0]d_in_1,
    output logic [WIDTH-1:0] d_out
    );
always_comb begin
    case(select) 
        0: d_out = d_in_0;
        1: d_out = d_in_1;
    endcase
end
endmodule

module vs_mux_4x1#(parameter WIDTH=1) (
    input logic [1:0]select,
    input logic [WIDTH-1:0] d_in_0,
    input logic [WIDTH-1:0] d_in_1,
    input logic [WIDTH-1:0] d_in_2,
    input logic [WIDTH-1:0] d_in_3,
    output logic [WIDTH-1:0] d_out
    );
always_comb begin
    case(select) 
        'b00: d_out = d_in_0;
        'b01: d_out = d_in_1;
        'b10: d_out = d_in_2;
        'b11: d_out = d_in_3;
    endcase
end
endmodule


