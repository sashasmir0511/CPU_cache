--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:29:40 04/09/2021
-- Design Name:   
-- Module Name:   C:/studi/qwr/TB_tegMem.vhd
-- Project Name:  qwr
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tegMem
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY TB_tegMem IS
END TB_tegMem;
 
ARCHITECTURE behavior OF TB_tegMem IS 

	shared variable ATEG_WIDTH		: integer := 5;
	shared variable AINDEX_WIDTH	: integer := 6;
	shared variable LFU_WIDTH		: integer := 4;
	
	shared variable CHANNEL_WIDTH	: integer := 2;

	COMPONENT tegMem
	PORT(
		clk		: IN  std_logic;
		reset_n	: IN  std_logic;
		addr	: IN  std_logic_vector(10 downto 0);
		wr		: IN  std_logic;
		lfu		: IN  std_logic;
		chan	: OUT std_logic_vector(1 downto 0);
		hit		: OUT std_logic
	);
	END COMPONENT;
	

	--Inputs
	signal clk     : std_logic := '0';
	signal reset_n : std_logic := '0';
	signal addr    : std_logic_vector(16 downto 0) := (others => '0');
	signal wr      : std_logic := '0';
	signal lfu     : std_logic := '0';

	--Outputs
	signal tegOut	: std_logic_vector(5 downto 0);
	signal chan		: std_logic_vector(1 downto 0);
	signal hit		: std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: tegMem PORT MAP (
		clk		=> clk,
		reset_n	=> reset_n,
		addr	=> addr,
		wr		=> wr,
		lfu		=> lfu,
		chan	=> chan,
		hit		=> hit
	);

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
 

	-- Stimulus process
	stim_proc: process
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;
		reset_n <= '1';
		wait for clk_period*10;
		reset_n <= '0';
		wait for clk_period;

		addr <= "10100" & "000001" & "00000";
		rand <= '0';
		wr <= '1';
		wait for clk_period * 1;
	
		addr <= "10101" & "000010 & "00000"";
		rand <= '0';
		wr <= '1';
		wait for clk_period * 1;
	
		addr <= "10100" & "000001" & "00000";
		rand <= '0';
		wr <= '0';
		wait for clk_period * 1;
		
		addr <= "10101" & "000010" & "00000";
		rand <= '0';
		wr <= '1';
		wait for clk_period * 1;
		
		addr <= "10101" & "000010" & "00000";
		rand <= '0';
		wr <= '0';
		wait for clk_period * 1;
		
		addr <= "11111" & "000010" & "00000";
		rand <= '1';
		wr <= '0';
		wait for clk_period * 1;

		wait;
	end process;
END;