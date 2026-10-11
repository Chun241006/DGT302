
# PROJECT SPECIFICATION

## 1. Project Information

Project Title:
Design and Verification of a 3-Band Digital
Audio Equalizer Using Verilog HDL

Course: Digital Signal Processing (DGT302)

Project Type: RTL Design and Verification

Development Tools:
- Visual Studio Code
- Git and GitHub
- Python (NumPy, SciPy)
- Verilog HDL
- ModelSim or compatible Verilog simulator

## 2. Project Overview

This project implements a 3-band digital
audio equalizer using Verilog HDL.

The system separates incoming audio samples
into three frequency bands:

- Bass
- Mid
- Treble

Each band is processed by a digital FIR filter.

The filtered signals are independently scaled
using gain controls and combined to produce
the final audio output.

A Python Golden Model will be developed to
generate reference outputs.

A Verilog Testbench will compare RTL outputs
with the Golden Model.

## 3. System Architecture

Input Audio Samples (16-bit signed)
              |
              +----> Bass FIR Filter ----> Bass Gain ----+
              |                                         |
              +----> Mid FIR Filter -----> Mid Gain -----+----> Mixer
              |                                         |        |
              +----> Treble FIR Filter --> Treble Gain --+        |
                                                                 v
                                                            Saturation
                                                                 |
                                                                 v
                                                        Output Audio Samples
                                                           (16-bit signed)

## 4. Functional Requirements

FR01:
The system shall accept signed 16-bit input samples.

FR02:
The system shall process samples using three FIR filters.

FR03:
The system shall support independent Bass, Mid,
and Treble gain controls.

FR04:
The system shall combine the three processed
signals into one output signal.

FR05:
The output shall be saturated to the signed
16-bit range (-32768 to +32767).

FR06:
The system shall provide valid input and
valid output control signals.

FR07:
The system shall support synchronous sample processing
and reset functionality.

FR08:
The system shall be implemented using Verilog HDL.

FR09:
The RTL shall be verified using a testbench
and a Python Golden Model.

## 5. DSP Design Parameters

Audio sample width: 16-bit signed

Number of bands: 3

Filter types:
- Bass: Low-Pass FIR
- Mid: Band-Pass FIR
- Treble: High-Pass FIR

Sample rate: TBD

Bass cutoff frequency: TBD

Mid passband frequencies: TBD

Treble cutoff frequency: TBD

FIR tap count: TBD

Coefficient quantization: TBD

Fixed-point arithmetic rules: TBD

Gain format: TBD

The DSP designer must finalize these values
after evaluating filter frequency responses.

## 6. RTL Interface

Suggested inputs:

- clk
- rst_n
- sample_valid
- sample_in[15:0] (signed)
- gain_bass
- gain_mid
- gain_treble

Suggested outputs:

- sample_out[15:0] (signed)
- out_valid

The exact width of gain controls,
pipeline latency, and signal timing
must be agreed upon before RTL integration.

## 7. Golden Model Requirements

The Golden Model shall:

- Use the same quantized FIR coefficients as RTL.
- Match the RTL fixed-point arithmetic rules.
- Implement all three filters.
- Implement independent gain controls.
- Implement mixer and saturation.
- Generate expected output samples.
- Support multiple test scenarios.

The Golden Model shall provide a bit-exact
fixed-point reference for RTL verification.

## 8. Testbench Requirements

The testbench shall:

- Generate clock and reset.
- Apply input samples to the DUT.
- Apply gain settings.
- Load Golden Model expected outputs.
- Capture RTL output on out_valid.
- Compare actual and expected samples.
- Report PASS/FAIL for each test case.
- Save verification logs.

## 9. Verification Test Cases

TC01: Zero input

TC02: Bass-frequency sine wave

TC03: Mid-frequency sine wave

TC04: Treble-frequency sine wave

TC05: Multi-tone audio input

TC06: Bass gain boost

TC07: Mid gain boost

TC08: Treble gain boost

TC09: Output saturation

TC10: Reset operation

Test frequencies must be selected after
the sample rate and bands are finalized.

## 10. Project Scope

Included:
- FIR-based audio equalizer
- Three frequency bands
- Independent gain control
- Verilog RTL design
- Python Golden Model
- Verilog Testbench
- Automated RTL/Golden Model comparison
- Simulation results and report

Excluded:
- Physical FPGA implementation
- Microphone and speaker integration
- Real-time analog audio hardware
- Graphical user interface
- Adaptive filtering

## 11. Team Responsibilities

Leader:
- System specification
- Architecture documentation
- Project management
- Report integration

Member 1:
- DSP filter design
- Coefficient generation
- Python Golden Model
- DSP documentation

Member 2:
- Verilog RTL implementation
- Module integration
- RTL simulation and debugging
- RTL documentation

Member 3:
- Testbench implementation
- Verification test cases
- Golden Model comparison
- Verification results documentation

## 12. Project Schedule

Week 5:
- Finalize specification and interfaces
- Develop Golden Model
- Implement basic RTL
- Develop initial Testbench

Week 6:
- Complete integration
- Run verification tests
- Debug mismatches
- Complete report

Week 7:
- Final review
- Submission and presentation

## 13. Acceptance Criteria

The project is considered complete when:

1. RTL compiles successfully.
2. Golden Model produces expected outputs.
3. Testbench runs the required test cases.
4. RTL matches the fixed-point Golden Model.
5. All failures are resolved or documented.
6. Simulation evidence is saved.
7. The project report is completed.
