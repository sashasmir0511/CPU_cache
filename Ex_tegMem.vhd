----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:21:19 03/04/2021 
-- Design Name: 
-- Module Name:    tegMem - tegMem_arch 
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
	-- параменты для памяти тегов
      ATEG_WIDTH     : integer := 6;
      AINDEX_WIDTH   : integer := 5;
		LFU_WIDTH		: integer := 4;
		
		-- ширина номера канала, а не их кол-во, т.к. брать логорифм в vhdl не удобно. 
		CHANNEL_WIDTH	: integer := 2		
	);
	port (
      clk            : in  std_logic;
		reset_n        : in  std_logic; 	-- сброс инверсный! (активный 0)
		
		-- Формат адреса на входе:
		--									ТЕГ[ATEG_WIDTH-1:0] & INDEX[AINDEX_WIDTH - 1:0]
		addr				: in  std_logic_vector(ATEG_WIDTH + AINDEX_WIDTH - 1 downto 0);
		wr					: in  std_logic;	-- запись нового тега 
		lfu				: in  std_logic;	-- инкремент счетчика 
		md 				: in  std_logic;	-- установка бита модификации
		
		-- Формат выходных данных:
		--									MOD & ТЕГ[ATEG_WIDTH-1:0]
		tegOut			: out std_logic_vector(ATEG_WIDTH + 1 - 1 downto 0);
		
		-- при hit = 1 - номер канала куда попали,
		-- при hit = 0 - номер вытесняемого канала
		chan   			: out std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
		hit				: out std_logic
	);
	
end tegMem;

architecture tegMem_arch of tegMem is

-- объявление используемых компонент
	-- канал памяти тегов
	component tegMemChannel
		generic (
			ATEG_WIDTH     : integer;
			AINDEX_WIDTH   : integer;
			LFU_WIDTH		: integer);
		port (
			clk            : in  std_logic;
			reset_n        : in  std_logic;			
			addr				: in  std_logic_vector(ATEG_WIDTH + AINDEX_WIDTH - 1 downto 0);
			wr					: in  std_logic;
			lfu_ce			: in  std_logic;
			lfu				: in  std_logic;
			lfu_of			: out std_logic;
			lfu_s				: in  std_logic;
			md 				: in  std_logic;			
			tegOut			: out std_logic_vector(ATEG_WIDTH + 2 + LFU_WIDTH - 1 downto 0);
			hit				: out std_logic);
	end component;
	
	-- КС выбора вытесняемого канала 
	component lfuCompKs is
		generic (
			LFU_WIDTH		: integer;
			CHANNEL_WIDTH	: integer
		);
		port (
			-- на вход все счетчики LFU + биты валидности
			lfuCntIn	:	in  std_logic_vector(2**CHANNEL_WIDTH * (LFU_WIDTH+1) - 1 downto 0);
			lfuMin	:  out std_logic_vector (CHANNEL_WIDTH - 1 downto 0)
		);
	end component;
	
	-- вспомогательные константы 
	constant CHAN_CNT	: integer := 2**CHANNEL_WIDTH;
	
	-- сигналы для подключения каналов
	type 		chTegOut_t is array (natural range <>) of std_logic_vector (ATEG_WIDTH + 2 + LFU_WIDTH - 1 downto 0);
	
	signal	hitCh		: std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
	signal   hitAll	: std_logic;
		
	signal	lfuCh		: std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
	signal	lfuCh_u	: std_logic_vector(CHAN_CNT - 1 downto 0);
	signal 	lfuAllCnt: std_logic_vector(CHAN_CNT * (LFU_WIDTH+1) - 1 downto 0);
	
	signal 	lfuShift : std_logic;
		
	signal	chHit		: std_logic_vector(CHAN_CNT - 1 downto 0);
	signal	chlfu_of : std_logic_vector(CHAN_CNT - 1 downto 0);
	signal   chTegOut : chTegOut_t(CHAN_CNT - 1 downto 0);
	
	
begin

	-- generate цикл для подключения всех каналов и сигналов, относящихся к ним. 
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
				md 				=> md,
				tegOut 			=> chTegOut(i),
				hit 				=> chHit(i)
			);
			
		lfuAllCnt((LFU_WIDTH+1) * (i + 1) - 1 downto (LFU_WIDTH+1) * i) <= 
													chTegOut(i)(LFU_WIDTH+1) & chTegOut(i)(LFU_WIDTH - 1 downto 0);
			
	end generate channel_g;
	
	-- комбинациоанная схема формирования номера канала с попаданием 
	hit_ch_p : process(chHit)
	begin
		hitCh <= (others => '0');
		for i in 0 to CHAN_CNT - 1 loop
			if chHit(i) = '1' then
				hitCh <= conv_std_logic_vector(i,CHANNEL_WIDTH);
			end if;
		end loop;
	end process hit_ch_p;
	
	-- подключение КС выбора канала по лагоритму LFU
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
	
	-- выходы
	chan		<= hitCh when hitAll = '1' else lfuCh;
	
	hit <= hitAll;
	
	tegOut <= 	chTegOut(conv_integer(lfuCh))(LFU_WIDTH) & 
					chTegOut(conv_integer(lfuCh))(ATEG_WIDTH + 2 + LFU_WIDTH - 1 downto 2 + LFU_WIDTH);

end tegMem_arch;

