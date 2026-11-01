`timescale 1ns/1ps
// Parameterized 31-tap (default) FIR filter.
// Samples: signed 16-bit. Coefficients: signed Q1.15 in a $readmemh file.
// Accumulation: signed 37-bit, arithmetic shift right by 15 (truncate),
// then saturate to signed 16-bit. Synchronous active-high reset.
// On each valid_in edge, sample_in is tap 0 and prior valid samples form taps 1..N-1.
module fir_filter #(
    parameter integer NUM_TAPS = 31,
    parameter COEFF_FILE = "dsp/coefficients/bass_coeff.mem"
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] sample_in,
    output reg                valid_out,
    output reg  signed [15:0] sample_out
);
    reg signed [15:0] coeff_mem [0:NUM_TAPS-1];
    reg signed [15:0] delay_line [0:NUM_TAPS-2];
    reg signed [31:0] products [0:NUM_TAPS-1];
    reg signed [36:0] accumulator;
    reg signed [36:0] scaled;
    integer i_comb;
    integer i_seq;

    initial begin
        $readmemh(COEFF_FILE, coeff_mem);
    end

    // Combinational FIR sum. Each 16x16 signed product is exactly 32 bits;
    // explicitly sign-extend each product before adding into 37-bit accumulator.
    always @* begin
        for (i_comb = 0; i_comb < NUM_TAPS; i_comb = i_comb + 1) begin
            if (i_comb == 0)
                products[i_comb] = $signed(sample_in) * $signed(coeff_mem[i_comb]);
            else
                products[i_comb] = $signed(delay_line[i_comb-1]) * $signed(coeff_mem[i_comb]);
        end

        accumulator = 37'sd0;
        for (i_comb = 0; i_comb < NUM_TAPS; i_comb = i_comb + 1)
            accumulator = accumulator + {{5{products[i_comb][31]}}, products[i_comb]};

        scaled = accumulator >>> 15;
    end

    function signed [15:0] saturate16;
        input signed [36:0] value;
        begin
            if (value > 37'sd32767)
                saturate16 = 16'sd32767;
            else if (value < -37'sd32768)
                saturate16 = -16'sd32768;
            else
                saturate16 = value[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            for (i_seq = 0; i_seq < NUM_TAPS-1; i_seq = i_seq + 1)
                delay_line[i_seq] <= 16'sd0;
            sample_out <= 16'sd0;
            valid_out  <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                sample_out <= saturate16(scaled);
                for (i_seq = NUM_TAPS-2; i_seq > 0; i_seq = i_seq - 1)
                    delay_line[i_seq] <= delay_line[i_seq-1];
                delay_line[0] <= sample_in;
            end
        end
    end
endmodule
