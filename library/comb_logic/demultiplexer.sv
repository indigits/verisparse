
/**
Different kinds of demultiplexers
*/

module vs_demux_1x2#(parameter WIDTH=1) (
    input logic select,
    input logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] d_out_0,
    output logic [WIDTH-1:0]d_out_1
    );
always_comb begin
    if (select) begin
        d_out_0 = 0;
        d_out_1 = d_in;
    end
    else begin
        d_out_0 = d_in;
        d_out_1 = 0;
    end
end
endmodule

module vs_demux_1x3#(parameter WIDTH=1) (
    input logic[1:0] select,
    input logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] d_out_0,
    output logic [WIDTH-1:0]d_out_1,
    output logic [WIDTH-1:0]d_out_2
    );
always_comb begin
    if (select == 0) begin 
        d_out_0 = d_in;
    end
    else begin
        d_out_0 = 0;
    end
    if (select == 1) begin 
        d_out_1 = d_in;
    end
    else begin
        d_out_1 = 0;
    end
    if (select == 2) begin 
        d_out_2 = d_in;
    end
    else begin
        d_out_2 = 0;
    end
end
endmodule


module vs_demux_1x4#(parameter WIDTH=1) (
    input logic[1:0] select,
    input logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] d_out_0,
    output logic [WIDTH-1:0]d_out_1,
    output logic [WIDTH-1:0]d_out_2,
    output logic [WIDTH-1:0]d_out_3
    );
always_comb begin
    if (select == 0) begin 
        d_out_0 = d_in;
    end
    else begin
        d_out_0 = 0;
    end
    if (select == 1) begin 
        d_out_1 = d_in;
    end
    else begin
        d_out_1 = 0;
    end
    if (select == 2) begin 
        d_out_2 = d_in;
    end
    else begin
        d_out_2 = 0;
    end
    if (select == 3) begin 
        d_out_3 = d_in;
    end
    else begin
        d_out_3 = 0;
    end
end
endmodule

