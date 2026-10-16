`timescale 1ns/1ps
// Saturate a signed input (IN_WIDTH >= 16) to signed 16-bit output.
module saturation #(
    parameter integer IN_WIDTH = 18
)(
    input  wire signed [IN_WIDTH-1:0] data_in,
    output wire signed [15:0]         data_out
);
    localparam signed [IN_WIDTH-1:0] MAX_16 = 32767;
    localparam signed [IN_WIDTH-1:0] MIN_16 = -32768;

    assign data_out =
        (data_in > MAX_16) ? 16'sd32767 :
        (data_in < MIN_16) ? -16'sd32768 :
                             data_in[15:0];
endmodule
