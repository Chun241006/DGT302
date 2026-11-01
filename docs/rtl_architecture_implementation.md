# RTL Architecture, Implementation and Simulation Results

## 1. RTL Architecture

The Digital Audio Equalizer is a three-band audio processing system implemented in Verilog HDL. It processes signed 16-bit PCM samples through three parallel FIR filtering paths: Bass, Mid, and Treble.

Each filtering path consists of a 31-tap FIR filter followed by an independent gain control module. The three processed signals are combined using a signed 18-bit mixer, followed by a saturation module that produces the final signed 16-bit PCM output.

The system contains eight RTL source modules: `fir_filter`, `bass_filter`, `mid_filter`, `treble_filter`, `gain_control`, `mixer`, `saturation`, and `audio_equalizer_top`.

## 2. RTL Implementation

### 2.1 FIR Filter

The FIR filter uses 31 coefficients stored in external hexadecimal memory files and loaded using `$readmemh`.

The filtering operation is defined as:

\[
y[n] = \sum_{k=0}^{30} h[k]x[n-k]
\]

Each input sample and coefficient is represented using signed 16-bit values. The coefficients use Q1.15 fixed-point representation.

Each multiplication produces a signed 32-bit result. The products are sign-extended and accumulated in a signed 37-bit accumulator to reduce the risk of intermediate overflow.

The accumulated result is arithmetically shifted right by 15 bits and saturated to the signed 16-bit range.

The delay line is updated only when `valid_in` is asserted. During invalid cycles, the stored sample history is preserved.

### 2.2 Gain Control

The gain control module applies an independent signed Q8.8 gain to each frequency band.

A gain value of 256 represents unity gain (1.0).

The gain operation is:

\[
y_{\text{gain}} = \operatorname{sat16}((x \times G) \gg 8)
\]

The module uses a signed 32-bit multiplication, an arithmetic right shift by 8 bits, and 16-bit saturation.

### 2.3 Mixer

The mixer combines the three gain-adjusted frequency bands.

\[
y_{\text{mix}} = y_{\text{bass}} + y_{\text{mid}} + y_{\text{treble}}
\]

Each signed 16-bit input is sign-extended to 18 bits before summation.

The 18-bit output width is sufficient to represent the sum of three signed 16-bit values without intermediate overflow.

### 2.4 Saturation

The final saturation module converts the signed 18-bit mixed signal into signed 16-bit PCM output.

Values greater than 32767 are clamped to 32767, while values below -32768 are clamped to -32768.

This prevents output wraparound when the combined signal exceeds the representable 16-bit range.

### 2.5 Reset and Valid Timing

The FIR filters implement synchronous active-high reset.

When reset is asserted at a rising clock edge, the delay lines, registered outputs, and valid signals are cleared.

During normal operation, each valid input sample is processed at a rising clock edge. The registered FIR output and `valid_out` are updated on that edge.

The gain control, mixer, and final saturation stages are combinational.

When `valid_in` is low, the FIR history and registered sample output remain unchanged, while `valid_out` is deasserted.

## 3. Verification Methodology

The RTL implementation was verified using ModelSim Intel FPGA Edition 2020.1 and a Python Golden Model.

The Golden Model performs the same fixed-point FIR filtering, gain multiplication, mixing, and saturation operations as the RTL implementation.

The testbench reads input samples from `data/input_samples.mem` and expected outputs from `data/expected_output.mem`.

The verification covers continuous input samples, inserted valid gaps, and reset recovery.

All three gain inputs were configured to unity gain (Q8.8 = 256).

## 4. Simulation Results

| Test Scenario | Compared Samples | Mismatches | Result |
|---|---:|---:|---|
| Continuous input | 1010 | 0 | PASS |
| Valid gaps | 1010 | 0 | PASS |
| Reset recovery | 1 | 0 | PASS |
| **Total** | **2021** | **0** | **PASS** |

RTL compilation completed with zero errors and zero warnings.

The Python Golden Model was regenerated successfully. A SHA-256 comparison confirmed that the generated expected output was identical to the previously stored reference file.

Waveform screenshots demonstrate input and output signal behavior during continuous sampling and valid-gap scenarios.

**Figure 1:** `docs/images/waveform_continuous.png`

**Figure 2:** `docs/images/waveform_valid_gaps.png`

## 5. Conclusion

The 31-tap Digital Audio Equalizer RTL successfully passed the supplied Golden Model verification.

All 2021 compared output samples matched the expected results, with zero mismatches.

The tested implementation correctly handled continuous valid inputs, inserted valid gaps, and reset recovery under unity-gain conditions.

Additional verification with non-unity gains and further boundary-value scenarios would improve overall test coverage.