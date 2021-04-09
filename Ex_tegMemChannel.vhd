----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:23:02 03/04/2021 
-- Design Name: 
-- Module Name:    tegMemChannel - tegMemChannel_arch 
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
	-- параметры для одного канала
	generic (
      ATEG_WIDTH     : integer := 6;		-- разрядность тега
      AINDEX_WIDTH   : integer := 5;		-- разрядность индекса
		LFU_WIDTH		: integer := 4			-- разрядность счетчика LFU
	);
	port (
		
      clk            : in  std_logic;
		reset_n        : in  std_logic; 		-- сброс инверсный! (активный 0)
		
		-- Формат адреса на входе:
		--									ТЕГ[ATEG_WIDTH-1:0] & INDEX[AINDEX_WIDTH - 1:0]
		addr				: in  std_logic_vector(ATEG_WIDTH + AINDEX_WIDTH - 1 downto 0);
		wr					: in  std_logic;		-- запись нового тега 
		lfu				: in  std_logic;		-- инкремент счетчика 
		lfu_ce			: in  std_logic;		-- канал выбран алгоритмом LFU
		lfu_of			: out std_logic;		-- переполнение счетчика
		lfu_s				: in  std_logic;		-- деление счетчика на 2 (сдвиг вправо на 1 разряд)
		md 				: in  std_logic;		-- установка бита модификации
		
		-- Формат выходных данных:
		--									ТЕГ[ATEG_WIDTH-1:0] & VAL & MOD & LFU[LFU_WIDTH - 1:0]
		tegOut			: out std_logic_vector(ATEG_WIDTH + 2 + LFU_WIDTH - 1 downto 0);
		hit				: out std_logic		-- попадание 
	);
end tegMemChannel;

architecture tegMemChannel_arch of tegMemChannel is

	-- вспомогательные константы --
	constant MEM_SIZE	: integer := 2**AINDEX_WIDTH;					-- количество строк памяти тэгов
	constant MEM_WIDTH: integer := LFU_WIDTH + ATEG_WIDTH + 2;	-- разрядность памяти тэгов
	constant VAL_BIT	: integer := LFU_WIDTH + 1;					-- позиция бита валидности
	constant MOD_BIT	: integer := LFU_WIDTH;							-- позиция бита модификации 
	
	-- синонимы для обращения к отдельным разрядам шины адреса
	alias aTeg			: std_logic_vector(ATEG_WIDTH - 1 downto 0) 
											is addr(ATEG_WIDTH + AINDEX_WIDTH - 1 downto AINDEX_WIDTH);
	alias aIndex		: std_logic_vector(AINDEX_WIDTH - 1 downto 0) 
											is addr(AINDEX_WIDTH - 1 downto 0);
	
	--	память - двумерный массив бит
	type tegMem_t is array (natural range <>) of std_logic_vector (MEM_WIDTH - 1 downto 0);
	signal tegMem 		: tegMem_t (MEM_SIZE - 1 downto 0) := (others => (others => 'U'));
	
	-- выход памяти. Синонимы для обращения к частям шины
	signal tegMemOut  : std_logic_vector (MEM_WIDTH - 1 downto 0);
		alias moTeg		: std_logic_vector (ATEG_WIDTH - 1 downto 0) 	is tegMemOut(MEM_WIDTH - 1 downto VAL_BIT + 1);
		alias moVal		: std_logic 												is tegMemOut(VAL_BIT);
		alias moMod		: std_logic 												is tegMemOut(MOD_BIT);
		alias moLfu		: std_logic_vector (LFU_WIDTH - 1 downto 0) 		is tegMemOut(MOD_BIT - 1 downto 0);
	
	-- вход памяти. Синонимы для обращения к частям шины
	signal tegMemIn   : std_logic_vector (MEM_WIDTH - 1 downto 0);
		alias miTeg		: std_logic_vector (ATEG_WIDTH - 1 downto 0) 	is tegMemIn(MEM_WIDTH - 1 downto VAL_BIT + 1);
		alias miVal		: std_logic 												is tegMemIn(VAL_BIT);
		alias miMod		: std_logic 												is tegMemIn(MOD_BIT);
		alias miLfu		: std_logic_vector (LFU_WIDTH - 1 downto 0) 		is tegMemIn(MOD_BIT - 1 downto 0);

	signal hitBuf		: std_logic;
	signal ce 			: std_logic;			-- сигнал разрешения записи в амять

begin
	-- Формирование данных на входе в память
	miTeg <= aTeg 	when wr = '1' else moTeg;
	miVal <= '1' 	when wr = '1' else moVal;
	miMod <= '1'	when md = '1' else 
				'0'   when wr = '1' else moMod;
	miLfu	<= '0' & moLfu(LFU_WIDTH - 1 downto 1) when lfu_s = '1' 	else
				moLfu + '1'									when lfu = '1' 	else
				(others => '0')							when wr = '1' 		else	moLfu;	
	
	-- формирование сигнала разрешения записи
	ce	<= '1' when hitBuf = '1' or lfu_ce = '1' or lfu_s = '1' else '0';
		
	-- процесс управления записью в память
	tegMem_p : process(clk)
		-- вспомогательная переменная для формирования значения по сбросу
		variable rstVal : std_logic_vector (MEM_WIDTH - 1 downto 0); 
	begin
		rstVal := (others => 'U');
		rstVal(VAL_BIT) := '0';
		rstVal(MOD_BIT) := '0';
		if clk'event and clk = '1' then
			if reset_n = '0' then
				tegMem <= (others => rstVal);
			elsif ce = '1' then
				tegMem(conv_integer(aIndex)) <= tegMemIn;
			end if;
		end if;
	end process tegMem_p;
	
	-- чтение из памяти тегов асинхронное. c эмуляцией задержки для функционального моделирования
	tegMemOut <= tegMem(conv_integer(aIndex)) after 1 ns; 	
	-- если все разряды счетчика = 1 - переполнение 
	lfu_of   <= '1' when moLfu = (moLfu'range => '1') else '0';	
	tegOut 	<= tegMemOut;
	hitBuf	<= '1' when moTeg = aTeg and moVal = '1' else '0';
	hit 		<= hitBuf;	
end tegMemChannel_arch;

