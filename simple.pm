const int k = 3;
const H0 = 0;
const H1 = 1;
const S0 = 2;
const double Pr = 0.7;
const N = 10;
module h0
    h0_in0_port: [-1..k];
    h0_in0_pkt_dst: [0..k];
    h0_in1_port: [0..k];
    h0_in1_pkt_dst: [0..k];
    h0_in2_port: [0..k];
    h0_in2_pkt_dst: [0..k];
    h0_out0_port: [0..k];
    h0_out0_pkt_dst: [0..k];
    h0_out1_port: [0..k];
    h0_out1_pkt_dst: [0..k];
    h0_out2_port: [0..k];
    h0_out2_pkt_dst: [0..k];
    h0_in_size : [0..3];
    h0_out_size : [0..3];
    
    h0_pkt_count: [0..N];
    [h0Step] h0_in_size < 3 & h0_pkt_count < N -> (h0_in2_port'=h0_in1_port) & (h0_in_size'=h0_in_size + 1 - 1) & (h0_out0_port'=1) & (h0_in2_pkt_dst'=h0_in1_pkt_dst) & (h0_out0_pkt_dst'=1) & (h0_pkt_count'=h0_pkt_count + 1);
    [h0Step] !h0_in_size < 3 & h0_pkt_count < N -> (h0_in0_port'=h0_in1_port) & (h0_in1_pkt_dst'=h0_in2_pkt_dst) & (h0_in_size'=h0_in_size - 1) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=1) & (h0_in0_pkt_dst'=h0_in1_pkt_dst) & (h0_in1_port'=h0_in2_port) & (h0_pkt_count'=h0_pkt_count + 1);
endmodule

module s0
    s0_in0_port: [0..k];
    s0_in0_pkt_dst: [0..k];
    s0_in1_port: [0..k];
    s0_in1_pkt_dst: [0..k];
    s0_in2_port: [0..k];
    s0_in2_pkt_dst: [0..k];
    s0_out0_port: [0..k];
    s0_out0_pkt_dst: [0..k];
    s0_out1_port: [0..k];
    s0_out1_pkt_dst: [0..k];
    s0_out2_port: [0..k];
    s0_out2_pkt_dst: [0..k];
    s0_in_size : [0..3];
    s0_out_size : [0..3];
    
    s0_flip_0: [0..1];
    s0_flip_1: [0..1];
    s0HasFlips : bool;
    [s0GenRand] !s0HasFlips -> 1 * (Pr) * (Pr) : (s0HasFlips'=true) & (s0_flip_0'=1) & (s0_flip_1'=1) + 1 * (Pr) * (1-(Pr)) : (s0HasFlips'=true) & (s0_flip_0'=1) & (s0_flip_1'=0) + 1 * (1-(Pr)) * (Pr) : (s0HasFlips'=true) & (s0_flip_0'=0) & (s0_flip_1'=1) + 1 * (1-(Pr)) * (1-(Pr)) : (s0HasFlips'=true) & (s0_flip_0'=0) & (s0_flip_1'=0);
    [s0Step] s0HasFlips & s0_flip_0 = 1 & s0_in0_port = 1 & s0_in_size > 0 -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_in1_port'=s0_in2_port) & (s0_out0_port'=2) & (s0_in0_port'=s0_in1_port) & (s0_in1_pkt_dst'=s0_in2_pkt_dst) & (s0HasFlips'=false);
    [s0Step] s0HasFlips & s0_in_size > 0 & s0_flip_1 = 0 & s0_in0_port = 1 -> (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_in1_port'=s0_in2_port) & (s0_in0_port'=s0_in1_port) & (s0_in1_pkt_dst'=s0_in2_pkt_dst) & (s0HasFlips'=false);
    [s0Step] s0HasFlips & !s0_in_size > 0 & s0_flip_1 = 0 & s0_in0_port = 1 -> (s0HasFlips'=false);
    [s0Step] s0HasFlips & !s0_in0_port = 1 & s0_in_size > 0 -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_in1_port'=s0_in2_port) & (s0_out0_port'=1) & (s0_in0_port'=s0_in1_port) & (s0_in1_pkt_dst'=s0_in2_pkt_dst) & (s0HasFlips'=false);
endmodule

module h1
    h1_in0_port: [0..k];
    h1_in0_pkt_dst: [0..k];
    h1_in1_port: [0..k];
    h1_in1_pkt_dst: [0..k];
    h1_in2_port: [0..k];
    h1_in2_pkt_dst: [0..k];
    h1_out0_port: [0..k];
    h1_out0_pkt_dst: [0..k];
    h1_out1_port: [0..k];
    h1_out1_pkt_dst: [0..k];
    h1_out2_port: [0..k];
    h1_out2_pkt_dst: [0..k];
    h1_in_size : [0..3];
    h1_out_size : [0..3];
    
    s0_pkt_count: [0..N];
    [h1Step] h1_in_size > 0 & s0_pkt_count < N -> (h1_in_size'=h1_in_size - 1) & (h1_in0_port'=h1_in1_port) & (h1_in1_port'=h1_in2_port) & (h1_in1_pkt_dst'=h1_in2_pkt_dst) & (s0_pkt_count'=s0_pkt_count + 1) & (h1_in0_pkt_dst'=h1_in1_pkt_dst);
    [h1Step] !h1_in_size > 0 & s0_pkt_count < N-> (s0_pkt_count'=s0_pkt_count + 1);
endmodule 