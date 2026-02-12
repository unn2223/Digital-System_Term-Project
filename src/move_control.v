`timescale 1ns/1ps

module move_control #(
    parameter integer STEP_SIZE = 4
)(
    input         pixel_clk,
    input         vs,
    input         btn_up,
    input         btn_down,
    input         btn_left,
    input         btn_right,
    output reg [10:0] cx = 320,
    output reg [10:0] cy = 240
);

    reg up_d1, up_d2, dn_d1, dn_d2;
    reg lf_d1, lf_d2, rt_d1, rt_d2;

    always @(posedge pixel_clk) begin
        {up_d2, up_d1} <= {up_d1, btn_up};
        {dn_d2, dn_d1} <= {dn_d1, btn_down};
        {lf_d2, lf_d1} <= {lf_d1, btn_left};
        {rt_d2, rt_d1} <= {rt_d1, btn_right};
    end

    wire up    = up_d2;
    wire down  = dn_d2;
    wire left  = lf_d2;
    wire right = rt_d2;

    reg vs_d;
    wire vs_rise = vs & ~vs_d;
    always @(posedge pixel_clk) vs_d <= vs;

    always @(posedge pixel_clk) begin
        if (vs_rise) begin
            if (up)    cy <= cy - STEP_SIZE;
            if (down)  cy <= cy + STEP_SIZE;
            if (left)  cx <= cx - STEP_SIZE;
            if (right) cx <= cx + STEP_SIZE;
        end
    end

endmodule
