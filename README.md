# Digital Audio Equalizer using Verilog HDL

**DGT302 — Digital Signal Processing | 3-Band FIR Digital Audio Equalizer**

This project implements a digital **3-Band Audio Equalizer** using Verilog HDL. The system processes 16-bit signed audio samples through three independent Finite Impulse Response (FIR) filter paths: Bass, Midrange, and Treble. Each frequency band has an independent gain control, allowing the filtered signals to be adjusted and combined into a single audio output.

The design uses **31-tap Type-I Linear Phase FIR filters** with Hamming window coefficients, fixed-point arithmetic, gain control, signal mixing, and saturation protection. A Python reference model is also provided to calculate expected integer outputs for RTL verification.

**Scope:** Digital signal processing architecture, Verilog RTL implementation, fixed-point arithmetic, and simulation-based functional verification. The repository does not claim verified FPGA/ASIC hardware deployment.

---

## 1. System Architecture / Top-Down Design

The equalizer consists of three parallel FIR filter branches. Each branch extracts a different frequency range, applies an independent gain, and sends its output to a common mixer.

```text
                 Input Audio Samples
                   Signed 16-bit
                         |
                         v
              +---------------------+
              |  Audio Equalizer    |
              |      Top Module     |
              +---------------------+
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
    +-----------+  +-----------+  +-----------+
    |   Bass    |  |    Mid    |  |  Treble   |
    |  Low-pass |  | Band-pass |  | High-pass |
    | FIR 31-Tap|  | FIR 31-Tap|  | FIR 31-Tap|
    +-----------+  +-----------+  +-----------+
          |              |              |
          v              v              v
    +-----------+  +-----------+  +-----------+
    | Bass Gain |  |  Mid Gain |  |Treble Gain|
    |   Q8.8    |  |   Q8.8    |  |   Q8.8    |
    +-----------+  +-----------+  +-----------+
          |              |              |
          +--------------+--------------+
                         |
                         v
                  +-------------+
                  |    Mixer    |
                  | 18-bit Sum  |
                  +-------------+
                         |
                         v
                  +-------------+
                  | Saturation  |
                  | Signed 16-bit|
                  +-------------+
                         |
                         v
                  +-------------+
                  | Audio Output|
                  | Signed 16-bit|
                  +-------------+
```

**Top-down implementation:** DSP requirements → FIR filter design → coefficient generation → fixed-point representation → individual RTL modules → top-level integration → Python Golden Model → RTL functional verification.

---

## 2. Key Features

- **3-Band Digital Equalizer:** Independently processes Bass, Midrange, and Treble frequency bands.
- **31-Tap FIR Filters:** Implements Type-I Linear Phase FIR filters with symmetric coefficients and Hamming window design.
- **Independent Gain Control:** Each frequency band has an adjustable signed Q8.8 gain.
- **Fixed-Point Arithmetic:** Uses signed Q1.15 audio samples and filter coefficients, with Q8.8 gain representation.
- **Saturation Protection:** Prevents numerical overflow and wrap-around distortion during filtering, gain multiplication, and signal mixing.
- **Python Golden Model:** Provides an integer-based reference implementation following the fixed-point arithmetic contract.
- **Frequency Response Visualization:** Python scripts generate filter coefficients and frequency response plots for all three bands.

---

## 3. System Specifications

| Property | Implementation |
|---|---|
| Project | Digital Audio Equalizer |
| Course | DGT302 — Digital Signal Processing |
| Language | Verilog HDL |
| Sampling Frequency | 48 kHz |
| Filter Architecture | FIR Type-I Linear Phase |
| Window Function | Hamming Window |
| Number of Taps | 31 per filter |
| Bass Filter | Low-pass, 200 Hz cutoff |
| Mid Filter | Band-pass, 250–3800 Hz |
| Treble Filter | High-pass, 4000 Hz cutoff |
| Input/Output Format | Signed 16-bit Q1.15 |
| Coefficient Format | Signed 16-bit Q1.15 |
| Gain Format | Signed 16-bit Q8.8 |
| FIR Accumulator | Signed 37-bit |
| Gain Accumulator | Signed 32-bit |
| Mixer Accumulator | Signed 18-bit |
| Output Protection | Signed 16-bit Saturation |

