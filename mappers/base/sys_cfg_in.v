
	
	
	//mapper config
	wire [11:0]map_idx;
	wire [9:0]prg_msk;
	wire [9:0]chr_msk;
	wire [7:0]srm_msk;
	wire [7:0]master_vol;
	wire [7:0]map_cfg;
	wire [7:0]ss_key_save;
	wire [7:0]ss_key_load;
	wire [7:0]ctrl;
	

	wire [7:0]prg_msk_in;
	wire [3:0]chr_msk_in;
	assign prg_msk[7:0] = (1'b1 << prg_msk_in[3:0])-1;
	assign srm_msk[7:0] = (1'b1 << prg_msk_in[7:4])-1;
	assign chr_msk[7:0] = (1'b1 << chr_msk_in[3:0])-1;
	
	assign {
	ctrl[7:0], 
	ss_key_load[7:0], 
	ss_key_save[7:0], 
	map_cfg[7:0], 
	master_vol[7:0], 
	{map_idx[11:8], chr_msk_in[3:0]}, 
	prg_msk_in[7:0], 
	map_idx[7:0]} = sys_cfg[`BW_SYS_CFG-1:0];
	
	
	//mappers may use bits 7-4 for own custom conigs
	wire cfg_mir_h = map_cfg[1:0] == 2'b00;
	wire cfg_mir_v = map_cfg[1:0] == 2'b01;
	wire cfg_mir_4 = map_cfg[1:0] == 2'b10;
	wire cfg_mir_1 = map_cfg[1:0] == 2'b11;
	wire cfg_chr_ram = map_cfg[2];
	wire cfg_prg_ram_off = map_cfg[3];
	wire [3:0]map_sub = map_cfg[7:4];
	
	

	wire ctrl_rst_delay = ctrl[0];//with this option quick reset wil reset the game but will not return to menu
	wire ctrl_ss_on     = ctrl[1];//vblank hook for in-game menu
	wire ctrl_gg_on     = ctrl[2];//cheats engine
	wire ctrl_ss_btn    = ctrl[3];//use external button for in-game menu
	wire ctrl_fami 	  = ctrl[4];//cartridge form-factor (0-nes, 1-famicom)
	wire ctrl_unlock    = ctrl[7];//used for mapper status check at 0x4080 during reboot. force map 255 till mapper is not configured
	
	
	
	wire srm_size1k   = srm_msk == 8'b00000000;
	wire srm_size2k   = srm_msk == 8'b00000001;
	wire srm_size4k   = srm_msk == 8'b00000011;
	wire srm_size8k   = srm_msk == 8'b00000111;
	wire srm_size16k  = srm_msk == 8'b00001111;
	wire srm_size32k  = srm_msk == 8'b00011111;
	wire srm_size64k  = srm_msk == 8'b00111111;
	wire srm_size128k = srm_msk == 8'b01111111;
	wire srm_size256k = srm_msk == 8'b11111111;
	