
module map_068(

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] =
	sst.addr[7:2] == 0 ? chr_reg[sst.addr[1:0]] : 
	sst.addr[7:0] == 4 ? nt[0] : 
	sst.addr[7:0] == 5 ? nt[1] : 
	sst.addr[7:0] == 6 ? prg_reg : 
	sst.addr[7:0] == 7 ? mirror_mode : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[17:14] 	= !cpu.addr[14] ? prg_reg[3:0] : 4'b1111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[10] 		= nt_area ? nt[mao.ciram_a10][0] : ppu.addr[10];
	assign chr.addr[17:11] 	= nt_area ? {1'b1, nt[mao.ciram_a10][6:1]} : chr_reg[ppu.addr[12:11]];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !mirror_mode[0] ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= nt_area ? 1 : !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation
	
	wire nt_area = ppu.addr[13] & !ppu.addr[12] & mirror_mode[1];
	
	
	reg [6:0]chr_reg[4];
	reg [6:0]nt[2];
	reg [3:0]prg_reg;
	reg [1:0]mirror_mode;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:2] == 0)chr_reg[sst.addr[1:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)nt[0] 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)nt[1] 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 6)prg_reg 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 7)mirror_mode 	<= sst.dato;
	end
		else
	if(cpu.addr[15] & !cpu.rw)
	begin
		
		if(cpu.addr[14] == 0)chr_reg[cpu.addr[13:12]] 	<= cpu.data[6:0];
		if(cpu.addr[14:12] == 4)nt[0] 						<= cpu.data[6:0];
		if(cpu.addr[14:12] == 5)nt[1] 						<= cpu.data[6:0];
		if(cpu.addr[14:12] == 6)mirror_mode[1:0] 			<= {cpu.data[4], cpu.data[0]};
		if(cpu.addr[14:12] == 7)prg_reg[3:0] 				<= cpu.data[3:0];
	
	end

	
endmodule
