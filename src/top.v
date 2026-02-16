`timescale 1ns / 1ps

module pacman_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        btn_up,
    input  wire        btn_down,
    input  wire        btn_left,
    input  wire        btn_right,
    output wire        hs,
    output wire        vs,
    output reg  [11:0] rgb
);

    // -----------------------------
    // constants
    // -----------------------------
    localparam BALL_RADIUS    = 10;
    localparam PELLET_RADIUS  = 4;
    localparam ENEMY_RADIUS   = 10;
    localparam WALL_THICKNESS = 20;
    localparam SCREEN_W       = 640;
    localparam SCREEN_H       = 480;

    // -----------------------------
    // 100MHz -> 25MHz
    // -----------------------------
    wire pixel_clk;
    clock_divider #(1) clkdiv (
        .clk_in  (clk),
        .rst     (rst),
        .clk_out (pixel_clk)
    );

    // -----------------------------
    // VGA controller
    // -----------------------------
    wire [10:0] hcount, vcount;
    wire        blank;

    vga_controller_640_480 vga_ctrl (
        .pixel_clk (pixel_clk),
        .rst       (rst),
        .hs        (hs),
        .vs        (vs),
        .hcount    (hcount),
        .vcount    (vcount),
        .blank     (blank)
    );

    // -----------------------------
    // frame tick (vs rising edge)
    // -----------------------------
    reg vs_d;
    always @(posedge pixel_clk) begin
        if (rst) vs_d <= 1'b1;
        else     vs_d <= vs;
    end
    wire vs_rise = vs & ~vs_d;

    // -----------------------------
    // move_control
    // -----------------------------
    wire [10:0] mover_cx, mover_cy;

    // 충돌 리셋 펄스
    wire game_reset;

    move_control #(4) mover (
        .pixel_clk (pixel_clk),
        .rst       (game_reset),
        .vs        (vs),
        .btn_up    (btn_up),
        .btn_down  (btn_down),
        .btn_left  (btn_left),
        .btn_right (btn_right),
        .cx        (mover_cx),
        .cy        (mover_cy)
    );

    // -----------------------------
    // pacman state
    // -----------------------------
    reg [10:0] cx = 320, cy = 240;
    reg        pacman_reset = 1'b0;

    // -----------------------------
    // pellet map: 15x11 -> 165bits
    // idx = y*15 + x
    // -----------------------------
    reg [164:0] pellet_bits;
    initial pellet_bits = {165{1'b1}};

    // -----------------------------
    // enemies
    // -----------------------------
    reg [10:0] ex0  =  40, ey0  =  80;  reg dir0_h  = 1'b1;
    reg [10:0] ex1  = 120, ey1  = 120;  reg dir1_h  = 1'b0;
    reg [10:0] ex2  = 200, ey2  = 160;  reg dir2_h  = 1'b1;
    reg [10:0] ex3  = 280, ey3  = 200;  reg dir3_h  = 1'b0;
    reg [10:0] ex4  = 360, ey4  = 240;  reg dir4_h  = 1'b1;
    reg [10:0] ex5  =  80, ey5  = 280;  reg dir5_h  = 1'b0;
    reg [10:0] ex6  = 160, ey6  = 320;  reg dir6_h  = 1'b1;
    reg [10:0] ex7  = 240, ey7  = 360;  reg dir7_h  = 1'b0;
    reg [10:0] ex8  = 320, ey8  = 400;  reg dir8_h  = 1'b1;
    reg [10:0] ex9  = 400, ey9  = 440;  reg dir9_h  = 1'b0;

    reg [10:0] ex10 =  60, ey10 =  60;  reg dir10_v = 1'b1;
    reg [10:0] ex11 = 140, ey11 = 140;  reg dir11_v = 1'b0;
    reg [10:0] ex12 = 220, ey12 = 220;  reg dir12_v = 1'b1;
    reg [10:0] ex13 = 300, ey13 = 300;  reg dir13_v = 1'b0;
    reg [10:0] ex14 = 380, ey14 = 380;  reg dir14_v = 1'b1;
    reg [10:0] ex15 =  60, ey15 = 440;  reg dir15_v = 1'b0;
    reg [10:0] ex16 = 220, ey16 =  60;  reg dir16_v = 1'b1;
    reg [10:0] ex17 = 380, ey17 = 140;  reg dir17_v = 1'b0;
    reg [10:0] ex18 =  60, ey18 = 220;  reg dir18_v = 1'b1;
    reg [10:0] ex19 = 140, ey19 = 300;  reg dir19_v = 1'b0;

    // -----------------------------
    // collision check
    // -----------------------------
    reg  [4:0]  check_idx = 0;
    reg  [10:0] target_ex, target_ey;
    reg         collide_latch = 1'b0;

    always @(*) begin
        case (check_idx)
            5'd0:  begin target_ex = ex0;  target_ey = ey0;  end
            5'd1:  begin target_ex = ex1;  target_ey = ey1;  end
            5'd2:  begin target_ex = ex2;  target_ey = ey2;  end
            5'd3:  begin target_ex = ex3;  target_ey = ey3;  end
            5'd4:  begin target_ex = ex4;  target_ey = ey4;  end
            5'd5:  begin target_ex = ex5;  target_ey = ey5;  end
            5'd6:  begin target_ex = ex6;  target_ey = ey6;  end
            5'd7:  begin target_ex = ex7;  target_ey = ey7;  end
            5'd8:  begin target_ex = ex8;  target_ey = ey8;  end
            5'd9:  begin target_ex = ex9;  target_ey = ey9;  end
            5'd10: begin target_ex = ex10; target_ey = ey10; end
            5'd11: begin target_ex = ex11; target_ey = ey11; end
            5'd12: begin target_ex = ex12; target_ey = ey12; end
            5'd13: begin target_ex = ex13; target_ey = ey13; end
            5'd14: begin target_ex = ex14; target_ey = ey14; end
            5'd15: begin target_ex = ex15; target_ey = ey15; end
            5'd16: begin target_ex = ex16; target_ey = ey16; end
            5'd17: begin target_ex = ex17; target_ey = ey17; end
            5'd18: begin target_ex = ex18; target_ey = ey18; end
            5'd19: begin target_ex = ex19; target_ey = ey19; end
            default: begin target_ex = ex0; target_ey = ey0; end
        endcase
    end

    wire [10:0] t_dx = (cx > target_ex) ? (cx - target_ex) : (target_ex - cx);
    wire [10:0] t_dy = (cy > target_ey) ? (cy - target_ey) : (target_ey - cy);
    wire [21:0] t_dist_sq = (t_dx * t_dx) + (t_dy * t_dy);

    wire [21:0] hit_enemy_sq = (BALL_RADIUS + ENEMY_RADIUS) * (BALL_RADIUS + ENEMY_RADIUS);
    wire        current_hit  = (t_dist_sq < hit_enemy_sq);

    always @(posedge pixel_clk) begin
        if (rst) begin
            check_idx     <= 0;
            collide_latch <= 1'b0;
        end else begin
            check_idx <= (check_idx == 5'd19) ? 5'd0 : (check_idx + 5'd1);

            if (vs_rise) begin
                collide_latch <= 1'b0;
            end else if (current_hit) begin
                collide_latch <= 1'b1;
            end
        end
    end

    // collide pulse
    reg collide_d = 1'b0;
    always @(posedge pixel_clk) begin
        if (rst) collide_d <= 1'b0;
        else     collide_d <= collide_latch;
    end
    wire collide_pulse = collide_latch & ~collide_d;

    assign game_reset = rst | collide_pulse;

    // -----------------------------
    // pellet eat logic
    // -----------------------------
    wire [10:0] pm_rel_x = (cx >= WALL_THICKNESS) ? (cx - WALL_THICKNESS) : 11'd0;
    wire [10:0] pm_rel_y = (cy >= WALL_THICKNESS) ? (cy - WALL_THICKNESS) : 11'd0;

    wire [3:0] pm_grid_x = pm_rel_x / 40;  // 0..14
    wire [3:0] pm_grid_y = pm_rel_y / 40;  // 0..10

    wire [7:0] pm_idx = (pm_grid_y * 8'd15) + pm_grid_x;

    wire [10:0] pellet_cx = 11'd40 + (pm_grid_x * 11'd40);
    wire [10:0] pellet_cy = 11'd40 + (pm_grid_y * 11'd40);

    wire [10:0] pm_dx = (cx > pellet_cx) ? (cx - pellet_cx) : (pellet_cx - cx);
    wire [10:0] pm_dy = (cy > pellet_cy) ? (cy - pellet_cy) : (pellet_cy - cy);
    wire [21:0] pm_dist_sq = (pm_dx * pm_dx) + (pm_dy * pm_dy);

    wire [21:0] eat_sq = (BALL_RADIUS + PELLET_RADIUS) * (BALL_RADIUS + PELLET_RADIUS);

    wire eat_signal =
        (pm_grid_x < 4'd15) && (pm_grid_y < 4'd11) &&
        (pellet_bits[pm_idx] == 1'b1) &&
        (pm_dist_sq < eat_sq);

    // -----------------------------
    // main update (frame-based)
    // -----------------------------
    always @(posedge pixel_clk) begin
        if (game_reset) begin
            pellet_bits   <= {165{1'b1}};
            cx            <= 320;
            cy            <= 240;
            pacman_reset  <= 1'b1;

            // 적 초기화
            ex0  <=  40;  ey0  <=  80;  dir0_h  <= 1'b1;
            ex1  <= 120;  ey1  <= 120;  dir1_h  <= 1'b0;
            ex2  <= 200;  ey2  <= 160;  dir2_h  <= 1'b1;
            ex3  <= 280;  ey3  <= 200;  dir3_h  <= 1'b0;
            ex4  <= 360;  ey4  <= 240;  dir4_h  <= 1'b1;
            ex5  <=  80;  ey5  <= 280;  dir5_h  <= 1'b0;
            ex6  <= 160;  ey6  <= 320;  dir6_h  <= 1'b1;
            ex7  <= 240;  ey7  <= 360;  dir7_h  <= 1'b0;
            ex8  <= 320;  ey8  <= 400;  dir8_h  <= 1'b1;
            ex9  <= 400;  ey9  <= 440;  dir9_h  <= 1'b0;

            ex10 <=  60;  ey10 <=  60;  dir10_v <= 1'b1;
            ex11 <= 140;  ey11 <= 140;  dir11_v <= 1'b0;
            ex12 <= 220;  ey12 <= 220;  dir12_v <= 1'b1;
            ex13 <= 300;  ey13 <= 300;  dir13_v <= 1'b0;
            ex14 <= 380;  ey14 <= 380;  dir14_v <= 1'b1;
            ex15 <=  60;  ey15 <= 440;  dir15_v <= 1'b0;
            ex16 <= 220;  ey16 <=  60;  dir16_v <= 1'b1;
            ex17 <= 380;  ey17 <= 140;  dir17_v <= 1'b0;
            ex18 <=  60;  ey18 <= 220;  dir18_v <= 1'b1;
            ex19 <= 140;  ey19 <= 300;  dir19_v <= 1'b0;

        end else if (vs_rise) begin
            // pellet update
            if (eat_signal) pellet_bits[pm_idx] <= 1'b0;

            // pacman update
            if (pacman_reset) begin
                cx <= 320;
                cy <= 240;
                if (btn_up || btn_down || btn_left || btn_right)
                    pacman_reset <= 1'b0;
            end else begin
                cx <= mover_cx;
                cy <= mover_cy;
            end

            // enemy move
            if (dir0_h)  begin if (ex0  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex0  <= ex0  + 2; else begin ex0  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir0_h  <= 1'b0; end end
            else         begin if (ex0  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex0  <= ex0  - 2; else begin ex0  <= WALL_THICKNESS + ENEMY_RADIUS;           dir0_h  <= 1'b1; end end

            if (dir1_h)  begin if (ex1  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex1  <= ex1  + 2; else begin ex1  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir1_h  <= 1'b0; end end
            else         begin if (ex1  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex1  <= ex1  - 2; else begin ex1  <= WALL_THICKNESS + ENEMY_RADIUS;           dir1_h  <= 1'b1; end end

            if (dir2_h)  begin if (ex2  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex2  <= ex2  + 2; else begin ex2  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir2_h  <= 1'b0; end end
            else         begin if (ex2  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex2  <= ex2  - 2; else begin ex2  <= WALL_THICKNESS + ENEMY_RADIUS;           dir2_h  <= 1'b1; end end

            if (dir3_h)  begin if (ex3  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex3  <= ex3  + 2; else begin ex3  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir3_h  <= 1'b0; end end
            else         begin if (ex3  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex3  <= ex3  - 2; else begin ex3  <= WALL_THICKNESS + ENEMY_RADIUS;           dir3_h  <= 1'b1; end end

            if (dir4_h)  begin if (ex4  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex4  <= ex4  + 2; else begin ex4  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir4_h  <= 1'b0; end end
            else         begin if (ex4  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex4  <= ex4  - 2; else begin ex4  <= WALL_THICKNESS + ENEMY_RADIUS;           dir4_h  <= 1'b1; end end

            if (dir5_h)  begin if (ex5  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex5  <= ex5  + 2; else begin ex5  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir5_h  <= 1'b0; end end
            else         begin if (ex5  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex5  <= ex5  - 2; else begin ex5  <= WALL_THICKNESS + ENEMY_RADIUS;           dir5_h  <= 1'b1; end end

            if (dir6_h)  begin if (ex6  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex6  <= ex6  + 2; else begin ex6  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir6_h  <= 1'b0; end end
            else         begin if (ex6  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex6  <= ex6  - 2; else begin ex6  <= WALL_THICKNESS + ENEMY_RADIUS;           dir6_h  <= 1'b1; end end

            if (dir7_h)  begin if (ex7  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex7  <= ex7  + 2; else begin ex7  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir7_h  <= 1'b0; end end
            else         begin if (ex7  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex7  <= ex7  - 2; else begin ex7  <= WALL_THICKNESS + ENEMY_RADIUS;           dir7_h  <= 1'b1; end end

            if (dir8_h)  begin if (ex8  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex8  <= ex8  + 2; else begin ex8  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir8_h  <= 1'b0; end end
            else         begin if (ex8  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex8  <= ex8  - 2; else begin ex8  <= WALL_THICKNESS + ENEMY_RADIUS;           dir8_h  <= 1'b1; end end

            if (dir9_h)  begin if (ex9  + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex9  <= ex9  + 2; else begin ex9  <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir9_h  <= 1'b0; end end
            else         begin if (ex9  >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ex9  <= ex9  - 2; else begin ex9  <= WALL_THICKNESS + ENEMY_RADIUS;           dir9_h  <= 1'b1; end end

            if (dir10_v) begin if (ey10 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey10 <= ey10 + 2; else begin ey10 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir10_v <= 1'b0; end end
            else         begin if (ey10 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey10 <= ey10 - 2; else begin ey10 <= WALL_THICKNESS + ENEMY_RADIUS;           dir10_v <= 1'b1; end end

            if (dir11_v) begin if (ey11 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey11 <= ey11 + 2; else begin ey11 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir11_v <= 1'b0; end end
            else         begin if (ey11 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey11 <= ey11 - 2; else begin ey11 <= WALL_THICKNESS + ENEMY_RADIUS;           dir11_v <= 1'b1; end end

            if (dir12_v) begin if (ey12 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey12 <= ey12 + 2; else begin ey12 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir12_v <= 1'b0; end end
            else         begin if (ey12 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey12 <= ey12 - 2; else begin ey12 <= WALL_THICKNESS + ENEMY_RADIUS;           dir12_v <= 1'b1; end end

            if (dir13_v) begin if (ey13 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey13 <= ey13 + 2; else begin ey13 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir13_v <= 1'b0; end end
            else         begin if (ey13 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey13 <= ey13 - 2; else begin ey13 <= WALL_THICKNESS + ENEMY_RADIUS;           dir13_v <= 1'b1; end end

            if (dir14_v) begin if (ey14 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey14 <= ey14 + 2; else begin ey14 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir14_v <= 1'b0; end end
            else         begin if (ey14 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey14 <= ey14 - 2; else begin ey14 <= WALL_THICKNESS + ENEMY_RADIUS;           dir14_v <= 1'b1; end end

            if (dir15_v) begin if (ey15 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey15 <= ey15 + 2; else begin ey15 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir15_v <= 1'b0; end end
            else         begin if (ey15 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey15 <= ey15 - 2; else begin ey15 <= WALL_THICKNESS + ENEMY_RADIUS;           dir15_v <= 1'b1; end end

            if (dir16_v) begin if (ey16 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey16 <= ey16 + 2; else begin ey16 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir16_v <= 1'b0; end end
            else         begin if (ey16 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey16 <= ey16 - 2; else begin ey16 <= WALL_THICKNESS + ENEMY_RADIUS;           dir16_v <= 1'b1; end end

            if (dir17_v) begin if (ey17 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey17 <= ey17 + 2; else begin ey17 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir17_v <= 1'b0; end end
            else         begin if (ey17 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey17 <= ey17 - 2; else begin ey17 <= WALL_THICKNESS + ENEMY_RADIUS;           dir17_v <= 1'b1; end end

            if (dir18_v) begin if (ey18 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey18 <= ey18 + 2; else begin ey18 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir18_v <= 1'b0; end end
            else         begin if (ey18 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey18 <= ey18 - 2; else begin ey18 <= WALL_THICKNESS + ENEMY_RADIUS;           dir18_v <= 1'b1; end end

            if (dir19_v) begin if (ey19 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey19 <= ey19 + 2; else begin ey19 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir19_v <= 1'b0; end end
            else         begin if (ey19 >= WALL_THICKNESS + ENEMY_RADIUS + 2)           ey19 <= ey19 - 2; else begin ey19 <= WALL_THICKNESS + ENEMY_RADIUS;           dir19_v <= 1'b1; end end
        end
    end

    // -----------------------------
    // drawing circles function
    // -----------------------------
    function [21:0] dist_sq;
        input [10:0] x1, y1, x2, y2;
        reg   [10:0] dx, dy;
        begin
            dx = (x1 > x2) ? (x1 - x2) : (x2 - x1);
            dy = (y1 > y2) ? (y1 - y2) : (y2 - y1);
            dist_sq = (dx * dx) + (dy * dy);
        end
    endfunction

    wire [21:0] enemy_r_sq = ENEMY_RADIUS * ENEMY_RADIUS;
    wire [21:0] ball_r_sq  = BALL_RADIUS  * BALL_RADIUS;
    wire [21:0] pellet_r_sq = PELLET_RADIUS * PELLET_RADIUS;

    // -----------------------------
    // pellet render
    // -----------------------------
    wire [10:0] rr_x = (hcount >= WALL_THICKNESS) ? (hcount - WALL_THICKNESS) : 11'd0;
    wire [10:0] rr_y = (vcount >= WALL_THICKNESS) ? (vcount - WALL_THICKNESS) : 11'd0;

    wire [3:0] rg_x = rr_x / 40;
    wire [3:0] rg_y = rr_y / 40;

    wire [7:0] render_idx = (rg_y * 8'd15) + rg_x;

    wire [10:0] p_cx = 11'd40 + (rg_x * 11'd40);
    wire [10:0] p_cy = 11'd40 + (rg_y * 11'd40);

    wire is_pellet_pixel =
        (hcount >= WALL_THICKNESS) && (vcount >= WALL_THICKNESS) &&
        (rg_x < 4'd15) && (rg_y < 4'd11) &&
        (pellet_bits[render_idx] == 1'b1) &&
        (dist_sq(hcount, vcount, p_cx, p_cy) < pellet_r_sq);

    // -----------------------------
    // final pixel output
    // -----------------------------
    always @(*) begin
        if (blank) begin
            rgb = 12'h000;
        end else if ((hcount < WALL_THICKNESS) ||
                     (hcount >= SCREEN_W - WALL_THICKNESS) ||
                     (vcount < WALL_THICKNESS) ||
                     (vcount >= SCREEN_H - WALL_THICKNESS)) begin
            rgb = 12'h00F;
        end else if (is_pellet_pixel) begin
            rgb = 12'hFFF;
        end else begin
            if      (dist_sq(hcount, vcount, ex0,  ey0)  < enemy_r_sq) rgb = 12'hF00;
            else if (dist_sq(hcount, vcount, ex1,  ey1)  < enemy_r_sq) rgb = 12'h0F0;
            else if (dist_sq(hcount, vcount, ex2,  ey2)  < enemy_r_sq) rgb = 12'h00F;
            else if (dist_sq(hcount, vcount, ex3,  ey3)  < enemy_r_sq) rgb = 12'h0FF;
            else if (dist_sq(hcount, vcount, ex4,  ey4)  < enemy_r_sq) rgb = 12'hF0F;
            else if (dist_sq(hcount, vcount, ex5,  ey5)  < enemy_r_sq) rgb = 12'hFF0;
            else if (dist_sq(hcount, vcount, ex6,  ey6)  < enemy_r_sq) rgb = 12'hF80;
            else if (dist_sq(hcount, vcount, ex7,  ey7)  < enemy_r_sq) rgb = 12'hF8F;
            else if (dist_sq(hcount, vcount, ex8,  ey8)  < enemy_r_sq) rgb = 12'h08F;
            else if (dist_sq(hcount, vcount, ex9,  ey9)  < enemy_r_sq) rgb = 12'h8F0;
            else if (dist_sq(hcount, vcount, ex10, ey10) < enemy_r_sq) rgb = 12'hF44;
            else if (dist_sq(hcount, vcount, ex11, ey11) < enemy_r_sq) rgb = 12'h4F4;
            else if (dist_sq(hcount, vcount, ex12, ey12) < enemy_r_sq) rgb = 12'h44F;
            else if (dist_sq(hcount, vcount, ex13, ey13) < enemy_r_sq) rgb = 12'hA50;
            else if (dist_sq(hcount, vcount, ex14, ey14) < enemy_r_sq) rgb = 12'hA0A;
            else if (dist_sq(hcount, vcount, ex15, ey15) < enemy_r_sq) rgb = 12'h0AF;
            else if (dist_sq(hcount, vcount, ex16, ey16) < enemy_r_sq) rgb = 12'h8A0;
            else if (dist_sq(hcount, vcount, ex17, ey17) < enemy_r_sq) rgb = 12'h00A;
            else if (dist_sq(hcount, vcount, ex18, ey18) < enemy_r_sq) rgb = 12'hA00;
            else if (dist_sq(hcount, vcount, ex19, ey19) < enemy_r_sq) rgb = 12'h888;
            else if (dist_sq(hcount, vcount, cx,   cy)   < ball_r_sq)  rgb = 12'hFF0;
            else rgb = 12'h000;
        end
    end

endmodule