**Note:** The listed frequency boundaries represent the filter design parameters. They do not imply ideal brick-wall separation between frequency bands.

---

## 4. RTL Modules

| File | Purpose |
|---|---|
| `rtl/audio_equalizer_top.v` | Integrates the complete 3-band equalizer |
| `rtl/fir_filter.v` | Implements the 31-tap FIR filtering operation |
| `rtl/bass_filter.v` | Bass low-pass filter wrapper |
| `rtl/mid_filter.v` | Midrange band-pass filter wrapper |
| `rtl/treble_filter.v` | Treble high-pass filter wrapper |
| `rtl/gain_control.v` | Applies independent Q8.8 gain and saturation |
| `rtl/mixer.v` | Combines the three processed frequency bands |
| `rtl/saturation.v` | Clips signed values to the 16-bit output range |

---

## 5. Repository Structure

```text
Digital-Audio-Equalizer-Verilog/
│
├── dsp/
│   ├── coefficients/
│   │   ├── bass_coeff.mem
│   │   ├── mid_coeff.mem
│   │   └── treble_coeff.mem
│   │
│   ├── plots/
│   │   ├── bass_response.png
│   │   ├── mid_response.png
│   │   └── treble_response.png
│   │
│   ├── coeff_gen.py
│   └── golden_model.py
│
├── data/
│   ├── input_samples.mem
│   ├── expected_output.mem
│   ├── test_config.md
│   └── generate_test_data.py
│
├── rtl/
│   ├── audio_equalizer_top.v
│   ├── fir_filter.v
│   ├── bass_filter.v
│   ├── mid_filter.v
│   ├── treble_filter.v
│   ├── gain_control.v
│   ├── mixer.v
│   └── saturation.v
│
├── tb/
│   └── tb_audio_equalizer.v
│
├── docs/
│   ├── RTL_INTERFACE_CONTRACT.md
│   └── FINAL_REPORT.md
│
├── results/
├── simulation/
│   └── results/
│
├── Verification.md
└── README.md
```

---

## 6. Fixed-Point Arithmetic Design

The system uses fixed-point arithmetic to represent audio samples, FIR coefficients, and gain values in hardware-friendly integer formats.

### 6.1 FIR Filtering

Each FIR filter performs a multiply-accumulate operation:

\[
y[n]=\sum_{k=0}^{30}h[k]x[n-k]
\]

Where:

- \(x[n]\): Input audio sample.
- \(h[k]\): FIR filter coefficient.
- \(y[n]\): Filtered output sample.

The 37-bit accumulator stores the intermediate sum. The result is shifted right by 15 bits and saturated to signed 16-bit format.

### 6.2 Gain Control

Each frequency band has an independent gain:

\[
y_{\text{gain}}=
\operatorname{sat}_{16}
\left(
\frac{y_{\text{FIR}}\times G}{256}
\right)
\]

The gain uses signed Q8.8 representation.

Unity gain is represented by:

```verilog
16'sd256
```

### 6.3 Signal Mixing

The three processed signals are added together:

\[
y_{\text{mix}}=y_b+y_m+y_t
\]

Where:

- \(y_b\): Bass output after gain.
- \(y_m\): Midrange output after gain.
- \(y_t\): Treble output after gain.

The mixer uses an 18-bit intermediate sum before applying final 16-bit saturation.

### 6.4 Saturation

The final output is limited to the signed 16-bit range:

\[
-32768\leq y_{\text{out}}\leq32767
\]

Saturation prevents numerical overflow from wrapping around and producing incorrect audio sample values.

---

## 7. Python DSP Tools and Golden Model

The project includes Python scripts for FIR coefficient generation and reference output calculation.

### Coefficient Generator

`dsp/coeff_gen.py`

This script:

1. Designs three 31-tap FIR filters using the Hamming window.
2. Generates Bass, Midrange, and Treble coefficients.
3. Converts floating-point coefficients into signed Q1.15 hexadecimal representation.
4. Saves coefficient files in `dsp/coefficients/`.
5. Generates frequency response plots in `dsp/plots/`.

### Python Golden Model

`dsp/golden_model.py`

The Golden Model independently calculates the expected output samples using integer arithmetic.

Its processing sequence is:

