`timescale 1ns/1ps

module move_control #(
    parameter [10:0] STEP_SIZE = 11'd4,
    parameter [10:0] START_X   = 11'd320,
    parameter [10:0] START_Y   = 11'd240,
    parameter [10:0] MIN_X     = 11'd30,
    parameter [10:0] MAX_X     = 11'd610,
    parameter [10:0] MIN_Y     = 11'd30,
    parameter [10:0] MAX_Y     = 11'd450
)(
    input  wire       pixel_clk,
    input  wire       rst,
    input  wire       vs,
    input  wire       btn_up,
    input  wire       btn_down,
    input  wire       btn_left,
    input  wire       btn_right,
    output reg [10:0] cx,
    output reg [10:0] cy
);

    initial begin
        cx <= START_X;
        cy <= START_Y;
    end

    // 2-FF sync for buttons
    reg up_d1, up_d2;
    reg dn_d1, dn_d2;
    reg lf_d1, lf_d2;
    reg rt_d1, rt_d2;

    always @(posedge pixel_clk) begin
        up_d1 <= btn_up;    up_d2 <= up_d1;
        dn_d1 <= btn_down;  dn_d2 <= dn_d1;
        lf_d1 <= btn_left;  lf_d2 <= lf_d1;
        rt_d1 <= btn_right; rt_d2 <= rt_d1;
    end

    wire up    = up_d2;
    wire down  = dn_d2;
    wire left  = lf_d2;
    wire right = rt_d2;

    // frame tick from vs rising edge
    reg vs_d;
    always @(posedge pixel_clk) begin
        if (rst) vs_d <= 1'b1;
        else     vs_d <= vs;
    end
    wire vs_rise = vs & ~vs_d;

    // movement (frame-based) + saturation to MIN/MAX
    always @(posedge pixel_clk) begin
        if (rst) begin
            cx <= START_X;
            cy <= START_Y;
        end else if (vs_rise) begin
            // Y
            if (up) begin
                if (cy >= (MIN_Y + STEP_SIZE)) cy <= cy - STEP_SIZE;
                else                           cy <= MIN_Y;
            end
            if (down) begin
                if ((cy + STEP_SIZE) <= MAX_Y) cy <= cy + STEP_SIZE;
                else                           cy <= MAX_Y;
            end

            // X
            if (left) begin
                if (cx >= (MIN_X + STEP_SIZE)) cx <= cx - STEP_SIZE;
                else                           cx <= MIN_X;
            end
            if (right) begin
                if ((cx + STEP_SIZE) <= MAX_X) cx <= cx + STEP_SIZE;
                else                           cx <= MAX_X;
            end
        end
    end

endmodule
