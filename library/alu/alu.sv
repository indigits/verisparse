`include "definitions.svp"

module ALU(
    input instruction_t IW,
    input logic clock,
    output logic [31:0] result
    );

    always_comb begin
        case (IW.opcode)
            ADD : result = IW.a + IW.b;
            SUB : result = IW.a - IW.b;
            MUL : result = multiplier(IW.a, IW.b);
        endcase
    end

endmodule
