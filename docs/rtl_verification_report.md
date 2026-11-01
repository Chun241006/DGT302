# RTL Golden Model Verification Report

## Project
Digital Audio Equalizer - 31-tap FIR

## Verification Environment
- Simulator: ModelSim Intel FPGA Edition 2020.1
- Language: Verilog / SystemVerilog Testbench
- Reference: dsp/golden_model.py
- Input: data/input_samples.mem
- Expected output: data/expected_output.mem

## RTL Architecture
- Three parallel FIR filters: Bass, Mid, Treble
- 31 taps per FIR filter
- 16-bit signed input and output
- Coefficients: signed Q1.15
- Gain control: signed Q8.8
- Mixer: signed 18-bit summation
- Saturation: signed 16-bit output
- Active-high synchronous reset

## Verification Results

| Test | Samples | Mismatches | Status |
|---|---:|---:|---|
| Continuous samples | 1010 | 0 | PASS |
| Valid gaps | 1010 | 0 | PASS |
| Reset recovery | 1 | 0 | PASS |
| Total | 2021 | 0 | PASS |

## Golden Model Validation
The Python Golden Model was executed again.
SHA-256 comparison confirmed that expected_output.mem remained unchanged.

## Simulation Artifacts
- simulation/results/console_output.txt
- simulation/results/test_results.txt
- simulation/results/results.csv
- simulation/results/waveform.vcd (local only)

## Conclusion
All 2021 compared output samples matched the supplied Golden Model.
Compilation completed with zero errors and zero warnings.
The tested RTL configuration passed continuous-input, valid-gap,
and reset-recovery verification with unity gains.
