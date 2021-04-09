----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:49:28 04/09/2021 
-- Design Name: 
-- Module Name:    memTegChannel - Behavioral 
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
use ieee.std_logic_unsigned.all;

entity tegMemChannel is
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
		lfu_ce			: in  std_logic;
		lfu_s			: in  std_logic;
		
		tegOut			: out std_logic_vector(ATEG_WIDTH + 1 + LFU_WIDTH - 1 downto 0);
		hit				: out std_logic;
		lfu_of			: out std_logic
	);
	
end tegMemChannel;

architecture tegMemChannel_arch of tegMemChannel is

	constant MEM_SIZE	: integer := 2**AINDEX_WIDTH;
	constant MEM_WIDTH  : integer := LFU_WIDTH + ATEG_WIDTH + 1;
	constant VAL_BIT	: integer := LFU_WIDTH;
   
	alias aTeg			: std_logic_vector(ATEG_WIDTH - 1 downto 0)
													is addr(ATEG_WIDTH + AINDEX_WIDTH - 1 downto AINDEX_WIDTH);
	alias aIndex		: std_logic_vector(AINDEX_WIDTH - 1 downto 0)
													is addr(AINDEX_WIDTH - 1 downto 0);

	type tegMem_t is array (natural range <>) of std_logic_vector (MEM_WIDTH - 1 downto 0);
	signal tegMem 		: tegMem_t (MEM_SIZE - 1 downto 0) := (others => (others => 'U'));

	signal tegMemOut	: std_logic_vector (MEM_WIDTH - 1 downto 0);
		alias moTeg		: std_logic_vector (ATEG_WIDTH - 1 downto 0) 	is tegMemOut(MEM_WIDTH - 1 downto VAL_BIT + 1);
		alias moVal		: std_logic 									is tegMemOut(VAL_BIT);
		alias moLfu		: std_logic_vector (LFU_WIDTH - 1 downto 0) 	is tegMemOut(LFU_WIDTH - 1 downto 0);
	
	signal tegMemIn   : std_logic_vector (MEM_WIDTH - 1 downto 0);
		alias miTeg		: std_logic_vector (ATEG_WIDTH - 1 downto 0) 	is tegMemIn(MEM_WIDTH - 1 downto VAL_BIT + 1);
		alias miVal		: std_logic 									is tegMemIn(VAL_BIT);
		alias miLfu		: std_logic_vector (LFU_WIDTH - 1 downto 0) 	is tegMemIn(LFU_WIDTH - 1 downto 0);

	signal hitBuf		: std_logic;
	signal ce 			: std_logic;

begin	
	miTeg	<= aTeg	when wr = '1' else moTeg;
	miVal	<= '1'	when wr = '1' else moVal;
	miLfu	<= '0' & moLfu(LFU_WIDTH - 1 downto 1)	when lfu_s = '1' 	else
				moLfu + '1'							when lfu = '1'		else
				(others => '0')						when wr = '1' 		else	moLfu;	
	

	ce	<= '1' when hitBuf = '1' or lfu_ce = '1' or lfu_s = '1' else '0';
		
	tegMem_p : process(clk)
		variable rstVal : std_logic_vector (MEM_WIDTH - 1 downto 0); 
	begin
		rstVal := (others => 'U');
		rstVal(VAL_BIT) := '0';
		if clk'event and clk = '1' then
			if reset_n = '0' then
				tegMem <= (others => rstVal);
			elsif ce = '1' then
				tegMem(conv_integer(aIndex)) <= tegMemIn;
			end if;
		end if;
	end process tegMem_p;
	
	tegMemOut <= tegMem(conv_integer(aIndex)) after 1 ns; 	

	lfu_of	<= '1' when moLfu = (moLfu'range => '1') else '0';	
	tegOut 	<= tegMemOut;
	hitBuf	<= '1' when moTeg = aTeg and moVal = '1' else '0';
	hit 	<= hitBuf;	
end tegMemChannel_arch;

