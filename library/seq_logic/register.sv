
module register #(parameter WIDTH = 16) (
    input clock,
    input [WIDTH - 1 : 0] in,
    output logic [WIDTH - 1: 0] out);

    always_ff @(posedge clock) out = in;

endmodule

