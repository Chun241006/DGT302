`timescale 1ns/1ps
// Signed Q8.8 gain: 16'sd256 = unity (1.0).
// Multiply full precision, arithmetic shift by 8 (truncate), saturate to int16.
module gain_control (
    input  wire signed [15:0] sample_in,
    input  wire signed [15:0] gain_q8_8,
    output wire signed [15:0] sample_out
);
    wire signed [31:0] product = $signed(sample_in) * $signed(gain_q8_8);
    wire signed [31:0] scaled = product >>> 8;

    assign sample_out =
        (scaled > 32'sd32767)  ? 16'sd32767 :
        (scaled < -32'sd32768) ? -16'sd32768 :
                                 scaled[15:0];
endmodule
