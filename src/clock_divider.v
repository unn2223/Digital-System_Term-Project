`timescale 1ns / 1ps

module clock_divider #(
    parameter [25:0] div = 26'd49999999
)(
    input  wire      clk_in,
    input  wire      rst,
    output reg       clk_out
);

    reg [25:0] q;

    initial begin
        q       <= 26'd0;
        clk_out <= 1'b0;
    end

    always @(posedge clk_in) begin
        if (rst) begin
            q       <= 26'd0;
            clk_out <= 1'b0;
        end else if (q == div) begin
            q       <= 26'd0;
            clk_out <= ~clk_out;
        end else begin
            q <= q + 26'd1;
        end
    end

endmodule
