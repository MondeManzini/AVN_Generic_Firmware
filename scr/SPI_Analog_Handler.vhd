-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- Ghana BM0 SPI ADC Handler
--
-- The firmware performs the following functions:
--
-- IConfiguration of the device.
-- Performing a read of each channel ever 0.75mSec.
-- Data is stored in the following address and the data will be stored
-- the user can read the channels at any time, the data is only valid for
-- 1mSec and will be up dated.
-- channel As below.
--
--
-- Signals and registers
-- Bit_Rate_Enable:  this signal is used for the 2Mhz clock for the SPI driver
-- TEN_PPS        :  is the 100mSec input signal which is used to start a conversion
--                   cycle for the next 8 ADC channels.
--
-- Firmware updated to handle 4 chip selects CS1, CS2, CS3 and CS4
-- and communicate to 3 AD7888 Chips Per Analog Card
-- Firmware uses one state machine that reads all three ADCs onthe analog card

--
-- Written by  : Raphael van Rensburg
-- Tested      : 16/02/2014
--              
-- Last update : 16/09/2014 - Monde Manzini
-- Last update : 29/05/2016 - Monde Manzini
--              - Added Analog Data Requests
--              - Added the Version Control
--              - Updated Header with date
--              - Testbench: SPI_Analog_Handler_Test_Bench located at
--                https://katfs.kat.ac.za/svnAfricanArray/SoftwareRepository/CommonCode/ScrCommon
--              - SPI_Analog_Handler_Test_Bench.do file located at
--                https://katfs.kat.ac.za/svnAfricanArray/SoftwareRepository/CommonCode/Modelsim/ 
-- Outstanding :
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.Version_Ascii.all;

entity SPI_Analog_Handler is

  port (
    -- General Signals                  
    RST_I                              : in std_logic;
    CLK_I                              : in std_logic;
    -- SPI Output
    Address_out                        : out std_logic_vector(2 downto 0);
    convert                            : out std_logic;
    --SPI Input
    AD_data_in                         : in  std_logic_vector(15 downto 0);
    Data_valid                         : in  std_logic;    
    -- ADC Channel Outputs
    Analog_Data                        : out std_logic_vector(767 downto 0);
    Chip_Select                        : out std_logic_vector(3 downto 0); 
    Data_Ready                         : out std_logic;
    Ana_In_Request                     : in  std_logic;
    Module_Number                      : in  std_logic_vector(7 downto 0);
    SPI_Analog_Handler_Version_Request : in  std_logic;
    SPI_Analog_Handler_Version_Name    : out std_logic_vector(255 downto 0); 
    SPI_Analog_Handler_Version_Number  : out std_logic_vector(63 downto 0);
    SPI_Analog_Handler_Version_Ready   : out std_logic 
    ); 

end SPI_Analog_Handler;

architecture Arch_DUT of SPI_Analog_Handler is

  constant CH0 : std_logic_vector(2 downto 0) := b"000";
  constant CH1 : std_logic_vector(2 downto 0) := b"001";
  constant CH2 : std_logic_vector(2 downto 0) := b"010";
  constant CH3 : std_logic_vector(2 downto 0) := b"011";
  constant CH4 : std_logic_vector(2 downto 0) := b"100";
  constant CH5 : std_logic_vector(2 downto 0) := b"101";
  constant CH6 : std_logic_vector(2 downto 0) := b"110";
  constant CH7 : std_logic_vector(2 downto 0) := b"111";

signal SPI_Analog_Handler_Version_Name_i   : std_logic_vector(255 downto 0); 
signal SPI_Analog_Handler_Version_Number_i : std_logic_vector(63 downto 0); 

-- type Analog_Array is array (0 to 767) of std_logic_vector(15 downto 0);
-- signal Analog_Data_Array                   : Analog_Array;
signal Analog_Data_Array_i                   : std_logic_vector(767 downto 0);


  type SPI_Drive_states is (Idle,Convertion_Dummy_1,Wait_Dummy_1, Data_Wait_State,
                           Next_Channel_State, Iterate_State);
  
  signal SPI_Drive_state        : SPI_Drive_states;  

  signal EnableRateGenarator    : std_logic;
  signal Bit_Rate_Enable        : std_logic;
  signal SPI_data_o             : std_logic_vector(15 downto 0);
  signal SPI_data_i             : std_logic_vector(15 downto 0);

  signal Chip_Select_i          : std_logic_vector(3 downto 0);
  signal Send_i                 : std_logic;
  signal data_ok                : std_logic;
  signal data_ok_latch          : std_logic;
  signal data_valid_latch       : std_logic;
  signal Data_Ready_i           : std_logic;  
  
  begin
    
