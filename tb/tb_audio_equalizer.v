`timescale 1ns/1ps
// Hoang Nguyen - verification against the supplied team's Golden Model.
// Run from project root; expected files and fixed unity gains match golden_model.py.
module tb_audio_equalizer;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, valid_in = 0;
    reg signed [15:0] sample_in = 0;
    reg signed [15:0] gain_bass_q8_8 = 16'sd256;
    reg signed [15:0] gain_mid_q8_8 = 16'sd256;
    reg signed [15:0] gain_treble_q8_8 = 16'sd256;
    wire valid_out;
    wire signed [15:0] sample_out;
    audio_equalizer_top dut (
        .clk(clk), .rst(rst), .valid_in(valid_in), .sample_in(sample_in),
        .gain_bass_q8_8(gain_bass_q8_8), .gain_mid_q8_8(gain_mid_q8_8),
        .gain_treble_q8_8(gain_treble_q8_8), .valid_out(valid_out), .sample_out(sample_out)
    );
    integer in_fd, exp_fd, log_fd, csv_fd;
    integer n_in, n_exp, parsed_in, parsed_exp, pass_id, idx, count, total, errors, pass_errors;
    reg [1023:0] in_line, exp_line;
    reg [15:0] input_word, expected_word;
    reg [15:0] last_expected, first_expected;
    reg last_valid;
    initial begin
        $dumpfile("simulation/results/waveform.vcd");
        $dumpvars(0, tb_audio_equalizer);
        log_fd = $fopen("simulation/results/test_results.txt", "w");
        csv_fd = $fopen("simulation/results/results.csv", "w");
        if (!log_fd || !csv_fd) $fatal(1, "Cannot create logs: make simulation/results first");
        $fdisplay(csv_fd, "test,sample_index,input_hex,expected_hex,actual_hex,status");
        errors = 0; total = 0; first_expected = 0; last_expected = 0; last_valid = 0;
        // Both passes start with reset, so the same model output applies.
        for (pass_id=0; pass_id<2; pass_id=pass_id+1) begin
            in_fd = $fopen("data/input_samples.mem", "r");
            exp_fd = $fopen("data/expected_output.mem", "r");
            if (!in_fd || !exp_fd) $fatal(1, "Missing input or expected file in data/");
            @(negedge clk); rst=1; valid_in=0; sample_in=0;
            repeat (2) begin
                @(posedge clk); #1;
                if (valid_out !== 1'b0 || sample_out !== 16'h0000) begin
                    errors=errors+1; $fdisplay(log_fd,"FAIL reset pass=%0d", pass_id);
                end
            end
            @(negedge clk); rst=0;
            idx=0; pass_errors=errors;
            begin : read_loop
                forever begin
                    in_line=0; exp_line=0;
                    n_in=$fgets(in_line,in_fd); n_exp=$fgets(exp_line,exp_fd);
                    if (n_in==0 && n_exp==0) disable read_loop;
                    if (n_in==0 || n_exp==0) $fatal(1,"Input/expected line count differs at sample %0d",idx);
                    parsed_in=$sscanf(in_line,"%h",input_word);
                    parsed_exp=$sscanf(exp_line,"%h",expected_word);
                    if (parsed_in!=1 || parsed_exp!=1 || (^input_word===1'bx) || (^expected_word===1'bx))
                        $fatal(1,"Invalid or X/Z data at sample %0d",idx);
                    // Insert gaps in pass 1, while retaining FIR history.
                    if (pass_id==1 && idx%7==0) begin
                        @(negedge clk); valid_in=0; sample_in=~input_word;
                        @(posedge clk); #1;
                        if (valid_out !== 1'b0) begin
                            errors=errors+1; $fdisplay(log_fd,"FAIL extra output during gap before sample %0d",idx);
                        end
                    end
                    @(negedge clk); valid_in=1; sample_in=input_word;
                    @(posedge clk); #1;
                    total=total+1;
                    if (valid_out !== 1'b1 || sample_out !== expected_word) begin
                        errors=errors+1;
                        $display("FAIL test=%0d sample=%0d input=%h expected=%h actual=%h valid=%b",pass_id,idx,input_word,expected_word,sample_out,valid_out);
                        $fdisplay(log_fd,"FAIL test=%0d sample=%0d input=%h expected=%h actual=%h valid=%b",pass_id,idx,input_word,expected_word,sample_out,valid_out);
                        $fdisplay(csv_fd,"%0d,%0d,%h,%h,%h,FAIL",pass_id,idx,input_word,expected_word,sample_out);
                    end else $fdisplay(csv_fd,"%0d,%0d,%h,%h,%h,PASS",pass_id,idx,input_word,expected_word,sample_out);
                    if (idx==0) first_expected=expected_word;
                    last_expected=expected_word; last_valid=1;
                    idx=idx+1;
                end
            end
            $fclose(in_fd); $fclose(exp_fd);
            if (idx==0) $fatal(1,"No samples in input file");
            @(negedge clk); valid_in=0;
            repeat (3) begin
                @(posedge clk); #1;
                if (valid_out !== 1'b0) begin
                    errors=errors+1; $fdisplay(log_fd,"FAIL extra output after last sample, pass %0d",pass_id);
                end
            end
            count=errors-pass_errors;
            $display("TEST %0d: samples=%0d errors=%0d",pass_id,idx,count);
            $fdisplay(log_fd,"TEST %0d (%s): samples=%0d errors=%0d",pass_id,pass_id==0 ? "continuous" : "valid gaps",idx,count);
        end
        // Reset after nonzero history, then verify first input after reset.
        @(negedge clk); rst=1; valid_in=1; sample_in=16'h7fff;
        @(posedge clk); #1;
        if (valid_out !== 1'b0 || sample_out !== 16'h0000) begin
            errors=errors+1; $fdisplay(log_fd,"FAIL reset asserted with valid input");
        end
        in_fd=$fopen("data/input_samples.mem","r");
        n_in=$fgets(in_line,in_fd); parsed_in=$sscanf(in_line,"%h",input_word); $fclose(in_fd);
        @(negedge clk); rst=0; valid_in=1; sample_in=input_word;
        @(posedge clk); #1;
        total=total+1;
        if (valid_out !== 1'b1 || sample_out !== first_expected) begin
            errors=errors+1; $fdisplay(log_fd,"FAIL first sample after reset expected=%h actual=%h",first_expected,sample_out);
        end
        @(negedge clk); valid_in=0;
        $display("SUMMARY compared=%0d errors=%0d",total,errors);
        $fdisplay(log_fd,"SUMMARY compared=%0d errors=%0d",total,errors);
        if (errors==0) begin $display("OVERALL PASS"); $fdisplay(log_fd,"OVERALL PASS"); end
        else begin $display("OVERALL FAIL"); $fdisplay(log_fd,"OVERALL FAIL"); end
        $fclose(log_fd); $fclose(csv_fd);
        if (errors!=0) $fatal(1,"Verification failed");
        $finish;
    end
    initial begin #1000000; $fatal(1,"Simulation timeout"); end
endmodule
