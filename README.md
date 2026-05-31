# AXI4 SPI / I2C 설계 및 검증

> MicroBlaze 기반 SoC에서 AXI4-Lite 프로토콜로 통신하는 SPI / I2C Master IP 설계 및 검증 (Verilog, C)

---

## 📌 프로젝트 개요

- MicroBlaze CPU와 **AXI4-Lite** 프로토콜로 통신하는 **SPI Master / I2C Master IP** 설계
- MicroBlaze 기반 **SoC 시스템** 구성 (Vivado Block Design)
- **HAL 기반 Layered Architecture** C Firmware 구현
- FPGA 보드를 이용한 Master – Slave 동작 검증

---

## 🛠️ 개발 환경

- Language: Verilog, C
- Tool: Vivado, Vitis
- Protocol: AMBA AXI4-Lite
- Board: Basys3 (Xilinx Artix-7)

---

## 🚌 AXI (Advanced eXtensible Interface)

### 개요

AMBA Bus 프로토콜 중 하나로 SoC 내부에서 CPU와 주변장치 간 고속 통신을 위한 표준 인터페이스입니다.

- 동작에 따라 **5개의 채널**로 구성
- 각 채널은 Info + **VALID / READY** 핸드셰이크 신호로 구성
- **AXI4-Lite** : AXI4의 경량화 버전, 단일 트랜잭션만 처리

### 채널 구성

| 채널 | 방향 | 설명 |
|------|------|------|
| `AW` | Master → Slave | Write Address |
| `W` | Master → Slave | Write Data |
| `B` | Slave → Master | Write Response |
| `AR` | Master → Slave | Read Address |
| `R` | Slave → Master | Read Data & Response |

> 각 채널의 **VALID와 READY가 동시에 1**이 되는 클락 엣지에서 해당 채널의 트랜잭션이 완료됩니다.

### Write Transaction

| 채널 | Master 역할 | Slave 역할 |
|------|------------|-----------|
| AW, W | Source → **VALID** 생성 | Destination → **READY** 생성 |
| B | Destination → **READY** 생성 | Source → **VALID** 생성 |

### Read Transaction

| 채널 | Master 역할 | Slave 역할 |
|------|------------|-----------|
| AR | Source → **VALID** 생성 | Destination → **READY** 생성 |
| R | Destination → **READY** 생성 | Source → **VALID** 생성 |

---

## 🧱 SoC 구성

### IP 구성

| IP | 설명 |
|----|------|
| **MicroBlaze** | Xilinx Soft Processor IP, AXI Master로 동작 |
| **AXI Uartlite** | `xil_printf`로 시리얼 데이터를 PC로 전송, 디버깅 용도 |
| **AXI Peripheral (Slave) IP** | Vivado AXI Slave 템플릿에 직접 설계한 RTL 로직 연결 |

**설계한 AXI Slave IP 목록**
- GPIO
- FND
- SPI Master
- I2C Master

### GPIO 구성

| 포트 | 연결 |
|------|------|
| `GPIOA[7:0]` | switch[7:0] |
| `GPIOB[7:0]` | LED[7:0] |
| `GPIOC[7:0]` | fnd_data[7:0] |
| `GPIOD[3:0]` | fnd_digit[3:0] |
| `GPIOD[7:4]` | 상하좌우 Button |

---

## ⚙️ Software 설계

### HAL 기반 Layered Architecture

| 계층 | 역할 |
|------|------|
| **Application** | Driver를 조합하여 실제 사용자 기능 구현 |
| **Driver** | 각 하드웨어 요소들의 개별 동작 구현 |
| **HAL** | 하드웨어 레지스터에 직접 접근하는 함수 구현 |

- **HAL (Hardware Abstraction Layer)** : Hardware와 OS 사이의 인터페이스 역할
- 상위 Software 계층이 하드웨어 동작을 신경 쓸 필요 없이 HAL 함수 호출만으로 동작 가능
- 상위 계층은 바로 아래 계층에만 접근 가능

---

## 📡 AXI SPI

### Block Diagram

MicroBlaze → AXI4-Lite → SPI Master IP → SPI Slave (외부 보드)

### FPGA 동작 시연

- **구성** : 좌측 Slave 보드 / 우측 Master 보드
- **동작** : Master의 switch 0~7번 입력에 따른 8bit 데이터를 10진수 형태로 Slave의 FND에 출력

---

## 🔗 AXI I2C

### Block Diagram

MicroBlaze → AXI4-Lite → I2C Master IP → I2C Slave (외부 보드)

### FPGA 동작 시연

- **구성** : 좌측 Slave 보드 / 우측 Master 보드
- **동작** : Master의 switch 0~7번 입력에 따른 8bit 데이터를 Slave의 LED 0~7번에 출력

---

## ✅ AXI SPI UVM 검증

### 검증 시나리오

| 시나리오 | 내용 |
|---------|------|
| Write (Master → Slave) | `m_tx_data`가 `s_rx_data`로 정상 전달되는지 확인 |
| Read (Slave → Master) | `s_tx_data`가 `m_rx_data`로 정상 전달되는지 확인 |
| 동작 신호 확인 | SCLK 데이터 송수신 상태에서만 활성화 확인, `done` 신호 펄스 출력 확인 |

### 검증 결과

| 항목 | 결과 |
|------|------|
| Scoreboard | `s_tx_data` ↔ `m_rx_data` 비교 일치 ✅ |
| Coverage | `m_tx_data` / `s_rx_data` / `s_tx_data` / `m_rx_data` 전체 달성 ✅ |
| Log | PASS ✅ |

---

## 🐛 Trouble Shooting

### I2C Master IP Port 설정 오류

**문제**
Command 신호, `tx_data`, `ack_in` 신호를 AXI Master(MicroBlaze)로부터 AXI Top Module로 입력받아야 한다고 판단해 **외부 port**로 선언

**원인**
AXI Master는 AXI Top Module의 외부 port가 아니라 **내부 레지스터**에 접근해 값을 지정하는 방식으로 동작

**해결**
Command 신호들을 외부 port 대신 **내부 wire**로 선언해 정상 동작 확인