Data_Ready  <= Data_Ready_i;
Chip_Select <= Chip_Select_i;
Analog_Data <= Analog_Data_Array_i;
-- SPI driver read all 8 channel automatically
   SPI_Driver: process (CLK_I, RST_I)
      variable Channel_cnt    : integer range 0 to 8;
      variable wait_cnt       : integer range 0 to 60;
      variable addr_cnt       : integer range 0 to 50;
      variable Cycle_cnt      : integer range 0 to 50;
      variable data_valid_cnt : integer range 0 to 100;
    begin
      if RST_I = '0' then 
         Channel_cnt    	                  := 0;
         Cycle_cnt                           := 0;
         wait_cnt                            := 0;
         addr_cnt                            := 0;
         data_valid_cnt                      := 0;
         Address_out		                     <= ( others => '0');
         convert                             <= '0';                     
         Chip_Select_i                       <= x"0";
         Analog_Data_Array_i                 <= ( others => '0');    
         Analog_Data                         <= ( others => '0');    
         SPI_Drive_state                     <= Idle;
         Data_Ready_i                        <= '0';
         data_ok                             <= '0';
         data_ok_latch                       <= '0';
         data_valid_latch                    <= '0';
         SPI_Analog_Handler_Version_Name     <= (others => '0');
         SPI_Analog_Handler_Version_Name_i   <= (others => '0');
         SPI_Analog_Handler_Version_Number   <= (others => '0'); 
         SPI_Analog_Handler_Version_Number_i <= (others => '0');
         SPI_Analog_Handler_Version_Ready    <= '0'; 
         report "The version number of SPI_Analog_Handler is 00.01.01." severity note;  
      elsif CLK_I'event and CLK_I = '1' then          
                  
         SPI_Analog_Handler_Version_Name_i   <= S & P & I & Space & A & N & A & L & O & G & Space & H & A & N & D & L & E & R &
                                                Space & Space & Space & Space & Space & Space & Space & 
                                                Space & Space & Space & Space & Space & Space & Space;
                                                
         SPI_Analog_Handler_Version_Number_i <= Zero & Zero & Dot & Zero & One & Dot & Zero & One;

         if Module_Number = X"05" then
            if SPI_Analog_Handler_Version_Request = '1' then
               SPI_Analog_Handler_Version_Ready  <= '1';
               SPI_Analog_Handler_Version_Name   <= SPI_Analog_Handler_Version_Name_i;
               SPI_Analog_Handler_Version_Number <= SPI_Analog_Handler_Version_Number_i;  
            else
               SPI_Analog_Handler_Version_Ready  <= '0';
            end if;
         else   
               SPI_Analog_Handler_Version_Ready  <= '0'; 
         end if; 

-- SPI Driver CB25a State Machine
         case SPI_Drive_State is
            when Idle =>
               Data_Ready_i   <= '0';
               Chip_Select_i  <= x"0";
               addr_cnt       := 0;
               Cycle_cnt      := 0;
               if Ana_In_Request = '1' then  -- Chip_Select_Array  
                 SPI_Drive_state    <= Convertion_Dummy_1;
               else
                  SPI_Drive_state   <= Idle;   
               end if;   
					
