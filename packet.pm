mdp
const int p1 = 3;
const int N = 10;
global count  : [0..N] init 0;

module RouterA
	A_in1  : [0..N] init 2;
	A_in2  : [0..N] init 2;
	A_out1 : [0..N] init 0;
	A_out2 : [0..N] init 0;
	proceed: [0..2] init 0;//1 is B 2 is C
	
	//Movement from input to output queue
	[A_in_out] A_in1 > 0 & A_out2 > 0 -> (A_in1' = A_in2) & (A_in2' = 0); 
	[A_in_out] A_in1 > 0 & A_out2 = 0 & A_out1 = 0 -> (A_in1' = A_in2) & (A_in2' = 0) & (A_out1' = A_in1); 
	[A_in_out] A_in1 > 0 & A_out2 = 0 & A_out1 > 0 -> (A_in1' = A_in2) & (A_in2' = 0) & (A_out2' = A_in1); 
	
	[BA_Sync] B_out1 = 1 & A_in2 = 0 & A_in1 = 0 -> (A_in1' = B_out1);
	[BA_Sync] B_out1 = 1 & A_in2 = 0 & A_in1 > 0 -> (A_in2' = B_out1);
	[BA_Sync] B_out1 = 1 & A_in2 > 0 & A_in1 > 0 -> (A_in2' = A_in2);
	
	[CA_Sync] C_out1 = 1 & A_in2 = 0 & A_in1 = 0 -> (A_in1' = C_out1);
	[CA_Sync] C_out1 = 1 & A_in2 = 0 & A_in1 > 0 -> (A_in2' = C_out1);
	[CA_Sync] C_out1 = 1 & A_in2 > 0 & A_in1 > 0 -> (A_in2' = A_in2);
	
	[AB_Sync] A_out1 = 2 & proceed = 1-> (A_out1' = A_out2) & (A_out2' = 0) & (proceed' = 0);
	[AC_Sync] A_out1 = 2 & proceed = 2-> (A_out1' = A_out2) & (A_out2' = 0) & (proceed' = 0);
	
	[] A_out1 = 2 & proceed = 0 -> 0.7:(proceed' = 1) + 0.3:(proceed'= 2);
	 
	[queue_up_A] A_in1 = 0 & A_in2 > 0  -> (A_in1' = A_in2) & (A_in2' =0);
	[queue_up_A] A_out1 = 0 & A_out2 > 0 -> (A_out1' = A_out2) & (A_out2'= 0);
	[] A_out1 = 1 & count <N -> (A_out1' = 0 ) & (count' = count +1);
	
endmodule

module RouterB
	B_in1  : [0..N] init 1;
	B_in2  : [0..N] init 1;
	B_out1 : [0..N] init 0;
	B_out2 : [0..N] init 0;
	proceed_B: [0..2] init 0;//1 is A 2 is C
		
	//Movement from input to output queue
	[B_in_out] B_in1 > 0 & B_out2 > 0 -> (B_in1' = A_in2) & (B_in2' = 0); 
	[B_in_out] B_in1 > 0 & B_out2 = 0 & B_out1 = 0 -> (B_in1' = B_in2) & (B_in2' = 0) & (B_out1' = B_in1); 
	[B_in_out] B_in1 > 0 & B_out2 = 0 & B_out1 > 0 -> (B_in1' = B_in2) & (B_in2' = 0) & (B_out2' = B_in1); 

	[BA_Sync] B_out1 = 1 & proceed_B = 1-> (B_out1' = B_out2) & (B_out2' = 0) & (proceed_B' = 0);

	[AB_Sync] A_out1 = 2 & B_in2 = 0 & B_in1 = 0 -> (B_in1' = A_out1);
	[AB_Sync] A_out1 = 2 & B_in2 = 0 & B_in1 > 0 -> (B_in2' = A_out1);
	[AB_Sync] A_out1 = 2 & B_in2 > 0 & B_in1 >0 -> (B_in2' = B_in2);

	[CB_Sync] C_out1 = 2 & B_in2 = 0 & B_in1 = 0 -> (B_in1' = C_out1);
	[CB_Sync] C_out1 = 2 & B_in2 = 0 & B_in1 > 0 -> (B_in2' = C_out1);
	[CB_Sync] C_out1 = 2 & B_in2 > 0 & B_in1 >0 -> (B_in2' = B_in2);
	
	[BC_Sync] B_out1 = 1 & proceed_B = 2-> (B_out1' = B_out2) & (B_out2' = 0) & (proceed_B' = 0);
	
	[] B_out1 = 1 & proceed_B = 0 -> 0.3:(proceed_B' = 1) + 0.7:(proceed_B'= 2);
	
	[queue_up_B] B_in1 = 0 & B_in2 > 0  -> (B_in1' = B_in2) & (B_in2' = 0);
	[queue_up_B] B_out1 = 0 & B_out2 > 0 -> (B_out1' = B_out2) & (B_out2' = 0);
	[] B_out1 = 2 & count <N ->  (B_out1' = 0) & (count' = count +1 );


endmodule

module RouterC
	C_in1  : [0..N] init 0;
	C_in2  : [0..N] init 0;
	C_out1 : [0..N] init 0;
	C_out2 : [0..N] init 0;
	C_count : [0..N] init 0;

	//Movement from input to output queue
	[C_in_out] C_in1 > 0 & C_out2 > 0 -> (C_in1' = C_in2) & (C_in2' = 0); 
	[C_in_out] C_in1 > 0 & C_out2 = 0 & C_out1 = 0 -> (C_in1' = C_in2) & (C_in2' = 0) & (C_out1' = C_in1); 
	[C_in_out] C_in1 > 0 & C_out2 = 0 & C_out1 > 0 -> (C_in1' = C_in2) & (C_in2' = 0) & (C_out2' = C_in1); 

	[queue_up_C] C_in1 = 0 & C_in2 > 0   -> (C_in1' = C_in2) & (C_in2' = 0);
	[queue_up_C] C_out1 = 0 & C_out2 > 0 -> (C_out1' = C_out2) & (C_out2' = 0);

	[AC_Sync] A_out1 = 2 & C_in2 = 0 & C_in1 = 0 & (C_count <N) -> (C_in1' = A_out1) & (C_count' = C_count+1);
	[AC_Sync] A_out1 = 2 & C_in2 = 0 & C_in1 >0  & (C_count <N) -> (C_in2' = A_out1) & (C_count' = C_count+1);
	[AC_Sync] A_out1 = 2 & C_in2 > 0 & C_in1 >0 -> (C_in2' = C_in2);
	
	[BC_Sync] B_out1 = 1 & C_in2 = 0 & C_in1 = 0 & (C_count <N) -> (C_in1' = B_out1) & (C_count' = C_count+1);
	[BC_Sync] B_out1 = 1 & C_in2 = 0 & C_in1 > 0 & (C_count <N) -> (C_in2' = B_out1) & (C_count' = C_count+1);
	[BC_Sync] B_out1 = 1 & C_in2 > 0 & C_in1 > 0 -> (C_in2' = C_in2);
	
	[CA_Sync] C_out1 = 1 -> (C_out1' = C_out2) & (C_out2' = 0);
	[CB_Sync] C_out1 = 2 -> (C_out1' = C_out2) & (C_out2' = 0);
endmodule

// system RouterA ||| RouterB ||| RouterC endsystem

rewards
	A_in1+B_in1+C_in1+A_out1+B_out1+C_out1 = 0: count;
	true:0;
endrewards