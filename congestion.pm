const int k = 5;
const int H0 = 0;
const int H1 = 1;
const int S0 = 2;
const int S1 = 3;
const int S2 = 4;
const int MAX_VAR_VALUE = 10;
const int NUM_PACKETS = 3;
const int COST_01 = 2;
const int COST_02 = 1;
const int COST_21 = 1;

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


    [h0Step] h0_in_size > 0  & h0_out_size < 1  & ((h0_in_size + 1) < 2) & (h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & (((h0_in_size + 1) + 1) - 1) < MAX_VAR_VALUE  & (h0_pkt_count + 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_out_size'=1) & (h0_in_size'=(((h0_in_size + 1) + 1) - 1)) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=H1) & (h0_in1_port'=h0_in0_port) & (h0_pkt_count'=(h0_pkt_count + 1));
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & (h0_in_size < 2) & (h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) & ((h0_in_size + 1) - 1) < MAX_VAR_VALUE  & (h0_pkt_count + 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_out_size'=1) & (h0_in_size'=((h0_in_size + 1) - 1)) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=H1) & (h0_in1_port'=h0_in0_port) & (h0_pkt_count'=(h0_pkt_count + 1));
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !((h0_in_size + 1) < 2) & (h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & ((h0_in_size + 1) - 1) < MAX_VAR_VALUE  & (h0_pkt_count + 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_out_size'=1) & (h0_in_size'=((h0_in_size + 1) - 1)) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=H1) & (h0_in1_port'=h0_in0_port) & (h0_pkt_count'=(h0_pkt_count + 1));
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !((h0_in_size + 1) < 2) & (h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) & (h0_pkt_count + 1) < MAX_VAR_VALUE  -> (h0_in0_port'=h0_in1_port) & (h0_out_size'=1) & (h0_in_size'=(h0_in_size - 1)) & (h0_out0_port'=1) & (h0_out0_pkt_dst'=H1) & (h0_in0_pkt_dst'=h0_in1_pkt_dst) & (h0_pkt_count'=(h0_pkt_count + 1));
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & (((h0_in_size + 1) - 1) > 0) & ((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & (((h0_in_size + 1) - 1) - 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_in_size'=(((h0_in_size + 1) - 1) - 1)) & (h0_in1_port'=h0_in0_port);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & ((h0_in_size - 1) > 0) & (h0_in_size > 0) & !(h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) -> (h0_in0_port'=h0_in1_port) & (h0_in_size'=((h0_in_size - 1) - 1)) & (h0_in0_pkt_dst'=h0_in1_pkt_dst);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & ((h0_in_size + 1) > 0) & !((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & ((h0_in_size + 1) - 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_in_size'=((h0_in_size + 1) - 1)) & (h0_in1_port'=h0_in0_port);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & (h0_in_size > 0) & !((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) -> (h0_in0_port'=h0_in1_port) & (h0_in_size'=(h0_in_size - 1)) & (h0_in0_pkt_dst'=h0_in1_pkt_dst);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !(((((h0_in_size + 1) - 1) + 1) - 1) > 0) & ((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & ((h0_in_size + 1) - 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_in_size'=((h0_in_size + 1) - 1)) & (h0_in1_port'=h0_in0_port);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !(((((h0_in_size + 1) - 1) + 1) - 1) > 0) & (h0_in_size > 0) & !(h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) -> (h0_in0_port'=h0_in1_port) & (h0_in_size'=(h0_in_size - 1)) & (h0_in0_pkt_dst'=h0_in1_pkt_dst);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !(((((h0_in_size + 1) - 1) + 1) - 1) > 0) & !((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & (h0_in_size < 2) & (h0_in_size + 1) < MAX_VAR_VALUE  -> (h0_in1_pkt_dst'=h0_in0_pkt_dst) & (h0_in_size'=(h0_in_size + 1)) & (h0_in1_port'=h0_in0_port);
    [h0Step] h0_in_size > 0  & h0_out_size < 1  & !(((((h0_in_size + 1) - 1) + 1) - 1) > 0) & !((h0_in_size + 1) > 0) & !(h0_pkt_count < NUM_PACKETS) & !(h0_in_size < 2) -> true;

    [H0_S0_link] h0_out_size > 0 & h0_out0_port = 1 -> (h0_out_size' = h0_out_size-1);
    
    [S0_H0_link] h0_in_size = 0 & s0_out_size > 0 & s0_out0_port = 3 -> (h0_in0_port' = 1) & (h0_in_size' = h0_in_size+1) & (h0_in0_pkt_dst' = s0_out0_pkt_dst);
    [S0_H0_link] h0_in_size = 1 & s0_out_size > 0 & s0_out0_port = 3 -> (h0_in1_port' = 1) & (h0_in_size' = h0_in_size+1) & (h0_in1_pkt_dst' = s0_out0_pkt_dst);
    [S0_H0_link] h0_in_size = 2 & s0_out_size > 0 & s0_out0_port = 3 -> true;
    

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


    [h1Step] h1_in_size > 0  & h1_out_size < 1  & (h1_in_size > 0) & (h1_pkt_count + 1) < MAX_VAR_VALUE  -> (h1_in_size'=(h1_in_size - 1)) & (h1_in0_port'=h1_in1_port) & (h1_pkt_count'=(h1_pkt_count + 1)) & (h1_in0_pkt_dst'=h1_in1_pkt_dst);
    [h1Step] h1_in_size > 0  & h1_out_size < 1  & !(h1_in_size > 0) & (h1_pkt_count + 1) < MAX_VAR_VALUE  -> (h1_pkt_count'=(h1_pkt_count + 1));

    [H1_S1_link] h1_out_size > 0 & h1_out0_port = 1 -> (h1_out_size' = h1_out_size-1);
    
    [S1_H1_link] h1_in_size = 0 & s1_out_size > 0 & s1_out0_port = 3 -> (h1_in0_port' = 1) & (h1_in_size' = h1_in_size+1) & (h1_in0_pkt_dst' = s1_out0_pkt_dst);
    [S1_H1_link] h1_in_size = 1 & s1_out_size > 0 & s1_out0_port = 3 -> (h1_in1_port' = 1) & (h1_in_size' = h1_in_size+1) & (h1_in1_pkt_dst' = s1_out0_pkt_dst);
    [S1_H1_link] h1_in_size = 2 & s1_out_size > 0 & s1_out0_port = 3 -> true;
    

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
    
    s0_route1: [0..MAX_VAR_VALUE];
    s0_route2: [0..MAX_VAR_VALUE];
    s0_flip_0: [0..1];
    s0HasFlips : bool;

    [s0GenRand] !s0HasFlips -> 1 * (1 / 2) : (s0HasFlips'=true) & (s0_flip_0'=1) + 1 * (1-(1 / 2)) : (s0HasFlips'=true) & (s0_flip_0'=0);

    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & (s0_in0_port = 1) -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=(s0_in_size - 1)) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=3) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & (s0_in0_pkt_dst = H0) & (s0_in0_port = 2) & !(s0_in0_port = 1) -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=(s0_in_size - 1)) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=3) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & !(s0_in0_pkt_dst = H0) & (s0_in0_port = 2) & !(s0_in0_port = 1) -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_in_size'=(s0_in_size - 1)) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=1) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & ((COST_01 < (COST_02 + COST_21)) | ((COST_01 = (COST_02 + COST_21)) & (s0_flip_0 = 1))) & (s0_in0_port = 3) & !(s0_in0_port = 2) & !(s0_in0_port = 1) & (COST_02 + COST_21) < MAX_VAR_VALUE  -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_route1'=COST_01) & (s0_in_size'=(s0_in_size - 1)) & (s0_route2'=(COST_02 + COST_21)) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=1) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & !((COST_01 < (COST_02 + COST_21)) | ((COST_01 = (COST_02 + COST_21)) & (s0_flip_0 = 1))) & (s0_in0_port = 3) & !(s0_in0_port = 2) & !(s0_in0_port = 1) & (COST_02 + COST_21) < MAX_VAR_VALUE  -> (s0_out0_pkt_dst'=s0_in0_pkt_dst) & (s0_route1'=COST_01) & (s0_in_size'=(s0_in_size - 1)) & (s0_route2'=(COST_02 + COST_21)) & (s0_in0_pkt_dst'=s0_in1_pkt_dst) & (s0_out0_port'=2) & (s0_out_size'=1) & (s0_in0_port'=s0_in1_port) & (s0HasFlips'=false);
    [s0Step] s0_in_size > 0  & s0_out_size < 1  & s0HasFlips & !(s0_in0_port = 3) & !(s0_in0_port = 2) & !(s0_in0_port = 1) -> true;

    [S0_H0_link] s0_out_size > 0 & s0_out0_port = 3 -> (s0_out_size' = s0_out_size-1);
    
    [H0_S0_link] s0_in_size = 0 & h0_out_size > 0 & h0_out0_port = 1 -> (s0_in0_port' = 3) & (s0_in_size' = s0_in_size+1) & (s0_in0_pkt_dst' = h0_out0_pkt_dst);
    [H0_S0_link] s0_in_size = 1 & h0_out_size > 0 & h0_out0_port = 1 -> (s0_in1_port' = 3) & (s0_in_size' = s0_in_size+1) & (s0_in1_pkt_dst' = h0_out0_pkt_dst);
    [H0_S0_link] s0_in_size = 2 & h0_out_size > 0 & h0_out0_port = 1 -> true;
    
    [S0_S2_link] s0_out_size > 0 & s0_out0_port = 2 -> (s0_out_size' = s0_out_size-1);
    
    [S2_S0_link] s0_in_size = 0 & s2_out_size > 0 & s2_out0_port = 1 -> (s0_in0_port' = 2) & (s0_in_size' = s0_in_size+1) & (s0_in0_pkt_dst' = s2_out0_pkt_dst);
    [S2_S0_link] s0_in_size = 1 & s2_out_size > 0 & s2_out0_port = 1 -> (s0_in1_port' = 2) & (s0_in_size' = s0_in_size+1) & (s0_in1_pkt_dst' = s2_out0_pkt_dst);
    [S2_S0_link] s0_in_size = 2 & s2_out_size > 0 & s2_out0_port = 1 -> true;
    
    [S0_S1_link] s0_out_size > 0 & s0_out0_port = 1 -> (s0_out_size' = s0_out_size-1);
    
    [S1_S0_link] s0_in_size = 0 & s1_out_size > 0 & s1_out0_port = 1 -> (s0_in0_port' = 1) & (s0_in_size' = s0_in_size+1) & (s0_in0_pkt_dst' = s1_out0_pkt_dst);
    [S1_S0_link] s0_in_size = 1 & s1_out_size > 0 & s1_out0_port = 1 -> (s0_in1_port' = 1) & (s0_in_size' = s0_in_size+1) & (s0_in1_pkt_dst' = s1_out0_pkt_dst);
    [S1_S0_link] s0_in_size = 2 & s1_out_size > 0 & s1_out0_port = 1 -> true;
    

endmodule

module s1
    s1_in0_port: [0..k];
    s1_in0_pkt_dst: [0..k];
    s1_in1_port: [0..k];
    s1_in1_pkt_dst: [0..k];
    s1_out0_port: [0..k];
    s1_out0_pkt_dst: [0..k];
    s1_in_size : [0..2];
    s1_out_size : [0..1];
    
    s1_route1: [0..MAX_VAR_VALUE];
    s1_route2: [0..MAX_VAR_VALUE];
    s1_flip_0: [0..1];
    s1HasFlips : bool;

    [s1GenRand] !s1HasFlips -> 1 * (1 / 2) : (s1HasFlips'=true) & (s1_flip_0'=1) + 1 * (1-(1 / 2)) : (s1HasFlips'=true) & (s1_flip_0'=0);

    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & (s1_in0_port = 1) -> (s1_in0_port'=s1_in1_port) & (s1_in0_pkt_dst'=s1_in1_pkt_dst) & (s1_out_size'=1) & (s1_in_size'=(s1_in_size - 1)) & (s1_out0_pkt_dst'=s1_in0_pkt_dst) & (s1_out0_port'=3) & (s1HasFlips'=false);
    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & (s1_in0_pkt_dst = H1) & (s1_in0_port = 2) & !(s1_in0_port = 1) -> (s1_in0_port'=s1_in1_port) & (s1_in0_pkt_dst'=s1_in1_pkt_dst) & (s1_out_size'=1) & (s1_in_size'=(s1_in_size - 1)) & (s1_out0_pkt_dst'=s1_in0_pkt_dst) & (s1_out0_port'=3) & (s1HasFlips'=false);
    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & !(s1_in0_pkt_dst = H1) & (s1_in0_port = 2) & !(s1_in0_port = 1) -> (s1_in0_port'=s1_in1_port) & (s1_in0_pkt_dst'=s1_in1_pkt_dst) & (s1_out_size'=1) & (s1_in_size'=(s1_in_size - 1)) & (s1_out0_pkt_dst'=s1_in0_pkt_dst) & (s1_out0_port'=1) & (s1HasFlips'=false);
    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & ((COST_01 < (COST_02 + COST_21)) | ((COST_01 = (COST_02 + COST_21)) & (s1_flip_0 = 1))) & (s1_in0_port = 3) & !(s1_in0_port = 2) & !(s1_in0_port = 1) & (COST_02 + COST_21) < MAX_VAR_VALUE  -> (s1_in0_port'=s1_in1_port) & (s1_route1'=COST_01) & (s1_in0_pkt_dst'=s1_in1_pkt_dst) & (s1_out_size'=1) & (s1_route2'=(COST_02 + COST_21)) & (s1_in_size'=(s1_in_size - 1)) & (s1_out0_pkt_dst'=s1_in0_pkt_dst) & (s1_out0_port'=1) & (s1HasFlips'=false);
    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & !((COST_01 < (COST_02 + COST_21)) | ((COST_01 = (COST_02 + COST_21)) & (s1_flip_0 = 1))) & (s1_in0_port = 3) & !(s1_in0_port = 2) & !(s1_in0_port = 1) & (COST_02 + COST_21) < MAX_VAR_VALUE  -> (s1_in0_port'=s1_in1_port) & (s1_route1'=COST_01) & (s1_in0_pkt_dst'=s1_in1_pkt_dst) & (s1_out_size'=1) & (s1_route2'=(COST_02 + COST_21)) & (s1_in_size'=(s1_in_size - 1)) & (s1_out0_pkt_dst'=s1_in0_pkt_dst) & (s1_out0_port'=2) & (s1HasFlips'=false);
    [s1Step] s1_in_size > 0  & s1_out_size < 1  & s1HasFlips & !(s1_in0_port = 3) & !(s1_in0_port = 2) & !(s1_in0_port = 1) -> true;

    [S1_H1_link] s1_out_size > 0 & s1_out0_port = 3 -> (s1_out_size' = s1_out_size-1);
    
    [H1_S1_link] s1_in_size = 0 & h1_out_size > 0 & h1_out0_port = 1 -> (s1_in0_port' = 3) & (s1_in_size' = s1_in_size+1) & (s1_in0_pkt_dst' = h1_out0_pkt_dst);
    [H1_S1_link] s1_in_size = 1 & h1_out_size > 0 & h1_out0_port = 1 -> (s1_in1_port' = 3) & (s1_in_size' = s1_in_size+1) & (s1_in1_pkt_dst' = h1_out0_pkt_dst);
    [H1_S1_link] s1_in_size = 2 & h1_out_size > 0 & h1_out0_port = 1 -> true;
    
    [S1_S2_link] s1_out_size > 0 & s1_out0_port = 2 -> (s1_out_size' = s1_out_size-1);
    
    [S2_S1_link] s1_in_size = 0 & s2_out_size > 0 & s2_out0_port = 2 -> (s1_in0_port' = 2) & (s1_in_size' = s1_in_size+1) & (s1_in0_pkt_dst' = s2_out0_pkt_dst);
    [S2_S1_link] s1_in_size = 1 & s2_out_size > 0 & s2_out0_port = 2 -> (s1_in1_port' = 2) & (s1_in_size' = s1_in_size+1) & (s1_in1_pkt_dst' = s2_out0_pkt_dst);
    [S2_S1_link] s1_in_size = 2 & s2_out_size > 0 & s2_out0_port = 2 -> true;
    
    [S1_S0_link] s1_out_size > 0 & s1_out0_port = 1 -> (s1_out_size' = s1_out_size-1);
    
    [S0_S1_link] s1_in_size = 0 & s0_out_size > 0 & s0_out0_port = 1 -> (s1_in0_port' = 1) & (s1_in_size' = s1_in_size+1) & (s1_in0_pkt_dst' = s0_out0_pkt_dst);
    [S0_S1_link] s1_in_size = 1 & s0_out_size > 0 & s0_out0_port = 1 -> (s1_in1_port' = 1) & (s1_in_size' = s1_in_size+1) & (s1_in1_pkt_dst' = s0_out0_pkt_dst);
    [S0_S1_link] s1_in_size = 2 & s0_out_size > 0 & s0_out0_port = 1 -> true;
    

endmodule

module s2
    s2_in0_port: [0..k];
    s2_in0_pkt_dst: [0..k];
    s2_in1_port: [0..k];
    s2_in1_pkt_dst: [0..k];
    s2_out0_port: [0..k];
    s2_out0_pkt_dst: [0..k];
    s2_in_size : [0..2];
    s2_out_size : [0..1];
    


    [s2Step] s2_in_size > 0  & s2_out_size < 1  & (s2_in0_port = 1) -> (s2_out0_port'=2) & (s2_out_size'=1) & (s2_out0_pkt_dst'=s2_in0_pkt_dst) & (s2_in0_port'=s2_in1_port) & (s2_in0_pkt_dst'=s2_in1_pkt_dst) & (s2_in_size'=(s2_in_size - 1));
    [s2Step] s2_in_size > 0  & s2_out_size < 1  & !(s2_in0_port = 1) -> (s2_out0_port'=1) & (s2_out_size'=1) & (s2_out0_pkt_dst'=s2_in0_pkt_dst) & (s2_in0_port'=s2_in1_port) & (s2_in0_pkt_dst'=s2_in1_pkt_dst) & (s2_in_size'=(s2_in_size - 1));

    [S2_S1_link] s2_out_size > 0 & s2_out0_port = 2 -> (s2_out_size' = s2_out_size-1);
    
    [S1_S2_link] s2_in_size = 0 & s1_out_size > 0 & s1_out0_port = 2 -> (s2_in0_port' = 2) & (s2_in_size' = s2_in_size+1) & (s2_in0_pkt_dst' = s1_out0_pkt_dst);
    [S1_S2_link] s2_in_size = 1 & s1_out_size > 0 & s1_out0_port = 2 -> (s2_in1_port' = 2) & (s2_in_size' = s2_in_size+1) & (s2_in1_pkt_dst' = s1_out0_pkt_dst);
    [S1_S2_link] s2_in_size = 2 & s1_out_size > 0 & s1_out0_port = 2 -> true;
    
    [S2_S0_link] s2_out_size > 0 & s2_out0_port = 1 -> (s2_out_size' = s2_out_size-1);
    
    [S0_S2_link] s2_in_size = 0 & s0_out_size > 0 & s0_out0_port = 2 -> (s2_in0_port' = 1) & (s2_in_size' = s2_in_size+1) & (s2_in0_pkt_dst' = s0_out0_pkt_dst);
    [S0_S2_link] s2_in_size = 1 & s0_out_size > 0 & s0_out0_port = 2 -> (s2_in1_port' = 1) & (s2_in_size' = s2_in_size+1) & (s2_in1_pkt_dst' = s0_out0_pkt_dst);
    [S0_S2_link] s2_in_size = 2 & s0_out_size > 0 & s0_out0_port = 2 -> true;
    

endmodule