-- Channel zero chip 1
         when Convertion_Dummy_1 =>  
            case addr_cnt is
               when 0 =>
                  Address_out    <= CH0;   
               when 1 =>
                  Address_out    <= CH1; 
               when 2 =>
                  Address_out    <= CH2; 
               when 3 =>
                  Address_out    <= CH3; 
               when 4 =>
                  Address_out    <= CH4; 
               when 5 =>
                  Address_out    <= CH5; 
               when 6 =>
                  Address_out    <= CH6; 
               when 7 =>
                  Address_out    <= CH7; 
               when others =>
            end case;
            data_ok_latch     <= '0';
            data_valid_latch  <= '0';
            convert           <= '1';
            SPI_Drive_State   <= Wait_Dummy_1;
                              
         when Wait_Dummy_1 =>
               convert   <= '0';                              
               if Data_valid = '1' then
                  data_valid_latch  <= '1';
               end if; 

               if data_valid_latch = '1' then
                  if data_valid_cnt = 50 then 
                     data_valid_cnt    := 0;
                     data_ok           <= '1';
                     SPI_Drive_State   <= Data_Wait_State;
                  else
                     data_valid_cnt := data_valid_cnt + 1; 
                     --for i in 0 to 47 loop
                        --Analog_Data_Array_i((i+15) downto i)) <= AD_data_in;
                        --Analog_Data_Array_i(767-(i * (15 + i)) downto 751-(i * (15 + i)))
                        --767-0 downto 751-0 = 767 downto 751 
                        --767-(1 * 15 + 1) downto 751-(1 * 15 + 1) = 750 downto 734
                        --767-(2 * 15 + 2) downto 751-(2 * 15 + 2) = 735 downto 719

                        --15+(0 * (15 + 1)) downto 0+(0 * (15 + 1)) = 15 downto 0
                        --15+(1 * (15 + 1)) downto 0+(1 * (15 + 1)) = 31 downto 16
                        --15+(2 * (15 + 1)) downto 0+(2 * (15 + 1)) = 47 downto 32
                        --15+(3 * (15 + 1)) downto 0+(3 * (15 + 1)) = 63 downto 48
                        --15+(4 * (15 + 1)) downto 0+(4 * (15 + 1)) = 79 downto 64

                        Analog_Data_Array_i((15+(Cycle_cnt * 16)) downto (0+(Cycle_cnt * 16)))   <= AD_data_in; 

                        if Cycle_cnt < 8 then
                           Chip_Select_i  <= x"1";
                           --data_ok        <= '1';
                        elsif Cycle_cnt > 7 and Cycle_cnt < 17 then
                           Chip_Select_i  <= x"2";
                           --data_ok        <= '1';
                        elsif Cycle_cnt > 15 and Cycle_cnt < 25 then
                           Chip_Select_i  <= x"3";
                           --data_ok                <= '1';
                        elsif Cycle_cnt > 24 and Cycle_cnt < 33 then
                           Chip_Select_i  <= x"4";
                           --data_ok                <= '1';
                        elsif Cycle_cnt > 32 and Cycle_cnt < 41 then
                           Chip_Select_i  <= x"8";
                           --data_ok                <= '1';
                        elsif Cycle_cnt > 39 and Cycle_cnt < 48 then
                           Chip_Select_i  <= x"c";
                           --data_ok        <= '1';
                        end if;
                     --end loop;
                  end if;
               end if;

         when Data_Wait_State =>
               
               if data_ok = '1' then
                  data_ok_latch     <= '1';
                  data_valid_latch  <= '0';
               end if;

               if data_ok_latch = '1' then
                  data_ok     <= '0';
                  if wait_cnt = 60 then
                     wait_cnt          := 0;
                     Cycle_cnt         := Cycle_cnt + 1;
                     SPI_Drive_State   <= Next_Channel_State;
                  else
                     wait_cnt    := wait_cnt + 1;
                  end if;
               end if;   

         when Next_Channel_State =>
            data_ok_latch     <= '0';
            if addr_cnt < 8 then
               addr_cnt          := addr_cnt + 1;
               SPI_Drive_State   <= Iterate_State;
            elsif addr_cnt > 7 then
               addr_cnt          := 0;
               SPI_Drive_State   <= Iterate_State;
            end if;

         when Iterate_State =>
            if Cycle_cnt > 0 and Cycle_cnt < 9 then
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt > 8 and Cycle_cnt < 17 then
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt > 16 and Cycle_cnt < 25 then
            -- addr_cnt          := addr_cnt + 1;
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt > 24 and Cycle_cnt < 33 then
            -- addr_cnt          := addr_cnt + 1;
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt > 32 and Cycle_cnt < 41 then
                --addr_cnt          := addr_cnt + 1;
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt > 40 and Cycle_cnt < 48 then
                --addr_cnt          := addr_cnt + 1;
               SPI_Drive_State   <= Convertion_Dummy_1;
            elsif Cycle_cnt = 48 then
               SPI_Drive_State   <= Idle;
               Data_Ready_i      <= '1';
               Cycle_cnt         := 0;
            end if;
            
         when others =>
            SPI_Drive_State      <= Idle;  
      end case;
       
      end if;
    end process SPI_Driver;  
  end Arch_DUT;
