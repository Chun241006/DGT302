`timescale 1ns/1ps
// Three-band digital audio equalizer.
// Input/output samples: signed 16-bit PCM. FIR coefficients: Q1.15, 31 taps.
// Gains: signed Q8.8; 256 means unity gain. Reset: synchronous, active-high.
module audio_equalizer_top #(
    parameter BASS_COEFF_FILE   = "dsp/coefficients/bass_coeff.mem",
    parameter MID_COEFF_FILE    = "dsp/coefficients/mid_coeff.mem",
    parameter TREBLE_COEFF_FILE = "dsp/coefficients/treble_coeff.mem"
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] sample_in,
    input  wire signed [15:0] gain_bass_q8_8,
    input  wire signed [15:0] gain_mid_q8_8,
    input  wire signed [15:0] gain_treble_q8_8,
    output wire               valid_out,
    output wire signed [15:0] sample_out
);
    wire valid_bass, valid_mid, valid_treble;
    wire signed [15:0] bass_filtered, mid_filtered, treble_filtered;
    wire signed [15:0] bass_gained, mid_gained, treble_gained;
    wire signed [17:0] mixed_sample;

    bass_filter #(.COEFF_FILE(BASS_COEFF_FILE)) u_bass (
        .clk(clk), .rst(rst), .valid_in(valid_in), .sample_in(sample_in),
        .valid_out(valid_bass), .sample_out(bass_filtered)
    );
    mid_filter #(.COEFF_FILE(MID_COEFF_FILE)) u_mid (
        .clk(clk), .rst(rst), .valid_in(valid_in), .sample_in(sample_in),
        .valid_out(valid_mid), .sample_out(mid_filtered)
    );
    treble_filter #(.COEFF_FILE(TREBLE_COEFF_FILE)) u_treble (
        .clk(clk), .rst(rst), .valid_in(valid_in), .sample_in(sample_in),
        .valid_out(valid_treble), .sample_out(treble_filtered)
    );

    gain_control u_gain_bass (
        .sample_in(bass_filtered), .gain_q8_8(gain_bass_q8_8), .sample_out(bass_gained)
    );
    gain_control u_gain_mid (
        .sample_in(mid_filtered), .gain_q8_8(gain_mid_q8_8), .sample_out(mid_gained)
    );
    gain_control u_gain_treble (
        .sample_in(treble_filtered), .gain_q8_8(gain_treble_q8_8), .sample_out(treble_gained)
    );

    mixer u_mixer (
        .bass_in(bass_gained), .mid_in(mid_gained), .treble_in(treble_gained),
        .mix_out(mixed_sample)
    );
    saturation #(.IN_WIDTH(18)) u_output_saturation (
        .data_in(mixed_sample), .data_out(sample_out)
    );

    assign valid_out = valid_bass & valid_mid & valid_treble;
endmodule
