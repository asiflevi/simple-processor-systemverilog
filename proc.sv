// -----------------------------------------------------------------------------
// 9-bit toy processor - ASIF AND ELON  (with IS_EQ added)
// -----------------------------------------------------------------------------
module proc (
    input  logic [8:0] DIN,
    input  logic       Resetn,
    input  logic       Clock,
    input  logic       Run,
    output logic [8:0] BusWires,
    output logic       Done
);

    // -------------------------------------------------------------------------
    // Parameters 
    // -------------------------------------------------------------------------
    parameter int    n      = 9;
    parameter logic  ONE    = 1'b1, ZERO = 1'b0;

    parameter logic [3:0]
        T0   = 4'b0000,
        T1   = 4'b0011,
        T2   = 4'b0101,
        T3   = 4'b1001;

    parameter logic [2:0]
        MV       = 3'b000,
        MVI      = 3'b001,
        ADD      = 3'b010,
        SUB      = 3'b011,
        ONES     = 3'b100,
        SPECIALM = 3'b101,  // Rx * 3.5 → Ry
        IS_EQ    = 3'b110;  // Rx ← (Rx == Ry) ? 1 : 0

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [7:0]   Xreg, Yreg;
    logic [2:0]   I, X, Y;
    logic [n-1:0] IR, A, G;
    logic [n-1:0] R0,R1,R2,R3,R4,R5,R6,R7;
    logic [n-1:0] addsub_out, ones_reg;

    // special datapath
    logic [n-1:0] mult35;
    logic [n-1:0] alu_to_G;

    logic [3:0]   Tstep_Q, Tstep_D;
    logic [7:0]   Rin, Rout;
    logic         ones_in, ones_sum_out;
    logic [$clog2(n+1)-1:0] ones_sum;
    logic         DINout, AddSub, Gout, Gin, Ain, IRin;
    integer       i;

    // Equality (1-bit) + zero-extended n-bit word
    logic         eq_flag;
    logic [n-1:0] eq_word;

    // -------------------------------------------------------------------------
    // Decode fields
    // -------------------------------------------------------------------------
    assign I = IR[8:6];  // opcode
    assign X = IR[5:3];  // Rx index
    assign Y = IR[2:0];  // Ry index

    dec3to8 decX (X, ONE, Xreg);
    dec3to8 decY (Y, ONE, Yreg);

    // -------------------------------------------------------------------------
    // FSM next-state logic
    // -------------------------------------------------------------------------
    always_comb begin
        unique case (Tstep_Q)
            T0: Tstep_D = Run  ? T1 : T0;
            T1: Tstep_D = Done ? T0 : T2;
            T2: Tstep_D = Done ? T0 : T3;
            T3: Tstep_D = T0;
            default: Tstep_D = T0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM output logic (control signals)
    // -------------------------------------------------------------------------
    always_comb begin
        // defaults
        IRin = 0; Ain = 0; Gin = 0; Gout = 0; DINout = 0;
        Rin = '0; Rout = '0; AddSub = 0;
        ones_in = 0; ones_sum_out = 0; Done = 0;

        unique case (Tstep_Q)
            T0: begin
                IRin = 1;
            end

            T1: unique case (I)
                ONES:     begin Rout = Xreg; ones_in = ONE;               end
                MV:       begin Rout = Yreg; Rin = Xreg; Done = ONE;      end
                MVI:      begin DINout = ONE; Rin = Xreg; Done = ONE;     end
                ADD, SUB,
                SPECIALM: begin Rout = Xreg; Ain = ONE;                   end
                IS_EQ:    begin Rout = Xreg; Ain = ONE;                   end
            endcase

            T2: unique case (I)
                ONES:     begin Rin = Yreg; ones_sum_out = ONE; Done = ONE; end
                ADD:      begin Rout = Yreg; Gin = ONE; AddSub = ZERO;      end
                SUB:      begin Rout = Yreg; Gin = ONE; AddSub = ONE;       end
                IS_EQ:    begin Rout = Yreg; Gin = ONE;                     end
                SPECIALM: begin                    Gin = ONE;               end // A already latched
            endcase

            T3: unique case (I)
                ADD, SUB, IS_EQ: begin Gout = ONE; Rin = Xreg; Done = ONE;  end
                SPECIALM:        begin Gout = ONE; Rin = Yreg; Done = ONE;  end
            endcase
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM state register
    // -------------------------------------------------------------------------
    always_ff @(posedge Clock or negedge Resetn) begin
        if (!Resetn)
            Tstep_Q <= T0;
        else
            Tstep_Q <= Tstep_D;
    end

    // -------------------------------------------------------------------------
    // Datapath registers (5-port regn: R, Rin, Clock, Resetn, Q)
    // -------------------------------------------------------------------------
    regn IR_reg    (DIN,       IRin,     Clock, Resetn, IR);
    regn ones_regn (BusWires,  ones_in,  Clock, Resetn, ones_reg);
    regn reg_0     (BusWires,  Rin[0],   Clock, Resetn, R0);
    regn reg_1     (BusWires,  Rin[1],   Clock, Resetn, R1);
    regn reg_2     (BusWires,  Rin[2],   Clock, Resetn, R2);
    regn reg_3     (BusWires,  Rin[3],   Clock, Resetn, R3);
    regn reg_4     (BusWires,  Rin[4],   Clock, Resetn, R4);
    regn reg_5     (BusWires,  Rin[5],   Clock, Resetn, R5);
    regn reg_6     (BusWires,  Rin[6],   Clock, Resetn, R6);
    regn reg_7     (BusWires,  Rin[7],   Clock, Resetn, R7);
    regn A_reg     (BusWires,  Ain,      Clock, Resetn, A);

    // -------------------------------------------------------------------------
    // ALU: add/sub, SPECIALM (A*3.5), IS_EQ (A==BusWires)
    // -------------------------------------------------------------------------
    // add/sub
    assign addsub_out = AddSub ? (A - BusWires) : (A + BusWires);

    // equality flag via XOR + reduction OR + NOT  (1 if equal, 0 otherwise)
    assign eq_flag = ~|(A ^ BusWires);

    // zero-extended word for writeback
    assign eq_word = {{(n-1){1'b0}}, eq_flag};

    // 3.5×A
    assign mult35 = (A << 1) + A + (A >> 1);

    // ALU selection
    always_comb begin
        unique case (I)
            SPECIALM:  alu_to_G = mult35;
            IS_EQ:     alu_to_G = eq_word;
            default:   alu_to_G = addsub_out;
        endcase
    end

    // G register
    regn G_reg (alu_to_G, Gin, Clock, Resetn, G);

    // -------------------------------------------------------------------------
    // Pop-count for ONES (generic over n)
    // -------------------------------------------------------------------------
    always_comb begin
        ones_sum = '0;
        for (i = 0; i < n; i = i + 1)
            ones_sum += ones_reg[i];
    end

    // -------------------------------------------------------------------------
    // 10:1 bus multiplexer
    // -------------------------------------------------------------------------
    always_comb begin
        if      (Gout)         BusWires = G;
        else if (ones_sum_out) BusWires = {{(n-$bits(ones_sum)){1'b0}}, ones_sum};
        else if (DINout)       BusWires = DIN;
        else if (Rout[0])      BusWires = R0;
        else if (Rout[1])      BusWires = R1;
        else if (Rout[2])      BusWires = R2;
        else if (Rout[3])      BusWires = R3;
        else if (Rout[4])      BusWires = R4;
        else if (Rout[5])      BusWires = R5;
        else if (Rout[6])      BusWires = R6;
        else if (Rout[7])      BusWires = R7;
        else                   BusWires = DIN;
    end

endmodule
