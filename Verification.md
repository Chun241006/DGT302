# Verification — Hoang Nguyen

## Objective
Verify the supplied three-band audio equalizer RTL against integer expected outputs. Verification covers FIR state progression, fixed-point arithmetic, gain, mixing, saturation, reset, and sample-valid handling.

## Method
The file-driven testbench instantiates `audio_equalizer_top`. Inputs and gains are driven on falling clock edges. Results are sampled 1 ns after rising edges, allowing nonblocking FIR register updates and combinational gain/mixer logic to settle. Clock period is 10 ns; this is a simulation clock, not the 48 kHz audio sampling rate. Valid strobes determine sample acceptance.

The scoreboard checks `valid_out == (!rst && valid_in)` each vector cycle for the supplied implementation. Every valid sample is compared exactly with the expected signed 16-bit value. Reset cycles also require zero output. Case-inequality detects unknown outputs. Invalid cycles do not require a particular output value because gains are combinational. Per-cycle valid checking detects missing and extra transactions. File validation, nonempty sample checks and a simulation watchdog prevent false completion.

## Reference arithmetic
The generator uses signed Q1.15 coefficients and 31 sample taps. It computes exact integer FIR sums, arithmetic right shifts by 15 and clips to [-32768, 32767]. Each signed Q8.8 gain product is shifted right by 8 and clipped again. The three gained bands are summed and clipped at the final output. Python signed right shifts match the floor behavior of Verilog arithmetic right shifts, including negative products. History advances only for accepted samples and is cleared by reset.

## Test plan
| Case | Purpose |
|---|---|
| Zero | Detect unwanted nonzero output |
| Impulse | Exercise tap order and 31-sample history |
| Individual bands | Isolate each band with other gains zero |
| Mute | Require zero mixed output |
| Fractional and negative gains | Exercise scaling and signed shifts |
| High gain and extreme samples | Exercise clipping paths |
| Random samples and gains | Broaden arithmetic combinations |
| Valid gaps | Verify history only advances on valid samples |
| Reset during traffic | Verify state clearing and output invalidation |
| Tail and idle | Exercise residual state and absence of extra outputs |

## Results and limitations
Status: RTL SIMULATION NOT RUN in the creation environment; no ModelSim/Icarus installation was available. The delivered synthetic vector set contains 2114 cycles and 1777 accepted samples. These counts describe generated stimulus, not successful RTL comparisons. Replace this paragraph with actual simulator counts and attach generated logs and waveform screenshots after execution.

Default coefficients are synthetic verification fixtures. They do not establish audio frequency response, crossover quality, or compliance with DSP goals. Final project sign-off requires the DSP owner's approved coefficients and independently generated input/expected vectors, then a successful ModelSim run. The included integer reference is a support model based on the arithmetic contract; it is not a substitute for validating the team's DSP design.

## Evidence to submit
Attach `test_results.txt`, `results.csv`, simulator transcript and waveform screenshots. Report tested coefficient source, vector source, number of compared samples, mismatch count, and simulator version. A passing fixture run must be identified as fixture verification.
