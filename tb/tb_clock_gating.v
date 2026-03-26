`timescale 1ns / 1ps

module tb_clock_gating;
    reg clk_in;
    reg reset_n;
    reg [7:0] data_bus;
    reg scan_en;
    wire clk_gated;

    // Instantiate the Controller
    clock_gating_controller uut (
        .clk_in(clk_in),
        .reset_n(reset_n),
        .data_bus(data_bus),
        .scan_en(scan_en),
        .clk_gated(clk_gated)
    );

    // Generate 100MHz System Clock
    always #5 clk_in = ~clk_in;

    initial begin
        $dumpfile("runs/clock_gating.vcd");
        $dumpvars(0, tb_clock_gating);

        // System Initialization
        clk_in   = 0;
        reset_n  = 0;
        scan_en  = 0;
        data_bus = 8'h00;

        // Apply Reset
        #15 reset_n = 1;

        // Phase 1: Active Data Transfer (Clock should run)
        #10 data_bus = 8'hAA;
        #10 data_bus = 8'hBB;
        #10 data_bus = 8'hCC;

        // Phase 2: System Goes Idle (Data stops changing)
        // We stay at 0xCC for more than 10 cycles (100ns)
        #150; 

        // Phase 3: Sudden Wake-up (New data arrives)
        #10 data_bus = 8'hDD;
        
        // Phase 4: DFT Scan Test (Force clock on despite idle)
        #50;
        scan_en = 1;

        #50;
        $display("Verification Complete: Check GTKWave for glitch-free clock gating.");
        $finish;
    end
endmodule

