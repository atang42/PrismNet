const int k = 3;
const int H0 = 0;
const int H1 = 1;
const int S0 = 2;
const int MAX_VAR_VALUE = 10;
const double Pr = 0.7;

module h0
    h0_in0_port: [0..k];
    h0_in0_pkt_dst: [0..k];
    h0_in1_port: [0..k];
    h0_in1_pkt_dst: [0..k];
    h0_out0_port: [0..k];
    h0_out0_pkt_dst: [0..k];
    h0_in_size : [0..2] init 1;
    h0_out_size : [0..1];
    
    h0_pkt_count: [0..MAX_VAR_VALUE];


    [h0Step] h0_in_size > 0  & h0_out_size < 1  & h0_in_size < 2 & h0_in_size + 1 - 1 < MAX_VAR_VALUE  & h0_pkt_count + 1 < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_out_size'=1) & (h0_in_size'=h0_in_size + 1 - 1) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=1) & (h0_in1_port'=h0_in0_port) & (h0_pkt_count'=h0_pkt_count + 1);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !h0_in_size < 2 & h0_pkt_count + 1 < MAX_VAR_VALUE  -> (h0_in0_port'=h0_in1_port) & (h0_out_size'=1) & (h0_in_size'=h0_in_size - 1) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=1) & (h0_in0_pkt_dst'=h0_in1_pkt_dst) & (h0_pkt_count'=h0_pkt_count + 1);

    [H0_S0_link] h0_out_size > 0 & h0_out0_port = 1 -> (h0_out_size' = h0_out_size-1);
    
    [S0_H0_link] h0_in_size = 0 & s0_out_size > 0 & s0_out0_port = 1 -> (h0_in0_port' = 1) & (h0_in_size' = h0_in_size+1) & (h0_in0_pkt_dst' = s0_out0_pkt_dst);
    [S0_H0_link] h0_in_size = 1 & s0_out_size > 0 & s0_out0_port = 1 -> (h0_in0_port' = 1) & (h0_in_size' = h0_in_size+1) & (h0_in1_pkt_dst' = s0_out0_pkt_dst);
    [S0_H0_link] h0_in_size = 2 & s0_out_size > 0 & s0_out0_port = 1 -> true;
    

endmodule

module s0
    s0_in0_port: [0..k];
    s0_in0_pkt_dst: [0..k];
    s0_in1_port: [0..k];
    s0_in1_pkt_dst: [0..k];
    s0_out0_port: [0..k];
    s0_out0_pkt_dst: [0..k];
    s0_in_size : [0..2];
    s0_out_size : [0..1];
    
    s0_flip_0: [0..1];
    s0HasFlips : bool;

    [s0GenRand] !s0HasFlips -> 1 * (Pr) : (s0HasFlips'=true) & (s0_flip_0'=1) + 1 * (1-(Pr)) : (s0HasFlips'=true) & (s0_flip_0'=0);

    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & s0_flip_0 = 1 & s0_in0_port = 1 -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=2) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & s0_in_size > 0 & !s0_flip_0 = 1 & s0_in0_port = 1 -> (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & !s0_in_size > 0 & !s0_flip_0 = 1 & s0_in0_port = 1 -> true;
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & !s0_in0_port = 1 -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=s0_in_size - 1) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=1) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);

    [S0_H1_link] s0_out_size > 0 & s0_out0_port = 2 -> (s0_out_size' = s0_out_size-1);
    
    [H1_S0_link] s0_in_size = 0 & h1_out_size > 0 & h1_out0_port = 1 -> (s0_in0_port' = 2) & (s0_in_size' = s0_in_size+1) & (s0_in0_pkt_dst' = h1_out0_pkt_dst);
    [H1_S0_link] s0_in_size = 1 & h1_out_size > 0 & h1_out0_port = 1 -> (s0_in0_port' = 2) & (s0_in_size' = s0_in_size+1) & (s0_in1_pkt_dst' = h1_out0_pkt_dst);
    [H1_S0_link] s0_in_size = 2 & h1_out_size > 0 & h1_out0_port = 1 -> true;
    
    [S0_H0_link] s0_out_size > 0 & s0_out0_port = 1 -> (s0_out_size' = s0_out_size-1);
    
    [H0_S0_link] s0_in_size = 0 & h0_out_size > 0 & h0_out0_port = 1 -> (s0_in0_port' = 1) & (s0_in_size' = s0_in_size+1) & (s0_in0_pkt_dst' = h0_out0_pkt_dst);
    [H0_S0_link] s0_in_size = 1 & h0_out_size > 0 & h0_out0_port = 1 -> (s0_in0_port' = 1) & (s0_in_size' = s0_in_size+1) & (s0_in1_pkt_dst' = h0_out0_pkt_dst);
    [H0_S0_link] s0_in_size = 2 & h0_out_size > 0 & h0_out0_port = 1 -> true;
    

endmodule

module h1
    h1_in0_port: [0..k];
    h1_in0_pkt_dst: [0..k];
    h1_in1_port: [0..k];
    h1_in1_pkt_dst: [0..k];
    h1_out0_port: [0..k];
    h1_out0_pkt_dst: [0..k];
    h1_in_size : [0..2];
    h1_out_size : [0..1];
    
    h1_pkt_count: [0..MAX_VAR_VALUE];


    [h1Step] h1_in_size > 0  & h1_out_size < 1  & h1_in_size > 0 & h1_pkt_count + 1 < MAX_VAR_VALUE  -> (h1_in_size'=h1_in_size - 1) & (h1_in0_port'=h1_in1_port) & (h1_pkt_count'=h1_pkt_count + 1) & (h1_in0_pkt_dst'=h1_in1_pkt_dst);
    [h1Step] h1_in_size > 0  & h1_out_size < 1  & !h1_in_size > 0 & h1_pkt_count + 1 < MAX_VAR_VALUE  -> (h1_pkt_count'=h1_pkt_count + 1);

    [H1_S0_link] h1_out_size > 0 & h1_out0_port = 1 -> (h1_out_size' = h1_out_size-1);
    
    [S0_H1_link] h1_in_size = 0 & s0_out_size > 0 & s0_out0_port = 2 -> (h1_in0_port' = 1) & (h1_in_size' = h1_in_size+1) & (h1_in0_pkt_dst' = s0_out0_pkt_dst);
    [S0_H1_link] h1_in_size = 1 & s0_out_size > 0 & s0_out0_port = 2 -> (h1_in0_port' = 1) & (h1_in_size' = h1_in_size+1) & (h1_in1_pkt_dst' = s0_out0_pkt_dst);
    [S0_H1_link] h1_in_size = 2 & s0_out_size > 0 & s0_out0_port = 2 -> true;
    

endmodule

