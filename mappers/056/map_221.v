
`include "../base/defs.v"

module map_221
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
	parameter MAP_NUM = 8'd4;
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? mode[7:0] : 
	ss_addr[7:0] == 1 ? {4'd0, mode[8], prg_bank[2:0]} : 
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[19:14] = prg[5:0];
	
	wire [5:0]prg = mode[1] ? 
	(mode[8] ? (!cpu_addr[14] ? outer_bank[5:0] : {outer_bank[5:3], 3'h7}) : {outer_bank[5:1], cpu_addr[14]}) :
	outer_bank[5:0];
	
	wire [5:0]outer_bank = mode[7:2] | prg_bank[2:0];		//???
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg [8:0]mode;
	reg [2:0]prg_bank;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) mode[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1) {mode[8], prg_bank[2:0]} <= cpu_dat[3:0];
	end
	else
	begin
		
		if(map_rst)begin
			mode <= 0;
			prg_bank <= 0;
		end
		else
		if(!cpu_rw) begin
			if(cpu_addr[15:14] == 2'b10) mode[8:0] <= cpu_addr[8:0];
			if(cpu_addr[15:14] == 2'b11) prg_bank[2:0] <= cpu_addr[2:0];
		end
		
	end

endmodule





























