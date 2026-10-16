`timescale 1ns/1ps
// Sum three signed 16-bit bands without intermediate 16-bit wraparound.
module mixer (
    input  wire signed [15:0] bass_in,
    input  wire signed [15:0] mid_in,
    input  wire signed [15:0] treble_in,
    output wire signed [17:0] mix_out
);
    assign mix_out =
          {{2{bass_in[15]}}, bass_in}
        + {{2{mid_in[15]}}, mid_in}
        + {{2{treble_in[15]}}, treble_in};
endmodule
