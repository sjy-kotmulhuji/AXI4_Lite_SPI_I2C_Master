# AXI4 SPI & I2C 설계 및 검증

> Verilog & C | MicroBlaze 기반 SoC | FPGA 보드 동작 검증  
> 온디바이스AI 반도체 설계 1기 · 2026.05 · 송주연

---

## 📌 프로젝트 개요

MicroBlaze CPU와 **AXI4-Lite 프로토콜**로 통신하는 **SPI Master** 및 **I2C Master** IP를 직접 설계하고, FPGA 보드에서 Master–Slave 동작을 검증한 프로젝트입니다.

| 항목 | 내용 |
|------|------|
| **프로토콜** | AXI4-Lite, SPI, I2C |
| **설계 언어** | SystemVerilog / Verilog, C |
| **툴** | Vivado, Vitis, VCS (UVM) |
| **보드** | Basys3 (Xilinx Artix-7) |

---

## 🏗️ 시스템 구성

```
MicroBlaze (AXI Master)
    │
    ├── AXI UartLite IP   (디버깅용 시리얼 출력)
    ├── GPIO IP           (Switch / LED / FND / Button)
    ├── AXI SPI Master IP (직접 설계)
    └── AXI I2C Master IP (직접 설계)
```

### AXI4-Lite 채널 구조

| 채널 | 방향 | 설명 |
|------|------|------|
| AW | Master → Slave | Write Address |
| W  | Master → Slave | Write Data |
| B  | Slave → Master | Write Response |
| AR | Master → Slave | Read Address |
| R  | Slave → Master | Read Data & Response |

> 각 채널은 **VALID & READY 핸드셰이크** 방식으로 동작하며, 두 신호가 동시에 1이 되는 클럭 엣지에서 트랜잭션이 완료됩니다.

---

## 📡 AXI SPI

### IP 구조
- Vivado AXI Slave Interface 템플릿에 직접 설계한 SPI Master RTL 연결
- Register Mapping을 통해 MicroBlaze에서 SPI 제어

### GPIO 핀 맵

| 신호 | 역할 |
|------|------|
| GPIOA[7:0] | switch[7:0] |
| GPIOB[7:0] | LED[7:0] |
| GPIOC[7:0] | fnd_data[7:0] |
| GPIOD[3:0] | fnd_digit[3:0] |
| GPIOD[7:4] | 상하좌우 Button |

### 동작 시연
- Master 보드의 switch 0~7번 입력 → 8bit 데이터를 10진수로 변환 → Slave 보드 FND 출력

---

## 🔗 AXI I2C

### IP 구조
- SPI와 동일한 AXI Slave 구조, I2C Master RTL 연결
- SCL / SDA 오픈 드레인 특성 고려한 설계

### 동작 시연
- Master 보드의 switch 0~7번 입력 → Slave 보드 LED 0~7번 출력

---

## ✅ UVM 검증 (AXI SPI)

### 검증 시나리오

| 시나리오 | 내용 |
|----------|------|
| Write (Master → Slave) | `m_tx_data` → `s_rx_data` 정상 전달 확인 |
| Read (Slave → Master) | `s_tx_data` → `m_rx_data` 정상 전달 확인 |
| 동작 신호 확인 | SCLK 활성화 타이밍, done 펄스 신호 검증 |

### 검증 결과
- Scoreboard 비교 통과: `m_tx_data ↔ s_rx_data`, `s_tx_data ↔ m_rx_data` 모두 일치
- Coverage 100% 달성

---

## 🧱 소프트웨어 설계 (HAL 기반 Layered Architecture)

```
[ Application Layer ]  ← 사용자 기능 구현 (Driver 조합)
[ Driver Layer      ]  ← 각 하드웨어 개별 동작 구현
[ HAL Layer         ]  ← 하드웨어 레지스터 직접 접근 함수
[ Hardware (RTL)    ]  ← AXI Slave IP
```

상위 레이어는 바로 아래 레이어만 접근 가능하며, HAL 함수 호출만으로 하드웨어 동작을 추상화합니다.

---

## 🐛 Trouble Shooting

### I2C Master IP – Port 설정 오류

**문제**  
Command 신호, `tx_data`, `ack_in`을 외부 port로 선언 → 의도와 다른 연결 발생

**원인**  
AXI Master(MicroBlaze)는 IP의 외부 port가 아닌 **내부 레지스터**에 접근하여 값을 지정하는 구조

**해결**  
해당 신호들을 외부 port → **내부 wire**로 변경

---

## 💬 느낀 점

- AXI 핸드셰이크 방식과 채널별 역할을 직접 구현하면서 버스 프로토콜에 대한 이해도가 크게 향상됨
- CPU(MicroBlaze)부터 GPIO, SPI, I2C Slave까지 직접 설계하고 FPGA 보드에서 동작시키면서 **SoC 전체 구조와 데이터 흐름**을 체감할 수 있었음
