`timescale 1ns / 1ps

module clock_gating_controller (
    input  wire       clk_in,    // Global Source Clock
    input  wire       reset_n,   // Active Low Reset
    input  wire [7:0] data_bus,  // Monitor this bus for activity
    input  wire       scan_en,   // Design-for-Test (DFT) bypass
    output wire       clk_gated  // The power-optimized clock
);

    reg [7:0] prev_data;
    reg [3:0] idle_count;
    reg       internal_en;
    reg       latched_en;

    // ==========================================================
    // BLOCK 1: THE ACTIVITY MONITOR
    // Tracks the data bus. If the data doesn't change for 
    // 10 consecutive clock cycles, it pulls internal_en LOW.
    // ==========================================================
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            prev_data   <= 8'h00;
            idle_count  <= 4'd0;
            internal_en <= 1'b1; // Default to ON
        end else begin
            prev_data <= data_bus;
            
            if (data_bus == prev_data) begin
                // Data hasn't changed, increment counter
                if (idle_count < 4'd10) begin
                    idle_count <= idle_count + 1'b1;
                end else begin
                    internal_en <= 1'b0; // Threshold met, request clock shutdown
                end
            end else begin
                // Data changed! Wake up the system immediately.
                idle_count  <= 4'd0;
                internal_en <= 1'b1;
            end
        end
    end

    // ==========================================================
    // BLOCK 2: THE ICG CELL (Integrated Clock Gating)
    // The Glitch-Free Negative-Edge Latch
    // ==========================================================
    wire final_en = internal_en | scan_en; // scan_en forces clock ON during testing

    always @(clk_in or final_en) begin
        if (~clk_in) begin
            latched_en <= final_en; 
        end
    end

    // ==========================================================
    // BLOCK 3: THE GATING AND-GATE
    // Perfectly synchronized by the latch above.
    // ==========================================================
    assign clk_gated = clk_in & latched_en;

endmodule
