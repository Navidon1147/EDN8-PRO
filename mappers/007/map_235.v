
`include "../base/defs.v"

module map_235
(map_out, bus, sys_cfg, ss_ctrl);

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
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? ctrl_reg[7:0] : 
	ss_addr[7:0] == 1 ? ctrl_reg[15:8] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;//{cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = 0;//!cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mir_single ? 0 : mir_h ? ppu_addr[11] : ppu_addr[10];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[14] = prg_32k ? cpu_addr[14] : prg_page;
	assign prg_addr[21:15] = prg[6:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	wire [6:0]prg = {ctrl_reg[9:8], ctrl_reg[4:0]};
	wire mir_single = ctrl_reg[10];
	wire prg_32k = !ctrl_reg[11];
	wire prg_page = ctrl_reg[12];
	wire mir_h = ctrl_reg[13];
	
	reg [15:0]ctrl_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)ctrl_reg[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)ctrl_reg[15:8] <= cpu_dat;
	end
		else
	if(map_rst | sys_rst)ctrl_reg[15:0] <= 0;
		else
	if(!cpu_rw & cpu_addr[15])
	begin
		ctrl_reg[15:0] <= cpu_addr[15:0];
	end
	
endmodule
