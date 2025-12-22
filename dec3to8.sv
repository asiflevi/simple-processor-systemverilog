// -----------------------------------------------------------------------------
// 3-to-8 decoder
// -----------------------------------------------------------------------------
module dec3to8 (
    input  logic [2:0] W,
    input  logic       En,
    output logic [7:0] Y
);

    // Combinational block: convert @(W or En) → always_comb
    always_comb begin
        if (En) begin
            unique case (W)
                3'b111: Y = 8'b1000_0000;
                3'b110: Y = 8'b0100_0000;
                3'b101: Y = 8'b0010_0000;
                3'b100: Y = 8'b0001_0000;
                3'b011: Y = 8'b0000_1000;
                3'b010: Y = 8'b0000_0100;
                3'b001: Y = 8'b0000_0010;
                default: Y = 8'b0000_0001;   // 3'b000
            endcase
        end
        else
            Y = 8'b0;
    end

endmodule