1. Load the three FIR coefficient files.
2. Read input audio samples.
3. Perform three FIR multiply-accumulate operations.
4. Apply Q1.15 scaling and saturation.
5. Apply independent Q8.8 gain control.
6. Mix the three frequency bands.
7. Apply final output saturation.
8. Generate `expected_output.mem`.

The reference model follows the fixed-point arithmetic contract used by the RTL design.

---

## 8. Simulation and Verification

### Requirements

- Python 3
- NumPy
- SciPy
- Matplotlib
- ModelSim / QuestaSim or Icarus Verilog

### Step 1 — Install Python Dependencies

Run from the repository root:

```powershell
pip install numpy scipy matplotlib
```

### Step 2 — Generate FIR Coefficients

```powershell
python dsp/coeff_gen.py
```

Generated files:

```text
dsp/coefficients/
├── bass_coeff.mem
├── mid_coeff.mem
└── treble_coeff.mem

dsp/plots/
├── bass_response.png
├── mid_response.png
└── treble_response.png
```

### Step 3 — Generate Expected Output

```powershell
python dsp/golden_model.py
```

The script reads `data/input_samples.mem` and generates:

```text
data/expected_output.mem
```

### Step 4 — Run RTL Simulation

For Icarus Verilog, run from the repository root:

```powershell
iverilog -g2012 -o simulation/equalizer_sim rtl/*.v tb/tb_audio_equalizer.v
vvp simulation/equalizer_sim
```

Alternatively, use ModelSim / QuestaSim:

```powershell
vlib work

vlog rtl/*.v tb/tb_audio_equalizer.v

vsim -c tb_audio_equalizer -do "run -all; quit -f"
```

The testbench uses the generated input and expected output files to check the RTL implementation.

---

## 9. Verification Test Plan

The verification environment covers the following scenarios:

| Test Case | Verification Purpose |
|---|---|
| Zero Input | Checks that zero input produces zero output |
| Impulse Input | Evaluates FIR tap ordering and filter history |
| Individual Bands | Tests each frequency band independently |
| Mute | Checks zero output when all gains are disabled |
| Fractional Gains | Verifies Q8.8 fixed-point multiplication |
| Negative Gains | Checks signed arithmetic behavior |
| High Gain | Tests saturation under large gain values |
| Extreme Samples | Checks numerical boundary conditions |
| Random Samples | Exercises different input and gain combinations |
| Valid Gaps | Checks sample history progression |
| Reset During Traffic | Verifies internal state clearing |
| Tail and Idle | Checks residual filter state and unwanted outputs |

### Verification Method

A file-driven Verilog testbench instantiates the top-level equalizer and compares valid RTL outputs against the expected signed 16-bit reference samples.

The scoreboard checks:

- Output validity.
- Exact sample-by-sample numerical matching.
- Reset behavior.
- Valid sample handling.
- Missing or unexpected output transactions.
- Unknown output values.

The verification fixture contains 2,114 stimulus cycles, including 1,777 accepted samples.

---

## 10. Limitations and Future Improvements

The current project has several limitations:

- The default coefficient files are synthetic verification fixtures and do not establish final audio frequency response or crossover quality.
- The design has not been claimed as a physically verified FPGA or ASIC implementation.
- Actual DSP performance requires validation using approved filter coefficients.
- Functional verification must be completed with the intended simulator before final project sign-off.
- The current architecture focuses on fixed-point digital signal processing rather than a complete audio playback system.

Potential future improvements include:

- Validate the frequency response of all three filters using approved DSP coefficients.
- Implement and test the design on an FPGA platform.
- Integrate an audio input/output interface.
- Add real-time gain adjustment.
- Evaluate audio quality using real audio signals.
- Optimize FIR implementation for hardware resource utilization.

---

## 11. Documentation

Additional project documentation:

- [RTL Interface Contract](docs/RTL_INTERFACE_CONTRACT.md)
- [Final Project Report](docs/FINAL_REPORT.md)
- [Verification Documentation](Verification.md)

---

## 12. Course Information

**Course:** DGT302 — Digital Signal Processing

**Project:** Digital Audio Equalizer using Verilog HDL

**Main Topics:**
- Digital Signal Processing
- FIR Filter Design
- Linear Phase Filters
- Hamming Window
- Fixed-Point Arithmetic
- Digital Audio Processing
- Gain Control and Signal Mixing
- Verilog RTL Design
- Functional Verification

