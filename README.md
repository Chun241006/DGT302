# 🎛️ Digital Audio Equalizer (3-Band FIR Filter in Verilog HDL)

Hệ thống xử lý âm thanh số **Digital Audio Equalizer 3 dải** (Bass, Mid, Treble) triển khai trên phần cứng FPGA/ASIC bằng ngôn ngữ Verilog HDL. Hệ thống hoạt động tại tần số lấy mẫu $48\text{ kHz}$, tích hợp bộ lọc FIR Type-1 Linear Phase $31\text{ Taps}$, Gain Control định dạng $Q8.8$, Mixer và module Saturation chống tràn số.

Dự án bao gồm mô hình tham chiếu **Bit-Exact Python Golden Model** giúp tự động hóa quá trình xác minh (Co-simulation Verification) với kết quả đạt **MATCH 100% (0 mismatch)**.

---

## 📑 Mục lục (Table of Contents)
- [1. Tính năng nổi bật (Key Features)](#1-tính-năng-nổi-bật-key-features)
- [2. Thông số Kỹ thuật (System Specifications)](#2-thông-số-kỹ-thuật-system-specifications)
- [3. Cấu trúc Thư mục Dự án (Project Structure)](#3-cấu-trúc-thư-mục-dự-án-project-structure)
- [4. Kiến trúc Hệ thống Phân tầng (Top-Down Architecture)](#4-kiến-trúc-hệ-thống-phân-tầng-top-down-architecture)
- [5. Quy tắc Tính toán Số cố định (Fixed-Point Arithmetic Contract)](#5-quy-tắc-tính-toán-số-cố-định-fixed-point-arithmetic-contract)
- [6. Hướng dẫn Tái tạo Dữ liệu & Mô phỏng (Reproduction & Simulation)](#6-hướng-dẫn-tái-tạo-dữ-liệu--mô-phỏng-reproduction--simulation)
  - [Bước 1: Tạo Hệ số Bộ lọc & Đồ thị Đáp ứng Tần số](#bước-1-tạo-hệ-số-bộ-lọc--đồ-thị-đáp-ứng-tần-số)
  - [Bước 2: Tạo Test Vector & Chạy Golden Model](#bước-2-tạo-test-vector--chạy-golden-model)
  - [Bước 3: Chạy Mô phỏng RTL Testbench](#bước-3-chạy-mô-phỏng-rtl-testbench)
- [7. Kết quả Kiểm thử & Đối chiếu (Verification Results)](#7-kết-quả-kiểm-thử--đối-chiếu-verification-results)
- [8. Đánh giá & Giới hạn Kỹ thuật (Design Trade-offs)](#8-đánh-giá--giới-hạn-kỹ-thuật-design-trade-offs)

---

## 1. Tính năng nổi bật (Key Features)
- **3-Band Equalizer:** Phân tách và điều chỉnh độc lập 3 dải âm thanh Bass ($<200\text{ Hz}$), Mid ($250 - 3800\text{ Hz}$) và Treble ($>4000\text{ Hz}$).
- **Linear Phase Type-1 FIR:** Sử dụng $31\text{ Taps}$ (Group Delay $D = 15\text{ samples}$) giúp bảo toàn pha của tín hiệu audio, không gây méo pha.
- **Bit-Exact Golden Model:** Script Python mô phỏng chính xác từng bit với RTL, tự động hóa quy trình sinh đáp án mẫu (`expected_output.mem`).
- **Saturation Protection:** Tích hợp bộ xén biên (Saturation) tại từng dải lọc, sau bộ Gain và tại đầu ra Mixer, triệt tiêu hoàn toàn lỗi lật bit (Wrap-around Distortion).
- **Phù hợp FPGA/ASIC Flow:** Tối ưu hóa bộ nhân DSP, sẵn sàng tổng hợp (Synthesizable) trên Quartus, Vivado hoặc Synopsys DC.

---

## 2. Thông số Kỹ thuật (System Specifications)

| Thông số | Giá trị | Ghi chú |
| :--- | :--- | :--- |
| **Sampling Rate ($F_s$)** | $48000\text{ Hz}$ ($48\text{ kHz}$) | Tần số lấy mẫu chuẩn Audio PCM |
| **Filter Topology** | FIR Type-1 Cửa sổ Hamming | $31\text{ Taps}$, Đối xứng (Symmetric) |
| **Input/Output Sample** | Signed 16-bit (`Q1.15`) | Mã bù 2 Hex, Dải giá trị `[-32768, 32767]` |
| **Filter Coefficients** | Signed 16-bit (`Q1.15`) | Lưu trong file `$readmemh` Hex |
| **Gain Control ($G_b, G_m, G_t$)** | Signed 16-bit (`Q8.8`) | Unity Gain ($1.0$) tương ứng `256` (`16'sd256`) |
| **FIR Accumulator** | Signed 37-bit | Truncation `>>> 15` $\rightarrow$ Saturation 16-bit |
| **Gain Accumulator** | Signed 32-bit | Truncation `>>> 8` $\rightarrow$ Saturation 16-bit |
| **Mixer Accumulator** | Signed 18-bit | Mở rộng bit chống tràn $\rightarrow$ Saturation 16-bit |

---

## 3. Cấu trúc Thư mục Dự án (Project Structure)

```text
Digital-Audio-Equalizer-Verilog/
├── dsp/                        # Phân vùng xử lý tín hiệu DSP (TV1)
│   ├── coefficients/           # Các file hệ số bộ lọc Hex Q1.15 (.mem)
│   │   ├── bass_coeff.mem
│   │   ├── mid_coeff.mem
│   │   └── treble_coeff.mem
│   ├── plots/                  # Đồ thị đáp ứng tần số (.png)
│   │   ├── bass_response.png
│   │   ├── mid_response.png
│   │   └── treble_response.png
│   ├── coeff_gen.py            # Script tính hệ số FIR & xuất đồ thị
│   └── golden_model.py         # Bit-Exact Python Simulator chuẩn RTL
├── data/                       # Dữ liệu thử nghiệm & Test vectors
│   ├── input_samples.mem       # Mẫu tín hiệu đầu vào thử nghiệm
│   ├── expected_output.mem      # Đáp án chuẩn do Golden Model tính toán
│   ├── test_config.md          # Specification chi tiết về dữ liệu
│   └── generate_test_data.py   # Script sinh dữ liệu kiểm thử
├── rtl/                        # Mã nguồn Verilog HDL (TV2)
│   ├── audio_equalizer_top.v   # Top-level module
│   ├── fir_filter.v            # Parametric 31-tap FIR Filter
│   ├── bass_filter.v           # Wrapper Low-pass Filter
│   ├── mid_filter.v            # Wrapper Band-pass Filter
│   ├── treble_filter.v         # Wrapper High-pass Filter
│   ├── gain_control.v          # Q8.8 Gain Multiplier & Saturation
│   ├── mixer.v                 # 18-bit 3-Band Adder
│   └── saturation.v            # Module xén biên Signed 16-bit
├── tb/                         # Testbench mô phỏng Verilog (TV3)
│   └── tb_audio_equalizer.v    # Verilog Testbench tự động đối chiếu
├── docs/                       # Tài liệu báo cáo & Specification
│   ├── RTL_INTERFACE_CONTRACT.md
│   └── FINAL_REPORT.md         # Báo cáo kỹ thuật cuối kỳ hoàn chỉnh
└── README.md                   # Tài liệu hướng dẫn dự án
