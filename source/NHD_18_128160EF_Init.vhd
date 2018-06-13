----------------------------------------------------------------------------------
-- Company: Baur 3.0 Service GmbH
-- Engineer: Joachim Baur
-- 
-- Create Date: 08.06.2018
-- Module Name: NHD_18_128160EF_Init - Behavioral
-- Description: initialization sequence for ILI9613 driver IC in NHD-1.8-128160 TFT
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity NHD_18_128160EF_Init is
    Port ( 
        i_sys_clock     : in STD_LOGIC;                         -- 125 MHz system clock 
        i_reset         : in STD_LOGIC;                         -- reset (connected to btn0 of board)
        i_driver_ready  : in STD_LOGIC;                         -- display driver is ready for next output

        o_write_start   : out STD_LOGIC;                        -- write start signal for driver
        o_dc	        : out STD_LOGIC;                        -- data/command for driver
        o_db	        : out STD_LOGIC_VECTOR (7 downto 0);    -- 8 bit data bus for driver
        o_rs_tft        : out STD_LOGIC;                        -- tft reset wire

        o_ready         : out STD_LOGIC                         -- init sequence completed
    );
end NHD_18_128160EF_Init;

architecture Behavioral of NHD_18_128160EF_Init is

	type init_phase is (
		PowerUp,
		PowerUpWait,
		Reset,
		ResetWait,
		ResetDelayAfter,
		DisplayOff,
		ExitSleep,
		ExitSleepWait,
		Gamset,
		Gamset_1,
		Vcom_control1,
		Vcom_control1_1,
		Vcom_control1_2,
		Vcom_offset,
        Vcom_offset_1,
        Frmctrl,
        Frmctrl_1,
        Frmctrl_2,
        Pwr_control1,
        Pwr_control1_1,
        Pwr_control1_2,
        Pwr_control2,
        Pwr_control2_1,
		Xadrset,
		Xadrset_1,
		Xadrset_2,
		Xadrset_3,
		Xadrset_4,
		Yadrset,
		Yadrset_1,
		Yadrset_2,
		Yadrset_3,
		Yadrset_4,
        Madctrl,
        Madctrl_1,
        Colmod,
        Colmod_1,
		Dspon,
		DsponWait,
		Finished,
		SendToDisplayDriver,
		WaitForDisplayDriver
		);
    signal curr_state : init_phase := PowerUp;
    signal next_state : init_phase := PowerUp;

    -- register buffers for output signals
    signal rs_reg            : STD_LOGIC := '1'; -- reset is active low, therefore high at startup
    signal dc_reg            : STD_LOGIC := '0';
    signal ws_reg            : STD_LOGIC := '0';
    signal db_reg            : std_logic_vector (7 downto 0) := (others => '0');

    signal ready_reg         : STD_LOGIC := '0';

    -- register for internal state of the driver's ready signal
    signal last_driver_ready : STD_LOGIC := '0';
	
