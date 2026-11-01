`timescale 1ns/1ps
// Bass band: low-pass FIR, design cutoff 200 Hz at 48 kHz sample rate.
module bass_filter #(
    parameter COEFF_FILE = "dsp/coefficients/bass_coeff.mem"
)(
    input wire clk, input wire rst, input wire valid_in,
    input wire signed [15:0] sample_in,
    output wire valid_out, output wire signed [15:0] sample_out
);
    fir_filter #(.NUM_TAPS(31), .COEFF_FILE(COEFF_FILE)) u_fir (
        .clk(clk), .rst(rst), .valid_in(valid_in), .sample_in(sample_in),
        .valid_out(valid_out), .sample_out(sample_out)
    );
endmodule
