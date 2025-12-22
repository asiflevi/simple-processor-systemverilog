// n-bit register with write-enable and active-low asynchronous reset
module regn #(
    parameter int n = 9
) (
    input  logic [n-1:0] R,        // Data input
    input  logic         Rin,      // Write enable
    input  logic         Clock,    // Clock
    input  logic         Resetn,   // Active-low reset
    output logic [n-1:0] Q         // Data output
);

    // On reset, clear register; otherwise on rising edge capture R when enabled
    always_ff @(posedge Clock or negedge Resetn) begin
        if (!Resetn)
            Q <= '0;
        else if (Rin)
            Q <= R;
    end

endmodule
