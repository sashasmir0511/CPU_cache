----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:46:54 04/09/2021 
-- Design Name: 
-- Module Name:    memTeg - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

entity tegMem is
	generic (
		ATEG_WIDTH		: integer := 5;
		AINDEX_WIDTH	: integer := 6;
		LFU_WIDTH		: integer := 4;
		
		CHANNEL_WIDTH	: integer := 2
	);
	port (
		clk				: in  std_logic;
		reset_n			: in  std_logic;

		addr			: in  std_logic_vector(ATEG_WIDTH + AINDEX_WIDTH - 1 downto 0);
		wr				: in  std_logic;
		lfu				: in  std_logic;
		
		tegOut			: out std_logic_vector(ATEG_WIDTH +1 -1 downto 0);
		chan   			: out std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
		hit				: out std_logic
	);
	
end tegMem;

architecture tegMem_arch of tegMem is

	component tegMemChannel
		generic (
			ATEG_WIDTH		: integer;
			AINDEX_WIDTH	: integer;
			LFU_WIDTH		: integer
		);
		port (
			clk				: in  std_logic;
			reset_n			: in  std_logic;			
			
			addr			: in  std_logic_vector(ATEG_WIDTH + AINDEX_WIDTH - 1 downto 0);
			wr				: in  std_logic;
			lfu_ce			: in  std_logic;
			lfu				: in  std_logic;
			lfu_s			: in  std_logic;
			
			tegOut			: out std_logic_vector(ATEG_WIDTH + 1 + LFU_WIDTH - 1 downto 0);
			hit				: out std_logic;
			lfu_of			: out std_logic
		);
	end component;

	component lfuCompKs is
		generic (
			LFU_WIDTH		: integer;
			CHANNEL_WIDTH	: integer
		);
		port (
			lfuCntIn		: in  std_logic_vector(2**CHANNEL_WIDTH * (LFU_WIDTH+1) - 1 downto 0);
			lfuMin			: out std_logic_vector (CHANNEL_WIDTH - 1 downto 0)
		);
	end component;
	
	constant	CHAN_CNT	: integer := 2**CHANNEL_WIDTH;
	
	type 		chTegOut_t is array (natural range <>) of std_logic_vector (ATEG_WIDTH + 1 + LFU_WIDTH - 1 downto 0);

	signal		hitCh		: std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
	signal 		hitAll		: std_logic;

	signal		lfuCh		: std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
	signal		lfuCh_u		: std_logic_vector(CHAN_CNT - 1 downto 0);
	signal 		lfuAllCnt	: std_logic_vector(CHAN_CNT * (LFU_WIDTH+1) - 1 downto 0);
	signal 		lfuShift 	: std_logic;
		
	signal		chHit		: std_logic_vector(CHAN_CNT - 1 downto 0);
	signal		chlfu_of	: std_logic_vector(CHAN_CNT - 1 downto 0);
	signal		chTegOut	: chTegOut_t(CHAN_CNT - 1 downto 0);

begin

	channel_g : for i in 0 to CHAN_CNT - 1 generate
	
		lfuCh_u(i) <= '1' when lfuCh = (conv_std_logic_vector(i,CHANNEL_WIDTH)) and hitAll = '0' else '0';
	
		tegMemCh_inst : tegMemChannel 
			generic map (
				ATEG_WIDTH 		=> ATEG_WIDTH,
				AINDEX_WIDTH	=> AINDEX_WIDTH,
				LFU_WIDTH		=> LFU_WIDTH)
			port map (
				clk				=> clk,		
				reset_n 			=> reset_n,
				addr 				=> addr,
				wr 				=> wr,
				lfu_ce 			=> lfuCh_u(i),
				lfu 				=> lfu,
				lfu_of 			=> chlfu_of(i),
				lfu_s 			=> lfuShift,
				tegOut 			=> chTegOut(i),
				hit 				=> chHit(i)
			);
			
		lfuAllCnt((LFU_WIDTH+1) * (i + 1) - 1 downto (LFU_WIDTH+1) * i) <= 
													chTegOut(i)(LFU_WIDTH+1) & chTegOut(i)(LFU_WIDTH - 1 downto 0);
			
	end generate channel_g;
	
	hit_ch_p : process(chHit)
	begin
		hitCh <= (others => '0');
		for i in 0 to CHAN_CNT - 1 loop
			if chHit(i) = '1' then
				hitCh <= conv_std_logic_vector(i,CHANNEL_WIDTH);
			end if;
		end loop;
	end process hit_ch_p;

	LFU_KS : lfuCompKs 
		generic map (
			LFU_WIDTH		=> LFU_WIDTH,
			CHANNEL_WIDTH	=> CHANNEL_WIDTH)
			port map (
			lfuCntIn 		=> lfuAllCnt,
			lfuMin			=> lfuCh
			);

	lfuShift	<= '1' when chlfu_of /= (chlfu_of'range => '0') else '0';
	hitAll	<= '1' when chHit /= (chHit'range => '0') else '0';
	chan		<= hitCh when hitAll = '1' else lfuCh;
	hit 		<= hitAll;
	tegOut	<= chTegOut(conv_integer(lfuCh))(LFU_WIDTH) & chTegOut(conv_integer(lfuCh))(ATEG_WIDTH + 1 + LFU_WIDTH - 1 downto 1 + LFU_WIDTH);

end tegMem_arch;

