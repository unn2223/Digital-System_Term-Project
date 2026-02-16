`timescale 1ns / 1ps

module vga_controller_640_480(
    input  wire        pixel_clk,
    input  wire        rst,
    output reg         hs,
    output reg         vs,
    output reg  [10:0] hcount,
    output reg  [10:0] vcount,
    output reg         blank
);

    // Keep your original timing numbers (only fix counter wrap points)
    localparam [10:0] HMAX   = 11'd800;
    localparam [10:0] HLINES = 11'd640;
    localparam [10:0] HFP    = 11'd648;
    localparam [10:0] HSP    = 11'd744;

    localparam [10:0] VMAX   = 11'd525;
    localparam [10:0] VLINES = 11'd480;
    localparam [10:0] VFP    = 11'd482;
    localparam [10:0] VSP    = 11'd484;

    localparam [10:0] HLAST = HMAX - 11'd1;
    localparam [10:0] VLAST = VMAX - 11'd1;

    // Horizontal counter: 0 .. HMAX-1
    always @(posedge pixel_clk) begin
        if (rst) begin
            hcount <= 11'd0;
        end else if (hcount == HLAST) begin
            hcount <= 11'd0;
        end else begin
            hcount <= hcount + 11'd1;
        end
    end

    // HS (active low)
    always @(posedge pixel_clk) begin
        if (rst) hs <= 1'b1;
        else     hs <= (hcount >= HFP && hcount < HSP) ? 1'b0 : 1'b1;
    end

    // Vertical counter increments at end of each line
    always @(posedge pixel_clk) begin
        if (rst) begin
            vcount <= 11'd0;
        end else if (hcount == HLAST) begin
            if (vcount == VLAST) vcount <= 11'd0;
            else                 vcount <= vcount + 11'd1;
        end
    end

    // VS (active low) - update once per line at end-of-line
    always @(posedge pixel_clk) begin
        if (rst) begin
            vs <= 1'b1;
        end else if (hcount == HLAST) begin
            vs <= (vcount >= VFP && vcount < VSP) ? 1'b0 : 1'b1;
        end
    end

    // blank: 0 in visible area, 1 outside
    always @(posedge pixel_clk) begin
        blank <= ((hcount < HLINES) && (vcount < VLINES)) ? 1'b0 : 1'b1;
    end

endmodule
