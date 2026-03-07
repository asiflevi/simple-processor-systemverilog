module regn #(parameter int w = 9)(input logic clk,input logic resetb , input logic [w-1:0] din, input logic en,output logic [w-1:0] Q);

logic [w-1:0] D;
assign D = en ? din : Q;

always_ff@(posedge clk or negedge resetb) begin
	if(!resetb)
		Q<='0;
	else
		Q<=D;
end
endmodule
