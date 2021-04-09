-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS 
  
 			 -- ��������� ��� ������ �����
			 shared variable ATEG_WIDTH     : integer := 5;
			 shared variable AINDEX_WIDTH   : integer := 6;
		
			 -- ������ ������ ������, � �� �� ���-��, �.�. ����� �������� � vhdl �� ������. 
		    shared variable CHANNEL_WIDTH	: integer := 2;	

  -- Component Declaration
          COMPONENT tegMem
          PORT(
            clk            : IN  std_logic;
				reset_n        : IN  std_logic; 	-- ����� ���������! (�������� 0)
				addr				: IN  std_logic_vector(10 downto 0);
				wr					: IN  std_logic;	-- ������ ������ ���� 
				rand				: IN 	std_logic;  -- ��������� ��������
				md 				: IN  std_logic;	-- ��������� ���� �����������
				tegOut			: OUT std_logic_vector(5 downto 0);
				chan   			: OUT std_logic_vector(1 downto 0);
				hit				: OUT std_logic
          );
          END COMPONENT;
		
			 -- ������ ������ �� �����:
			 signal clk            : std_logic := '0';
			 signal reset_n        : std_logic := '0'; 
			 signal addr				: std_logic_vector(10 downto 0) := (others => '0');
			 signal wr					: std_logic := '0';	
			 signal rand				: std_logic := '0';  
			 signal md 				: std_logic := '0';
		
			 -- ������ �������� ������:
			 signal tegOut			: std_logic_vector(5 downto 0);
			 signal chan   			: std_logic_vector(1 downto 0);
			 signal hit				: std_logic;
			 
			 constant clk_period : time := 10 ns;
          
  BEGIN

  -- Component Instantiation
  uut: tegMem PORT MAP(
            clk     => clk,
				reset_n => reset_n,       
				addr	  => addr,
				wr		  => wr,
				rand	  => rand,
				md 	  => md,
				tegOut  => tegOut,
				chan    => chan,
				hit	  => hit
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
			
			-- ������ 
			addr <= "10100" & "000001";
			md <= '0';
			rand <= '0';
			wr <= '1';
			wait for clk_period * 1;
		
			-- ������
			addr <= "10101" & "000010";
			md <= '0';
			rand <= '0';
			wr <= '1';
			wait for clk_period * 1;
		
			-- ������
			addr <= "10100" & "000001";
			md <= '0';
			rand <= '0';
			wr <= '0';
			wait for clk_period * 1;
			
			-- ������
			addr <= "10101" & "000010";
			md <= '1';
			rand <= '0';
			wr <= '1';
			wait for clk_period * 1;
			
			-- ������
			addr <= "10101" & "000010";
			md <= '0';
			rand <= '0';
			wr <= '0';
			wait for clk_period * 1;
			
			-- ������
			addr <= "11111" & "000010";
			md <= '0';
			rand <= '1';
			wr <= '0';
			wait for clk_period * 1;
				
			wait;		
  end process;
END;
