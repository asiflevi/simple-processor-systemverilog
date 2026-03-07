module proc (input logic clk , input logic resetb, input logic [8:0] din ,input logic Run,
output logic Done, output logic [8:0] BusWires);


typedef enum logic [1:0] {
    T0=2'b00,
    T1=2'b01,
    T2=2'b10,
    T3=2'b11
}state_t;

parameter logic [2:0] MV = 3'b000;
parameter logic [2:0] MVI = 3'b001;
parameter logic [2:0] ADD = 3'b010;
parameter logic [2:0] SUB = 3'b011;
parameter logic [2:0] ones = 3'b100;
parameter logic [2:0] my_mult = 3'b101;

state_t Tstep_D,Tstep_Q;

//Q wires of all registers
logic [8:0] R0,R1,R2,R3,R4,R5,R6,R7,A,G,IR;

logic [8:0] G_mux;
//enables for all registers
logic [7:0] Rin,Xreg,Yreg;
logic A_in,G_in,IR_in;

//add sub signals and path
logic add_sub_en;
logic [8:0] add_sub_out;

//ones operation 
logic [8:0] ones_D;

//my_mult operation 
logic [8:0] my_mult_D;


//mux selectors
logic G_out,Din_out;
logic [7:0] Rout;

logic [2:0] I;

assign I = IR[8:6];
dec3to8 decX (.din(IR[5:3]), .en(1'b1), .dout(Xreg));
dec3to8 decY (.din(IR[2:0]), .en(1'b1), .dout(Yreg));

// Control FSM state table always @(Tstep_Q, Run, Done) begin
always_comb begin
    case(Tstep_Q)
    T0:Tstep_D=Run?T1:T0;
    T1:Tstep_D=Done?T0:T2;
    T2:Tstep_D=Done?T0:T3;
    T3:Tstep_D=T0;
    default:Tstep_D=T0;
    endcase
end

// always_comb begin
// // Control FSM outputs always @(Tstep_Q or I or Xreg or Yreg) begin
// ... specify initial values case (Tstep_Q) T0: // store DIN in IR in time step 0 begin
// IRin = 1'b1; end
// T1: //define signals in time step 1 case (I) ... endcase
// T2: //define signals in time step 2 case (I) ... endcase
// T3: //define signals in time step 3
// case (I) ... endcase
// endcase
// end

always_comb begin
    {Rin,A_in,G_in,IR_in,G_out,Din_out,Rout,Done,add_sub_en}='0;
    case(Tstep_Q)
    T0:IR_in=1'b1;
    T1: 
        case(I)
        MV:begin
            Done=1'b1;
            Rout=Yreg;
            Rin=Xreg;
        end
        MVI:begin
            Done=1'b1;
            Din_out=1'b1;
            Rin=Xreg;
        end
        ADD:begin
            A_in=1'b1;
            Rout=Xreg;
        end
        SUB:begin
            A_in=1'b1;
            Rout=Xreg;
        end
        ones:begin
            A_in=1'b1;
            Rout=Xreg;
        end
        my_mult:begin
            A_in=1'b1;
            Rout=Xreg;
        end
        default:Done=1'b1;
        endcase
    T2:begin
        case(I)
        ADD:begin
            add_sub_en=1'b0;
            Rout=Yreg;
            G_in=1'b1;
        end
        SUB:begin
            add_sub_en=1'b1;
            Rout=Yreg;
            G_in=1'b1;
        end
        ones:begin
            G_in=1'b1;
            
        end
        my_mult:begin
            G_in=1'b1;
        end

        default:add_sub_en=1'b0;
        endcase
        end
    T3:begin
        Done=1'b1;
        G_out=1'b1;
        case(I)
        ones:Rin=Yreg;
        my_mult:Rin=Yreg;
        default:Rin=Xreg;
        endcase
    end
    default:Done=1'b1;
    endcase
end


//bus mux 
always_comb begin
    if(|Rout) begin
        case(Rout)
        8'b00000001:BusWires=R0;
        8'b00000010:BusWires=R1;
        8'b00000100:BusWires=R2;
        8'b00001000:BusWires=R3;
        8'b00010000:BusWires=R4;
        8'b00100000:BusWires=R5;
        8'b01000000:BusWires=R6;
        8'b10000000:BusWires=R7;
        default:BusWires=9'b0;
        endcase
    end
    else if(Din_out) begin
        BusWires=din;
    end
    else if (G_out) begin
        BusWires=G;
    end

    else begin
        BusWires=9'b0;
    end

end

//add sub logic implementation
assign add_sub_out = add_sub_en ? (A-BusWires):(A+BusWires);
//ones logic implmentation


// assign ones_D = BusWires[0]+BusWires[1]+BusWires[2]+BusWires[3]+BusWires[4]+BusWires[5]+BusWires[6]
// +BusWires[7]+BusWires[8];
always_comb begin
    ones_D=9'b0;
    for(int i=0 ; i<9 ; i++) begin
        ones_D=ones_D + {{8{1'b0}},A[i]};
    end
end

//my_mult implemantion logic
assign my_mult_D = A+{1'b0,A[8:1]}+{A[7:0],1'b0};


always_comb begin
    case(I)
    ones:G_mux=ones_D;
    my_mult:G_mux=my_mult_D;
    default:G_mux=add_sub_out;
    endcase

end

// Control FSM flip-flops always @(posedge Clock, negedge Resetn) if (!Resetn) ...
regn reg_0 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[0]), .Q(R0));
regn reg_1 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[1]), .Q(R1));
regn reg_2 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[2]), .Q(R2));
regn reg_3 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[3]), .Q(R3));
regn reg_4 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[4]), .Q(R4));
regn reg_5 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[5]), .Q(R5));
regn reg_6 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[6]), .Q(R6));
regn reg_7 (.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(Rin[7]), .Q(R7));

regn reg_A(.clk(clk) , .resetb(resetb) , .din(BusWires) , .en(A_in), .Q(A));
regn reg_G (.clk(clk) , .resetb(resetb) , .din(G_mux) , .en(G_in), .Q(G));
regn reg_IR (.clk(clk) , .resetb(resetb) , .din(din) , .en(IR_in), .Q(IR));

// regn reg_ones (.clk(clk) , .resetb(resetb) , .din(ones_D) , .en(ones_ld), .Q(ones_Q));

// regn reg_my_mult (.clk(clk) , .resetb(resetb) , .din(my_mult_D) , .en(my_mult_ld), .Q(my_mult_Q));


//ff for fsm

always_ff@(posedge clk or negedge resetb) begin
        if(!resetb)
            Tstep_Q<=T0;
        else
            Tstep_Q<=Tstep_D;
end


 endmodule

