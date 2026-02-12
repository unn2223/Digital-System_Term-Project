`timescale 1ns / 1ps

module vga_controller_640_480(
    input            pixel_clk,
    input            rst,
    output reg       hs,
    output reg       vs,
    output reg [10:0] hcount,
    output reg [10:0] vcount,
    output reg       blank
);

    localparam HMAX   = 800;
    localparam HLINES = 640;
    localparam HFP    = 648;
    localparam HSP    = 744;

    localparam VMAX   = 525;
    localparam VLINES = 480;
    localparam VFP    = 482;
    localparam VSP    = 484;

    always @(posedge pixel_clk) begin: h_count
        if (rst || (hcount == HMAX))
            hcount <= 0;
        else
            hcount <= hcount + 1;
    end

    always @(posedge pixel_clk) begin
        if (rst)
            hs <= 1'b1;
        else
            hs <= (hcount >= HFP && hcount < HSP) ? 1'b0 : 1'b1;
    end

    always @(posedge pixel_clk) begin: v_count
        if (rst)
            vcount <= 0;
        else if (hcount == HMAX) begin
            if (vcount == VMAX)
                vcount <= 0;
            else
                vcount <= vcount + 1;
        end
    end

    always @(posedge pixel_clk) begin
        if (rst)
            vs <= 1'b1;
        else if (hcount == HMAX - 1)
            vs <= (vcount >= VFP && vcount < VSP) ? 1'b0 : 1'b1;
    end

    always @(posedge pixel_clk) begin
        blank <= ((hcount < HLINES) && (vcount < VLINES)) ? 1'b0 : 1'b1;
    end

endmodule