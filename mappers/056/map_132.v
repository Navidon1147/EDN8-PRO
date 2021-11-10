
`include "../base/defs.v"

module map_132
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	parameter MAP_NUM = 8'd27;
	assign ss_rdat[7:0] = 
	ss_addr[7:2] == 0 ? regs[ss_addr[1:0]][7:0] : 
	ss_addr[7:0] == 4 ? {5'd0, prg, chr[1:0]} :
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[15:13] = {prg, cpu_addr[14:13]};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[14:13] = chr[1:0];
	
	reg [7:0]regs[4];
	reg prg;
	reg [1:0]chr;
	
	assign map_cpu_oe = {cpu_addr[15:2], 2'd0} == 16'h4100 & cpu_rw & m2;
	assign map_cpu_dout[5:0] = regs[1][5:0] ^ regs[2][5:0];
	assign map_cpu_dout[7:6] = 2'b01;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0) regs[ss_addr[1:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 4) {prg, chr[1:0]} <= cpu_dat[2:0];
	end
	else
	begin
		if(map_rst) begin
			regs[0] <= 0;
			regs[1] <= 0;
			regs[2] <= 0;
			regs[3] <= 0;
			prg <= 0;
			chr <= 0;
		end
			
		if(!cpu_rw & {cpu_addr[15:2], 2'd0} == 16'h4100) regs[cpu_addr[1:0]][7:0] <= cpu_dat[7:0];
		if(!cpu_rw & !cpu_ce) begin
			prg <= regs[2][2];
			chr[1:0] <= regs[2][1:0];
		end
	end
	
endmodule
