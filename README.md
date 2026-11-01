# Digital Audio Equalizer in Verilog HDL

[![Language](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Target-FPGA](https://img.shields.io/badge/Target-FPGA%20%2F%20Simulation-orange.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A hardware-implemented **Digital Audio Equalizer (EQ)** designed in Verilog HDL. This project filters and shapes digital audio signals across multiple frequency bands using fixed-point digital signal processing (DSP) techniques.

---

## 📌 Features

- **Multi-band Processing:** Splits incoming audio into distinct frequency bands (e.g., Bass, Mid-range, Treble) for independent gain control.
- **Hardware DSP Pipeline:** Implemented using pipelined fixed-point arithmetic (FIR/IIR filters) for low-latency, real-time throughput.
- **Audio Protocol Support:** Compatible with standard digital audio interfaces (e.g., I2S protocol / PCM data stream).
- **Gain & Attenuation Control:** Dynamic gain adjustments per band via register configurations or hardware switches.
- **Modular Architecture:** Clean separation between audio ingestion, filter bank, gain control, summing stage, and output DAC/PWM interface.

---

## 🏗️ Architecture & Block Diagram

```text
               +--------------------------------------------+
               |        Digital Audio Equalizer Top         |
               |                                            |
 Audio In ===> |  +---------+   +-------------------+       |
 (I2S / PCM)   |  | I2S Rx  |-->|  Low-Pass Filter  |--+    |
               |  +---------+   +-------------------+  |    |
               |       |                               |    |
               |       |        +-------------------+  v    |
               |       +------->| Band-Pass Filter  |==[+] ===> Audio Out
               |       |        +-------------------+  ^    |   (I2S / DAC)
               |       |                               |    |
               |       |        +-------------------+  |    |
               |       +------->| High-Pass Filter  |--+    |
               |                +-------------------+       |
               |                          ^                 |
 Gain Controls | -------------------------+                 |
               +--------------------------------------------+
