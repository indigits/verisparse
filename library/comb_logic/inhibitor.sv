// out = in whenever enable_l is low
module inhibitor(output out, input in, input enable_l);
    wire enable_h;
    not Q1( enable_h, enable_l);
    and Q2(out, in , enable_h);
endmodule
