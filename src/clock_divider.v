`timescale 1ns / 1ps

module clock_divider #(
    parameter div = 49999999
)(
    input           clk_in,
    output reg      clk_out
);

    reg [25:0] q;

    initial begin
        q       <= 0;
        clk_out = 0;
    end

    always @(posedge clk_in) begin
            if (q == div) begin
                clk_out <= ~clk_out;
                q       <= 0;
            end
            else
                q <= q + 1;
        end

endmodule