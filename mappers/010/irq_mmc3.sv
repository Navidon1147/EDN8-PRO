

module irq_mmc3(

	input clk,
	input decode_en,
	input cpu_m2,
	input [7:0]cpu_data,
	input [3:0]reg_addr,
	input ppu_a12,
	input map_rst,
	input mmc3a,
	
	output irq,
	
	input  SSTBus sst,
	output [7:0]sst_di
);
	
	assign sst_di = 
	sst.addr[7:0] == 16 ? reload_val : 
	sst.addr[7:0] == 17 ? irq_on : //irq_on should be saved befor irq_pend
	sst.addr[7:0] == 18 ? irq_ctr : 
	sst.addr[7:0] == 19 ? {reload_req, irq_pend} :
	8'hff;
	
	
	assign irq 				= irq_pend;
	
	
	wire [7:0]ctr_next	= irq_ctr == 0 ? reload_val : irq_ctr - 1;
	wire irq_trigger 		= mmc3a ? ctr_next == 0 & (irq_ctr != 0 | reload_req) : ctr_next == 0;
	
	reg [7:0]reload_val;
	reg [7:0]irq_ctr;
	reg irq_on, reload_req, irq_pend;

	always @(posedge clk)
	if(sst.act)
	begin
		if(decode_en)
		begin
			if(sst.we_reg & sst.addr[7:0] == 16)reload_val 	<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 17)irq_on 		<= sst.dato[0];
			if(sst.we_reg & sst.addr[7:0] == 18)irq_ctr		<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 19){reload_req, irq_pend} <= sst.dato;
		end
	end
		else
	if(map_rst)
	begin
		irq_on 	<= 0;
		irq_pend	<= 0;
	end
		else
	begin
		
		if(decode_en)
		case(reg_addr[3:0])
			4'hC:reload_val[7:0] <= cpu_data[7:0];//C000
			4'hE:irq_on 			<= 0;//E000
			4'hF:irq_on 			<= 1;//E001
		endcase
		
		
		if(decode_en & reg_addr == 4'hD)//C001
		begin
			reload_req		<= 1;
			irq_ctr[7:0] 	<= 0;
		end
			else
		if(a12_edge)
		begin
			reload_req		<= 0;
			irq_ctr 			<= ctr_next;
		end
		
	
		if(!irq_on)
		begin
			irq_pend <= 0;
		end
			else
		if(a12_edge & irq_trigger)
		begin
			irq_pend <= 1;
		end
		
	end
	
//************************************************************* a12 filter (IC level)	
	wire a12_edge = a12_filter[2:0] == 'b111 & a12d;
	
	reg [2:0]a12_filter;
		
	always @(posedge clk)
	begin
		
		if(a12d)
		begin
			a12_filter[2:0] <= 0;
		end
			else
		if(m2_ne)
		begin
			a12_filter[2:0] <= {a12_filter[1:0], 1'b1};
		end
		
	end
//************************************************************* a12 deglitcher (onboard cap)
	reg a12d;
	reg [1:0]a12_st;
	
	//negedge used to reduce filter delay
	//from a12 rise to irq triggering should be around 50ns
	always @(negedge clk)
	begin
		a12_st[1:0] <= {a12_st[0], ppu_a12};
		if(a12_st[1:0] == 2'b11)a12d <= 1;
		if(a12_st[1:0] == 2'b00)a12d <= 0;
	end
	
//************************************************************* m2 neg edge
	wire m2_ne = m2_st[2:0] == 3'b110;
	
	reg [2:0]m2_st;
	always @(posedge clk)
	begin
		m2_st[2:0]	<= {m2_st[1:0], cpu_m2};
	end		
	
endmodule
