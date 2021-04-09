----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:35:22 03/26/2021 
-- Design Name: 
-- Module Name:    randCntr - randCntr_arch 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity randCntr is
	-- параметры для одного канала
	generic (
      CHANNEL_WIDTH     : integer := 2		-- разрядность канала
	);
	port (		
		-- Формат адреса на входе:
		randCntIn	:	in  std_logic;		
		-- Формат выходных данных:
		randOut	:  out std_logic_vector (CHANNEL_WIDTH - 1 downto 0)
	);
end randCntr;

architecture randCntr_arch of randCntr is
	signal tmp:	std_logic;
	signal rand_number: std_logic_vector(CHANNEL_WIDTH - 1 downto 0);
	signal counter: std_logic_vector(CHANNEL_WIDTH**2 - 1 downto 0) := "1111";
begin
	randNumber_p : process(randCntIn)
	begin
		if (randCntIn'event and randCntIn='1') then
			tmp <= counter(CHANNEL_WIDTH**2 - 1);
			for i in 0 to CHANNEL_WIDTH**2 - 2 loop
				counter(i+1) <= counter(i);
			end loop;
         counter(0) <= tmp xor counter(CHANNEL_WIDTH**2 - 1);
			
			for i in 0 to CHANNEL_WIDTH - 1 loop
				rand_number(i) <= counter(i);
			end loop;
		end if;		
	end process randNumber_p;
	
	randOut <= rand_number;

end randCntr_arch;