begin

	init_sequence: process (i_sys_clock)
	
    -- delay in clock cycles (1 clock cycle @ 125 MHz = 8ns), 1 ms = 1,000,000 ns = 125,000 clock cycles
	variable delay_cycles : integer range 0 to 15000000 := 0;

	constant DC_CMD  : STD_LOGIC := '0'; -- tft dc wire pulled low: command
    constant DC_DATA : STD_LOGIC := '1'; -- tft dc wire pulled high: data

	begin
        if rising_edge(i_sys_clock) then
            
            if i_reset = '1' then
                ready_reg <= '0';
                curr_state <= Reset;
            else

                case curr_state is

                    when PowerUp =>
                        rs_reg <= '1'; -- pull reset high
                        -- init wait after power up for 120 ms (15,000,000 clock cycles * 8 ns)
                        delay_cycles := 15000000;
                        curr_state <= PowerUpWait;

                    when PowerUpWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							curr_state <= Reset;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when Reset =>
						rs_reg <= '0'; --  pull reset low = reset ACTIVE
                        -- init wait for reset pulse min duration = 10 us = 10,000 ns (1,250 clock cycles * 8 ns)
                        -- make it 20 us = 2,500 clock cycles
                        delay_cycles := 2500; 
                        curr_state <= ResetWait;

					when ResetWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							rs_reg <= '1'; -- pull reset high again
                            -- init wait after reset for 120 ms (15,000,000 clock cycles * 8 ns)
							delay_cycles := 15000000; 
							curr_state <= ResetDelayAfter;
                        else 
                            delay_cycles := delay_cycles - 1;
						end if;
						
					when ResetDelayAfter => 
                        -- wait for end of delay
					    if delay_cycles = 0 then
                            curr_state <= ExitSleep;
                        else 
                            delay_cycles := delay_cycles - 1;
                        end if;

                    when ExitSleep =>
                        -- CMD 0x11, exit sleep
						dc_reg <= DC_CMD;
                        db_reg <= x"11";
 
                        -- init wait 10 ms (1,250,000 clock cycles * 8 ns)
                        delay_cycles := 1250000;

                        curr_state <= SendToDisplayDriver;
                        next_state <= ExitSleepWait;

                    when ExitSleepWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							curr_state <= DisplayOff;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when DisplayOff =>
                        -- CMD 0x28, display off
						dc_reg <= DC_CMD;
                        db_reg <= x"28";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Gamset;

                    when Gamset =>
                        -- CMD 0x26 GAMSET
						dc_reg <= DC_CMD;
                        db_reg <= x"26";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Gamset_1;

                    when Gamset_1 =>
                        -- DATA 0x04 GAMSET
						dc_reg <= DC_DATA;
                        db_reg <= x"04";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_control1;

                    when Vcom_control1 =>
                        -- CMD 0xC5 VCOM_control 1
						dc_reg <= DC_CMD;
                        db_reg <= x"C5";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_control1_1;

                    when Vcom_control1_1 =>
                        -- DATA 0x2F VCOM_control 1
						dc_reg <= DC_DATA;
                        db_reg <= x"2F";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_control1_2;
                        
                    when Vcom_control1_2 =>
                        -- DATA 0x3E VCOM_control 1
                        dc_reg <= DC_DATA;
                        db_reg <= x"3E";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_offset;

                    when Vcom_offset =>
                        -- CMD 0xC7 VCOM OFFSET CONTROL
						dc_reg <= DC_CMD;
                        db_reg <= x"C7";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_offset_1;

                    when Vcom_offset_1 =>
                        -- DATA 0x40 VCOM OFFSET CONTROL
						dc_reg <= DC_DATA;
                        db_reg <= x"40";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Frmctrl;

                    when Frmctrl =>
                        -- CMD 0xB1 Frame Rate Control
						dc_reg <= DC_CMD;
                        db_reg <= x"B1";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Frmctrl_1;

                    when Frmctrl_1 =>
                        -- DATA 0x0A Frame Rate Control
						dc_reg <= DC_DATA;
                        db_reg <= x"0A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Frmctrl_2;

                    when Frmctrl_2 =>
                        -- DATA 0x14 Frame Rate Control
						dc_reg <= DC_DATA;
                        db_reg <= x"14";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwr_control1;

                    when Pwr_control1 =>
                        -- CMD 0xC0 Power Control 1
						dc_reg <= DC_CMD;
                        db_reg <= x"C0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwr_control1_1;

                    when Pwr_control1_1 =>
                        -- DATA 0x0A Power Control 1
						dc_reg <= DC_DATA;
                        db_reg <= x"0A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwr_control1_2;

                    when Pwr_control1_2 =>
                        -- DATA 0x00 Power Control 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwr_control2;

                    when Pwr_control2 =>
                        -- CMD 0xC1 Power Control 2
						dc_reg <= DC_CMD;
                        db_reg <= x"C1";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwr_control2_1;

                    when Pwr_control2_1 =>
                        -- DATA 0x02 Power Control 2
						dc_reg <= DC_DATA;
                        db_reg <= x"02";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset;

                    when Xadrset =>
                        -- CMD 0x2A XADRSET
						dc_reg <= DC_CMD;
                        db_reg <= x"2A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_1;

                    when Xadrset_1 =>
                        -- DATA 0x00 XADRSET 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_2;

                    when Xadrset_2 =>
                        -- DATA 0x00 XADRSET 2
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_3;

                    when Xadrset_3 =>
                        -- DATA 0x00 XADRSET 3
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_4;

                    when Xadrset_4 =>
                        -- DATA 0x7F XADRSET 4
						dc_reg <= DC_DATA;
                        db_reg <= x"7F";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset;

                    when Yadrset =>
                        -- CMD 0x2B YADRSET
						dc_reg <= DC_CMD;
                        db_reg <= x"2B";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_1;

                    when Yadrset_1 =>
                        -- DATA 0x00 YADRSET 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_2;

                    when Yadrset_2 =>
                        -- DATA 0x00 YADRSET 2
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_3;

                    when Yadrset_3 =>
                        -- DATA 0x00 YADRSET 3
						dc_reg <= DC_DATA;
                        db_reg <= x"00";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_4;

                    when Yadrset_4 =>
                        -- DATA 0x9F YADRSET 4
						dc_reg <= DC_DATA;
                        db_reg <= x"9F";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Madctrl;
                        
                    when Madctrl =>
                        -- CMD 0x36 MADCTRL
                        dc_reg <= DC_CMD;
                        db_reg <= x"36";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Madctrl_1;

                    when Madctrl_1 =>
                        -- DATA 0x48 MADCTRL
                        dc_reg <= DC_DATA;
                        db_reg <= x"48";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Colmod;

                    when Colmod =>
                        -- CMD 0x3A COLMOD
                        dc_reg <= DC_CMD;
                        db_reg <= x"3A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Colmod_1;

                    when Colmod_1 =>
                        -- DATA 0x66 COLMOD
                        dc_reg <= DC_DATA;
                        db_reg <= x"66";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Dspon;

                     when Dspon =>
                        -- CMD 0x29 DISPON
						dc_reg <= DC_CMD;
                        db_reg <= x"29";
                        curr_state <= SendToDisplayDriver;
                        next_state <= DsponWait;

                        -- wait 50 ms after DISPON
                        delay_cycles := 6250000;

                    when DsponWait =>
						if delay_cycles = 0 then
							curr_state <= Finished;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when Finished => 
						ready_reg <= '1';

                    --

                    when SendToDisplayDriver =>
                        if i_driver_ready = '1' then
                    	   ws_reg <= '1';
                    	   curr_state <= WaitForDisplayDriver;
                        end if;

                    when WaitForDisplayDriver =>
                        ws_reg <= '0';
                    	if i_driver_ready = '1' and last_driver_ready = '0' then
                    	   curr_state <= next_state;
                    	end if;

                    --

                    when others =>
                        curr_state <= Finished;

            	end case;
            
            end if;
            
            last_driver_ready <= i_driver_ready;
             
        end if;
    end process init_sequence;

    -- output the register buffers to the ports
    o_write_start   <= ws_reg;
    o_dc            <= dc_reg;
    o_db            <= db_reg;
    o_rs_tft        <= rs_reg; 

    o_ready         <= ready_reg;

end Behavioral;
