`timescale 1ns/1ps
module tb_proc;

  // Testbench signals
  logic [8:0] DIN;
  logic       Resetn, Clock, Run;
  logic       Done;
  logic [8:0] BusWires;

  // DUT instantiation
  proc dut (
    .DIN      (DIN),
    .Resetn   (Resetn),
    .Clock    (Clock),
    .Run      (Run),
    .BusWires (BusWires),
    .Done     (Done)
  );

  // 20-ns clock
  initial Clock = 0;
  always #10 Clock = ~Clock;

  initial begin
    // 0–20 ns: reset asserted
    Resetn = 0; Run = 0; DIN = 9'o000;
    #20;
    Resetn = 1;  // release reset at 20 ns

    // --- MVI R0,#5 (20–60 ns) ---
    @(negedge Clock); DIN <= 9'o100; Run <= 1;  // ≈20 ns
    @(negedge Clock); DIN <= 9'd5;   Run <= 0;  // ≈40 ns

    // --- MV R1,R0 (60–100 ns) ---
    @(negedge Clock); DIN <= 9'o010; Run <= 1;  // ≈60 ns
    @(negedge Clock);               Run <= 0;  // ≈80 ns

    // --- ADD R0,R1 (100–140 ns) --- changed to is_eq instead.
    @(negedge Clock); DIN <= 9'o201; Run <= 1;  // ≈100 ns
    @(negedge Clock);               Run <= 0;  // ≈120 ns

    // wait through 140 & 160 ns to align SUB at 180 ns
    @(negedge Clock);  // ≈140 ns
    @(negedge Clock);  // ≈160 ns

    // --- SUB R0,R0 (180–200 ns) ---
    @(negedge Clock); DIN <= 9'o300; Run <= 1;  // ≈180 ns
    @(negedge Clock);               Run <= 0; DIN <= 9'o000; // ≈200 ns
	 
	 @(negedge Clock);  // ≈200-220 ns
    @(negedge Clock);  // ≈160 ns
	 
	 @(negedge Clock); DIN <= 9'o410; Run <= 1;  // ≈200 ns
    @(negedge Clock);               Run <= 0; DIN <= 9'o000; // ≈220 ns
	 
	 
	 @(negedge Clock);  // ≈200-220 ns
    @(negedge Clock);  // ≈160 ns
	 
	 @(negedge Clock); DIN <= 9'o501; Run <= 1;  // ≈200 ns
    @(negedge Clock);               Run <= 0; DIN <= 9'o000; // ≈220 ns
	 
	 @(negedge Clock);  // ≈200-220 ns
    @(negedge Clock);  // ≈160 ns
	 
	 // --- MVI R0,#5 (20–60 ns) ---
    @(negedge Clock); DIN <= 9'o110; Run <= 1;  // ≈20 ns
    @(negedge Clock); DIN <= 9'd16;   Run <= 0;  // ≈40 ns
	 
	 @(negedge Clock);  
    @(negedge Clock); 
	 
	 
	 @(negedge Clock); DIN <= 9'o510; Run <= 1;  // ≈200 ns
    @(negedge Clock);               Run <= 0; DIN <= 9'o000; // ≈220 ns
	 
	 
	 @(negedge Clock);  // ≈200-220 ns
    @(negedge Clock);  // ≈160 ns
	 
	 @(negedge Clock); DIN <= 9'o401; Run <= 1;  // ≈200 ns
    @(negedge Clock);               Run <= 0; DIN <= 9'o000; // ≈220 
	 
	 
	
	 
	
    // run on until ~400 ns, then stop
    #280;
    $stop;
  end

  // Live monitor
  initial begin
    $monitor("%0t | Rst=%b Run=%b DIN=%o IR=%o Bus=%h R0=%0h R1=%0h Done=%b",
             $time, Resetn, Run, DIN, dut.IR, BusWires, dut.R0, dut.R1, Done);
  end

endmodule
