

module vs_up_counter#(parameter N=8) (
    input logic clock,
    input logic reset_n,
    output logic [(N-1):0] out
    );
    always_ff@(posedge clock) begin
        if (~reset_n) begin
            out <= 0;
        end
        else begin
            out <= out + 1;
        end
    end
endmodule


module vs_up_down_counter #(parameter N=8) (
    input logic clock,
    input logic up,
    input logic reset_n,
    output logic [(N-1):0] out
    );

    always_ff@(posedge clock) begin
        if (~reset_n) begin
            out <= 0;
        end
        else if (up) begin
            out <= out + 1;
        end else begin
            out <= out - 1;
        end
    end

endmodule

