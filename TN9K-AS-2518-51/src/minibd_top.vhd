-----------------------------------------------------------
--        AS-2518-51 Sound Board - Tang Nano 9k
--          Original Code by various Authors
--
--             Modified for Tang Nano 9k 
--                by pinballwiz.org 
--                   04/08/2025
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-----------------------------------------------------------
entity minibd_top is
	port(
		Clock_27          : in    std_logic;
		I_RESET           : in    std_logic;
        ps2_clk           : inout    std_logic;
        ps2_dat           : inout std_logic;
		O_AUDIO_L         : out   std_logic;
		O_AUDIO_R         : out   std_logic
		);
end minibd_top;
-----------------------------------------------------------
architecture rtl of minibd_top is

-- Sound board signals
signal reset		:  std_logic;
signal cpu_clk		:	std_logic;
signal snd_ctl		: 	std_logic_vector(7 downto 0);
signal audio_o	    : std_logic;

-- PS/2 interface signals
signal codeReady	: std_logic;
signal scanCode	: std_logic_vector(9 downto 0);
signal send 		: std_logic;
signal Command 	: std_logic_vector(7 downto 0);
signal PS2Busy		: std_logic;
signal PS2Error	: std_logic;
signal dataByte	: std_logic_vector(7 downto 0);
signal dataReady	: std_logic;
-----------------------------------------------------------
component Gowin_rPLL
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;
-----------------------------------------------------------
begin

reset <= not I_RESET;
-----------------------------------------------------------
Clock_gen: Gowin_rPLL
    port map (
        clkout  => cpu_clk, -- 3.58Mhz
        clkin   => Clock_27
    );
-----------------------------------------------------------
-- Main audio board code
Core: entity work.AS_2518_51
port map(
	dac_clk     => Clock_27,
	cpu_clk     => cpu_clk,
	reset_l     => I_RESET,
	addr_i      => snd_ctl(5 downto 0),
	snd_int_i   => not scancode(8),
	test_sw_l   => '1',
	audio_o     => audio_o
	);

O_AUDIO_L <= audio_o;
O_AUDIO_R <= audio_o;
-----------------------------------------------------------
	-- PS/2 keyboard controller
keyboard: entity work.PS2Controller
port map(
		Reset     => reset,
		Clock     => Clock_27,
		PS2Clock  => ps2_clk,
		PS2Data   => ps2_dat,
		Send      => send,
		Command   => command,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte
		);
-----------------------------------------------------------
-- PS/2 scancode decoder	
decoder: entity work.KeyboardMapper
port map(
		Clock     => Clock_27,
		Reset     => reset,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte,
		Send      => send,
		Command   => command,
		CodeReady => codeReady,
		ScanCode  => scanCode
		);
-----------------------------------------------------------
-- Connect PS2 scancodes to sound control inputs
inputreg: process
begin
	wait until rising_edge(Clock_27);
		if scanCode(8) = '0' then
			snd_ctl(5 downto 0) <= not scanCode(5 downto 0);
		else
			snd_ctl(5 downto 0) <= "111111";
		end if;
end process;

snd_ctl(7 downto 6) <= "11";
-----------------------------------------------------------
end rtl;