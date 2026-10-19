`timescale 1ns/1ps
// Hoang Nguyen — cycle-based, bit-exact verification for supplied RTL.
module tb_audio_equalizer;
reg clk=0;
always #5 clk=~clk;
reg rst=1, valid_in=0;
reg signed [15:0] sample_in=0;
reg signed [15:0] gain_bass_q8_8=256, gain_mid_q8_8=256, gain_treble_q8_8=256;
wire valid_out;
wire signed [15:0] sample_out;
audio_equalizer_top dut(.clk(clk),.rst(rst),.valid_in(valid_in),.sample_in(sample_in),
.gain_bass_q8_8(gain_bass_q8_8),.gain_mid_q8_8(gain_mid_q8_8),
.gain_treble_q8_8(gain_treble_q8_8),.valid_out(valid_out),.sample_out(sample_out));
integer fd,logfd,csvfd,rc,cycle=0,checked=0,errors=0,r,v;
reg signed [15:0] x,gb,gm,gt,expected;
reg expected_valid;
reg [2047:0] vector_path;
reg [8191:0] line;
integer got_line, row_bad;
initial begin
    vector_path="model/vectors.txt";
    rc=$value$plusargs("VECTORS=%s",vector_path);
    fd=$fopen(vector_path,"r");
    logfd=$fopen("simulation/results/test_results.txt","w");
    csvfd=$fopen("simulation/results/results.csv","w");
    if(fd==0 || logfd==0 || csvfd==0) $fatal(1,"Cannot open input/results files; run from project root");
    $dumpfile("simulation/results/waveform.vcd"); $dumpvars(0,tb_audio_equalizer);
    $fdisplay(csvfd,"cycle,rst,valid_in,input,bass_gain,mid_gain,treble_gain,expected_valid,actual_valid,expected,actual,status");
    while(!$feof(fd)) begin
        got_line=$fgets(line,fd);
        if(got_line!=0) begin
            rc=$sscanf(line,"%d %d %h %h %h %h %h",r,v,x,gb,gm,gt,expected);
            if(rc!=7 || (r!=0 && r!=1) || (v!=0 && v!=1) ||
               (^x===1'bx) || (^gb===1'bx) || (^gm===1'bx) || (^gt===1'bx) || (^expected===1'bx))
                $fatal(1,"Malformed vector row %0d",cycle);
            @(negedge clk);
            rst=r; valid_in=v; sample_in=x;
            gain_bass_q8_8=gb; gain_mid_q8_8=gm; gain_treble_q8_8=gt;
            expected_valid=(!r && v);
            @(posedge clk); #1; // Observe registered FIR and settled combinational chain.
            row_bad=0;
            if(valid_out !== expected_valid) row_bad=1;
            if((r || v) && sample_out !== expected) row_bad=1;
            if(expected_valid) checked=checked+1;
            if(row_bad) begin
                errors=errors+1;
                $display("FAIL cycle=%0d expected=%0d actual=%0d expected_valid=%b actual_valid=%b",cycle,expected,sample_out,expected_valid,valid_out);
                $fdisplay(logfd,"FAIL cycle=%0d expected=%0d actual=%0d expected_valid=%b actual_valid=%b",cycle,expected,sample_out,expected_valid,valid_out);
            end
            $fdisplay(csvfd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%b,%b,%0d,%0d,%0s",cycle,r,v,x,gb,gm,gt,expected_valid,valid_out,expected,sample_out,row_bad ? "FAIL":"PASS");
            cycle=cycle+1;
        end
    end
    if(checked==0) begin errors=errors+1; $fdisplay(logfd,"FAIL: no valid samples checked"); end
    $display("SUMMARY cycles=%0d samples=%0d errors=%0d",cycle,checked,errors);
    $fdisplay(logfd,"SUMMARY cycles=%0d samples=%0d errors=%0d",cycle,checked,errors);
    if(errors==0) begin $display("PASS"); $fdisplay(logfd,"PASS"); end
    else begin $display("FAIL"); $fdisplay(logfd,"FAIL"); end
    $fclose(fd); $fclose(logfd); $fclose(csvfd);
    if(errors!=0) $fatal(1,"Verification failed");
    $finish;
end
initial begin #10000000; $fatal(1,"TIMEOUT"); end
endmodule
