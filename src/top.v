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

    // 1) 100MHz -> 25MHz 분주
    wire pixel_clk;
    clock_divider #(1) clkdiv (
        .clk_in  (clk),
        .clk_out (pixel_clk)
    );

    // 2) VGA Controller
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

    // 3) move_control
    wire [10:0] mover_cx, mover_cy;
    move_control #(4) mover (
        .pixel_clk (pixel_clk),
        .vs        (vs),
        .btn_up    (btn_up),
        .btn_down  (btn_down),
        .btn_left  (btn_left),
        .btn_right (btn_right),
        .cx        (mover_cx),
        .cy        (mover_cy)
    );

    // Pac-Man 좌표 및 리셋 플래그
    reg [10:0] cx = 320, cy = 240;
    reg        pacman_reset = 1'b0;

    // 4) 시작시 펠릿 배열 (15x11)
    reg pellet_map [0:14][0:10];
    integer i, j;
    initial begin
        for (i = 0; i < 15; i = i + 1)
            for (j = 0; j < 11; j = j + 1)
                pellet_map[i][j] = 1;
    end

    // 5) 상수 정의
    localparam BALL_RADIUS    = 10;
    localparam PELLET_RADIUS  = 4;
    localparam ENEMY_RADIUS   = 10;
    localparam WALL_THICKNESS = 20;
    localparam SCREEN_W       = 640;
    localparam SCREEN_H       = 480;

    // 6) vs 상승 에지 검출
    reg vs_d;
    always @(posedge pixel_clk) vs_d <= vs;
    wire vs_rise = vs & ~vs_d;

    // 7) 적 위치 및 방향 레지스터
    //    적0-9: 좌우 이동
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
    //    적10-19: 상하 이동
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

    // =================================================================
    //  - 한 클럭에 20개를 다 검사하지 않고, 매 클럭마다 적 1마리씩 돌아가며 검사
    //  - 하드웨어 자원 최소화 (비교기 1개만 재사용)
    // =================================================================

    reg [4:0]  check_idx;      // 0~19까지 적 인덱스를 세는 카운터
    reg [10:0] target_ex, target_ey; // 현재 검사할 적의 좌표
    reg        collide_latch;  // 한 프레임 내에서 충돌 감지 여부 저장

    // 1. Multiplexer: 현재 검사할 적(check_idx)의 좌표 선택
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

    // 2. 단일 비교기: 선택된 적 1마리와 팩맨의 거리 계산
    //    (원형 충돌 판정: 거리제곱 < 반지름합의 제곱)
    wire [10:0] t_diff_x = (cx > target_ex) ? (cx - target_ex) : (target_ex - cx);
    wire [10:0] t_diff_y = (cy > target_ey) ? (cy - target_ey) : (target_ey - cy);
    wire [21:0] t_dist_sq = (t_diff_x * t_diff_x) + (t_diff_y * t_diff_y);
    
    // 현재 선택된 적과 충돌 여부
    wire current_check_hit = (t_dist_sq < (BALL_RADIUS + ENEMY_RADIUS)*(BALL_RADIUS + ENEMY_RADIUS));

    // 3. 순차 검사기 (Sequential Logic)
    always @(posedge pixel_clk) begin
        if (rst) begin
            check_idx <= 0;
            collide_latch <= 0;
        end else begin
            if (check_idx == 19) check_idx <= 0;
            else check_idx <= check_idx + 1;
            // 충돌 감지 시 래치(Latch) 설정
            // vs_rise(프레임 시작)일 때 리셋하여 새 프레임 검사 준비
            if (vs_rise) begin
                collide_latch <= 0;
            end else if (current_check_hit) begin
                collide_latch <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------
    // 충돌 상승 에지 검출 (리셋 트리거용)
    // -------------------------------------------------------------
    reg collide_d;
    always @(posedge pixel_clk) begin
        if (rst) collide_d <= 1'b0;
        else if (vs_rise) collide_d <= collide_latch; // 프레임 단위로 엣지 체크
    end
    wire collide_rise = collide_latch & ~collide_d;


    // =================================================================
    // 팩맨-펠릿 충돌 로직
    // =================================================================
    
    // 1. 팩맨의 현재 격자 인덱스 계산
    wire [10:0] pm_rel_x = (cx >= 20) ? (cx - 20) : 11'd0;
    wire [10:0] pm_rel_y = (cy >= 20) ? (cy - 20) : 11'd0;
    
    wire [3:0] pm_grid_x = pm_rel_x / 40; 
    wire [3:0] pm_grid_y = pm_rel_y / 40;

    // 2. 그 격자의 펠릿 중심점 좌표 계산
    wire [10:0] target_pellet_x = 40 + (pm_grid_x * 40);
    wire [10:0] target_pellet_y = 40 + (pm_grid_y * 40);

    // 3. 거리 제곱 계산 (팩맨 중심 <-> 타겟 펠릿 중심)
    wire [10:0] pm_diff_x = (cx > target_pellet_x) ? (cx - target_pellet_x) : (target_pellet_x - cx);
    wire [10:0] pm_diff_y = (cy > target_pellet_y) ? (cy - target_pellet_y) : (target_pellet_y - cy);
    wire [21:0] pm_dist_sq = (pm_diff_x * pm_diff_x) + (pm_diff_y * pm_diff_y);

    // 4. 먹기 판정 신호 (Grid 범위 체크 + 펠릿 존재 여부 + 거리 체크)
    wire eat_signal = (pm_grid_x < 15 && pm_grid_y < 11) &&
                      (pellet_map[pm_grid_x][pm_grid_y] == 1) &&
                      (pm_dist_sq < (BALL_RADIUS + PELLET_RADIUS)*(BALL_RADIUS + PELLET_RADIUS));


    // =================================================================
    // [메인 로직] 상태 업데이트
    // =================================================================
    always @(posedge pixel_clk) begin
        if (rst || collide_rise) begin
            // 1) 리셋시 모든 펠릿 복구
            for (i = 0; i < 15; i = i + 1)
                for (j = 0; j < 11; j = j + 1)
                    pellet_map[i][j] <= 1;
            
            // 2) 팩맨 초기화
            cx <= 320; 
            cy <= 240;
            pacman_reset <= 1'b1;

            // 3) 적 초기화
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
            // 1) 펠릿 업데이트
            if (eat_signal) begin
                pellet_map[pm_grid_x][pm_grid_y] <= 0;
            end

            // 2) Pac-Man 좌표 갱신
            if (pacman_reset) begin
                cx <= 320; 
                cy <= 240;
                if (btn_up || btn_down || btn_left || btn_right)
                    pacman_reset <= 1'b0;
            end else begin
                cx <= mover_cx;
                cy <= mover_cy;
            end

            // 3) 적 이동 로직
            //    적0 (좌우)
            if (dir0_h) begin
                if (ex0 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex0 <= ex0 + 2;
                else begin ex0 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir0_h <= 1'b0; end
            end else begin
                if (ex0 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex0 <= ex0 - 2;
                else begin ex0 <= WALL_THICKNESS + ENEMY_RADIUS; dir0_h <= 1'b1; end
            end

            //    적1 (좌우)
            if (dir1_h) begin
                if (ex1 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex1 <= ex1 + 2;
                else begin ex1 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir1_h <= 1'b0; end
            end else begin
                if (ex1 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex1 <= ex1 - 2;
                else begin ex1 <= WALL_THICKNESS + ENEMY_RADIUS; dir1_h <= 1'b1; end
            end

            //    적2 (좌우)
            if (dir2_h) begin
                if (ex2 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex2 <= ex2 + 2;
                else begin ex2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir2_h <= 1'b0; end
            end else begin
                if (ex2 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex2 <= ex2 - 2;
                else begin ex2 <= WALL_THICKNESS + ENEMY_RADIUS; dir2_h <= 1'b1; end
            end

            //    적3 (좌우)
            if (dir3_h) begin
                if (ex3 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex3 <= ex3 + 2;
                else begin ex3 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir3_h <= 1'b0; end
            end else begin
                if (ex3 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex3 <= ex3 - 2;
                else begin ex3 <= WALL_THICKNESS + ENEMY_RADIUS; dir3_h <= 1'b1; end
            end

            //    적4 (좌우)
            if (dir4_h) begin
                if (ex4 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex4 <= ex4 + 2;
                else begin ex4 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir4_h <= 1'b0; end
            end else begin
                if (ex4 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex4 <= ex4 - 2;
                else begin ex4 <= WALL_THICKNESS + ENEMY_RADIUS; dir4_h <= 1'b1; end
            end

            //    적5 (좌우)
            if (dir5_h) begin
                if (ex5 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex5 <= ex5 + 2;
                else begin ex5 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir5_h <= 1'b0; end
            end else begin
                if (ex5 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex5 <= ex5 - 2;
                else begin ex5 <= WALL_THICKNESS + ENEMY_RADIUS; dir5_h <= 1'b1; end
            end

            //    적6 (좌우)
            if (dir6_h) begin
                if (ex6 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex6 <= ex6 + 2;
                else begin ex6 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir6_h <= 1'b0; end
            end else begin
                if (ex6 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex6 <= ex6 - 2;
                else begin ex6 <= WALL_THICKNESS + ENEMY_RADIUS; dir6_h <= 1'b1; end
            end

            //    적7 (좌우)
            if (dir7_h) begin
                if (ex7 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex7 <= ex7 + 2;
                else begin ex7 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir7_h <= 1'b0; end
            end else begin
                if (ex7 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex7 <= ex7 - 2;
                else begin ex7 <= WALL_THICKNESS + ENEMY_RADIUS; dir7_h <= 1'b1; end
            end

            //    적8 (좌우)
            if (dir8_h) begin
                if (ex8 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex8 <= ex8 + 2;
                else begin ex8 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir8_h <= 1'b0; end
            end else begin
                if (ex8 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex8 <= ex8 - 2;
                else begin ex8 <= WALL_THICKNESS + ENEMY_RADIUS; dir8_h <= 1'b1; end
            end

            //    적9 (좌우)
            if (dir9_h) begin
                if (ex9 + 2 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS) ex9 <= ex9 + 2;
                else begin ex9 <= SCREEN_W - WALL_THICKNESS - ENEMY_RADIUS; dir9_h <= 1'b0; end
            end else begin
                if (ex9 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ex9 <= ex9 - 2;
                else begin ex9 <= WALL_THICKNESS + ENEMY_RADIUS; dir9_h <= 1'b1; end
            end

            //    적10 (상하)
            if (dir10_v) begin
                if (ey10 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey10 <= ey10 + 2;
                else begin ey10 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir10_v <= 1'b0; end
            end else begin
                if (ey10 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey10 <= ey10 - 2;
                else begin ey10 <= WALL_THICKNESS + ENEMY_RADIUS; dir10_v <= 1'b1; end
            end

            //    적11 (상하)
            if (dir11_v) begin
                if (ey11 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey11 <= ey11 + 2;
                else begin ey11 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir11_v <= 1'b0; end
            end else begin
                if (ey11 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey11 <= ey11 - 2;
                else begin ey11 <= WALL_THICKNESS + ENEMY_RADIUS; dir11_v <= 1'b1; end
            end

            //    적12 (상하)
            if (dir12_v) begin
                if (ey12 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey12 <= ey12 + 2;
                else begin ey12 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir12_v <= 1'b0; end
            end else begin
                if (ey12 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey12 <= ey12 - 2;
                else begin ey12 <= WALL_THICKNESS + ENEMY_RADIUS; dir12_v <= 1'b1; end
            end

            //    적13 (상하)
            if (dir13_v) begin
                if (ey13 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey13 <= ey13 + 2;
                else begin ey13 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir13_v <= 1'b0; end
            end else begin
                if (ey13 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey13 <= ey13 - 2;
                else begin ey13 <= WALL_THICKNESS + ENEMY_RADIUS; dir13_v <= 1'b1; end
            end

            //    적14 (상하)
            if (dir14_v) begin
                if (ey14 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey14 <= ey14 + 2;
                else begin ey14 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir14_v <= 1'b0; end
            end else begin
                if (ey14 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey14 <= ey14 - 2;
                else begin ey14 <= WALL_THICKNESS + ENEMY_RADIUS; dir14_v <= 1'b1; end
            end

            //    적15 (상하)
            if (dir15_v) begin
                if (ey15 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey15 <= ey15 + 2;
                else begin ey15 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir15_v <= 1'b0; end
            end else begin
                if (ey15 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey15 <= ey15 - 2;
                else begin ey15 <= WALL_THICKNESS + ENEMY_RADIUS; dir15_v <= 1'b1; end
            end

            //    적16 (상하)
            if (dir16_v) begin
                if (ey16 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey16 <= ey16 + 2;
                else begin ey16 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir16_v <= 1'b0; end
            end else begin
                if (ey16 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey16 <= ey16 - 2;
                else begin ey16 <= WALL_THICKNESS + ENEMY_RADIUS; dir16_v <= 1'b1; end
            end

            //    적17 (상하)
            if (dir17_v) begin
                if (ey17 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey17 <= ey17 + 2;
                else begin ey17 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir17_v <= 1'b0; end
            end else begin
                if (ey17 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey17 <= ey17 - 2;
                else begin ey17 <= WALL_THICKNESS + ENEMY_RADIUS; dir17_v <= 1'b1; end
            end

            //    적18 (상하)
            if (dir18_v) begin
                if (ey18 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey18 <= ey18 + 2;
                else begin ey18 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir18_v <= 1'b0; end
            end else begin
                if (ey18 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey18 <= ey18 - 2;
                else begin ey18 <= WALL_THICKNESS + ENEMY_RADIUS; dir18_v <= 1'b1; end
            end

            //    적19 (상하)
            if (dir19_v) begin
                if (ey19 + 2 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS) ey19 <= ey19 + 2;
                else begin ey19 <= SCREEN_H - WALL_THICKNESS - ENEMY_RADIUS; dir19_v <= 1'b0; end
            end else begin
                if (ey19 >= WALL_THICKNESS + ENEMY_RADIUS + 2) ey19 <= ey19 - 2;
                else begin ey19 <= WALL_THICKNESS + ENEMY_RADIUS; dir19_v <= 1'b1; end
            end
        end
    end

    // =================================================================
    // 펠릿 렌더링용 로직
    // =================================================================

    // 1. 렌더링용 격자 인덱스 계산
    wire [10:0] render_rel_x = (hcount >= 20) ? (hcount - 20) : 11'd0;
    wire [10:0] render_rel_y = (vcount >= 20) ? (vcount - 20) : 11'd0;
    
    wire [3:0] render_grid_x = render_rel_x / 40; 
    wire [3:0] render_grid_y = render_rel_y / 40;

    // 2. 해당 격자의 펠릿 중심점
    wire [10:0] render_p_center_x = 40 + (render_grid_x * 40);
    wire [10:0] render_p_center_y = 40 + (render_grid_y * 40);

    // 3. 거리 제곱 계산
    wire [10:0] render_diff_x = (hcount > render_p_center_x) ? (hcount - render_p_center_x) : (render_p_center_x - hcount);
    wire [10:0] render_diff_y = (vcount > render_p_center_y) ? (vcount - render_p_center_y) : (render_p_center_y - vcount);
    
    wire [21:0] render_dist_sq = (render_diff_x * render_diff_x) + (render_diff_y * render_diff_y);

    // 4. 최종 펠릿 렌더링 판정
    wire is_pellet_pixel = (hcount >= 20 && vcount >= 20) &&
                           (render_grid_x < 15 && render_grid_y < 11) &&
                           (pellet_map[render_grid_x][render_grid_y] == 1) &&
                           (render_dist_sq < PELLET_RADIUS * PELLET_RADIUS);


    // =================================================================
    // 화면 출력 (Multiplexer)
    // =================================================================
    always @(*) begin
        if (blank) begin
            rgb = 12'h000;
        end else begin
            // 벽 그리기
            if ((hcount < WALL_THICKNESS) 
             || (hcount >= SCREEN_W - WALL_THICKNESS)
             || (vcount < WALL_THICKNESS) 
             || (vcount >= SCREEN_H - WALL_THICKNESS)) begin
                rgb = 12'h00F; // 파란색 벽
            end 
            else begin
                if (is_pellet_pixel) begin
                    rgb = 12'hFFF; // 하얀색 펠릿
                end 
                else begin
                    // 적들 그리기
                    if      ((hcount - ex0)*(hcount - ex0) + (vcount - ey0)*(vcount - ey0) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hF00;
                    else if ((hcount - ex1)*(hcount - ex1) + (vcount - ey1)*(vcount - ey1) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h0F0;
                    else if ((hcount - ex2)*(hcount - ex2) + (vcount - ey2)*(vcount - ey2) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h00F;
                    else if ((hcount - ex3)*(hcount - ex3) + (vcount - ey3)*(vcount - ey3) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h0FF;
                    else if ((hcount - ex4)*(hcount - ex4) + (vcount - ey4)*(vcount - ey4) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hF0F;
                    else if ((hcount - ex5)*(hcount - ex5) + (vcount - ey5)*(vcount - ey5) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hFF0;
                    else if ((hcount - ex6)*(hcount - ex6) + (vcount - ey6)*(vcount - ey6) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hF80;
                    else if ((hcount - ex7)*(hcount - ex7) + (vcount - ey7)*(vcount - ey7) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hF8F;
                    else if ((hcount - ex8)*(hcount - ex8) + (vcount - ey8)*(vcount - ey8) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h08F;
                    else if ((hcount - ex9)*(hcount - ex9) + (vcount - ey9)*(vcount - ey9) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h8F0;
                    else if ((hcount - ex10)*(hcount - ex10) + (vcount - ey10)*(vcount - ey10) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hF44;
                    else if ((hcount - ex11)*(hcount - ex11) + (vcount - ey11)*(vcount - ey11) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h4F4;
                    else if ((hcount - ex12)*(hcount - ex12) + (vcount - ey12)*(vcount - ey12) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h44F;
                    else if ((hcount - ex13)*(hcount - ex13) + (vcount - ey13)*(vcount - ey13) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hA50;
                    else if ((hcount - ex14)*(hcount - ex14) + (vcount - ey14)*(vcount - ey14) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hA0A;
                    else if ((hcount - ex15)*(hcount - ex15) + (vcount - ey15)*(vcount - ey15) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h0AF;
                    else if ((hcount - ex16)*(hcount - ex16) + (vcount - ey16)*(vcount - ey16) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h8A0;
                    else if ((hcount - ex17)*(hcount - ex17) + (vcount - ey17)*(vcount - ey17) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h00A;
                    else if ((hcount - ex18)*(hcount - ex18) + (vcount - ey18)*(vcount - ey18) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'hA00;
                    else if ((hcount - ex19)*(hcount - ex19) + (vcount - ey19)*(vcount - ey19) < (ENEMY_RADIUS*ENEMY_RADIUS)) rgb = 12'h888;
                    else begin
                        // Pac-Man 그리기
                        if ((hcount - cx)*(hcount - cx) + (vcount - cy)*(vcount - cy)
                            < (BALL_RADIUS * BALL_RADIUS)) begin
                            rgb = 12'hFF0; // 노란색 팩맨
                        end else begin
                            // 배경
                            rgb = 12'h000;
                        end
                    end
                end
            end
        end
    end

endmodule
