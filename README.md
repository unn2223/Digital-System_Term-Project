# FPGA Pacman-like Game (VGA 640x480)

Verilog로 만든 간단한 Pac-Man 스타일 게임입니다.
VGA(640x480)로 화면을 출력하고, 버튼으로 캐릭터를 움직여 펠릿을 먹습니다. 적과 충돌하면 게임이 리셋됩니다.

---

## 폴더 구조 (Tree)

```text
Digital-System-Term-Project
├── src
│   ├── clock_divider.v
│   ├── move_control.v
│   ├── top.v
│   └── vga_controller_640_480.v
├── pacman.xdc
└── implementation.mp4
```

---

## 핵심 기능

* **VGA 출력**: 640x480 타이밍(HS/VS/blank/hcount/vcount) 생성
* **프레임 기반 업데이트**: VS를 프레임 tick으로 사용해 매 프레임 단위로 게임 상태 갱신
* **팩맨 이동**: 버튼(상/하/좌/우) 입력으로 이동, 벽 밖으로 못 나가도록 제한
* **펠릿 시스템**: 15×11 총 165개의 펠릿, 펠릿을 먹으면 사라지고, 리셋 시 전체 복구
* **적 20마리 랜덤 위치 및 랜덤 방향 이동**
  * 외벽에 닿으면 방향 반전
* **충돌 판정**: 적과 충돌 시 즉시 리셋

---

## 파일 설명

* `src/top.v`
  Top 모듈(`pacman_top`). 게임 상태 업데이트 + 렌더링(벽/펠릿/적/팩맨) 담당
* `src/clock_divider.v`
  보드 클럭(예: 100MHz)을 VGA용 픽셀 클럭(≈25MHz)으로 분주
* `src/move_control.v`
  버튼 입력 동기화 + 프레임마다 이동 반영 + reset/경계 clamp
* `src/vga_controller_640_480.v`
  VGA 타이밍(HS/VS/blank/hcount/vcount) 생성
* `pacman.xdc`
  FPGA 보드 핀 매핑(클럭/버튼/VGA/RGB)
    *  Xilinx **XC7A75T-1FGG484I**(Artix-7) 기준으로 작성된 핀 매핑 파일입니다.  
  다른 보드/FPGA를 사용할 경우 클럭, 버튼, VGA(RGB/HS/VS) 핀을 환경에 맞게 수정해야 합니다.
---

## 실행 방법 (Vivado 기준)

1. 새 프로젝트 생성 후 `src/*.v` 추가
2. `pacman.xdc`를 Constraints로 추가
3. Synthesis → Implementation → Bitstream 생성
4. FPGA에 다운로드 후 VGA 모니터 연결

---

## 조작

* **UP / DOWN / LEFT / RIGHT**: 팩맨 이동
* **적과 충돌**: 자동 리셋(위치/펠릿 초기화)
