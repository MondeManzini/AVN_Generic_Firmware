-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- Kutunse SPI Addressable Port for AD7888 ADC
--
-- The firmware performs the following functions:
--
-- IConfiguration of the device.
-- Performing a read of each channel ever 100mSec.
-- Data is stored in the following address and the data will be stored
-- the user can read the channels at any time, the data is only valid for
-- 100mSec and will be up dated.
-- The method would be to place the address in the ADR_I register and issue a WE_
-- I signal for one ckl cycle only,one clock later the DAT_O will have the four
-- channel As below.
-- 
-- Firmware updtated to handle 4 chip selects CS1, CS2, CS3 and CS4
--
-- Signals and registers
-- Bit_Rate_Enable:  this signal is used for the 2Mhz clock for the SPI driver
-- TEN_PPS        :  is the 100mSec input signal which is used to start a conversion
--                   cycle for the next 8 ADC channels.
-- 
--
-- Written by  : Raphael van Rensburg
-- Tested      : 09/02/2012 Simulation only - Initialiation. SPI read and writes,
--               data
--             : Test do file is SPI_ADC.do
-- Last update : 08/08/2014 - Initial release  Version 1.0
-- Outstanding : 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity SPI_Analog_Driver is

  port (
    -- General Signals                  
    RST_I                             : in std_logic;
    CLK_I                             : in std_logic;
    --SPI control signals
    CS1                               : in  std_logic; 
    CS2                               : in  std_logic; 
    CS3                               : in  std_logic; 
    CS4                               : in  std_logic;
    nCS                               : out std_logic;
    Address                           : in  std_logic_vector(2 downto 0);
    convert                           : in  std_logic;
    -- SPI Pins	 
    nCS_1                             : out std_logic;
    nCS_2                             : out std_logic;
    nCS_3                             : out std_logic;
    nCS_4                             : out std_logic;		 
    Sclk                              : out std_logic;
    Mosi                              : out std_logic;                     --to SPI device
    Miso                              : in  std_logic;                     --from SPI device
    -- Data
    AD_data                           : out std_logic_vector(15 downto 0);
    Data_valid                        : out std_logic;
    -- Version Control
    Module_Number                     : in  std_logic_vector(7 downto 0);
    SPI_Analog_Driver_Version_Request : in  std_logic;
    SPI_Analog_Driver_Version_Name    : out std_logic_vector(255 downto 0); 
    SPI_Analog_Driver_Version_Number  : out std_logic_vector(63 downto 0);
    SPI_Analog_Driver_Version_Ready   : out std_logic 
    );

end SPI_Analog_Driver;

architecture Arch_DUT of SPI_Analog_Driver is

  constant Dontc                 : std_logic                    := '0';
  constant Zero                  : std_logic                    := '0';
  constant Ref_enabled           : std_logic                    := '0';
  constant Ref_disabled          : std_logic                    := '1';
  
  constant PM10_normal_operation : std_logic_vector             := "00";
  constant PM10_full_shutdown    : std_logic_vector             := "01";
  constant PM10_auto_shutdown    : std_logic_vector             := "10";
  constant PM10_auto_standby     : std_logic_vector             := "11";
  constant pad_byte              : std_logic_vector             := X"00";
   
--------------
-- Ascii Codes
--------------   
constant A        : std_logic_vector(7 downto 0) := X"41";
constant B        : std_logic_vector(7 downto 0) := X"42";
constant C        : std_logic_vector(7 downto 0) := X"43";
constant D        : std_logic_vector(7 downto 0) := X"44";
constant E        : std_logic_vector(7 downto 0) := X"45";
constant F        : std_logic_vector(7 downto 0) := X"46";
constant G        : std_logic_vector(7 downto 0) := X"47";
constant H        : std_logic_vector(7 downto 0) := X"48";
constant I        : std_logic_vector(7 downto 0) := X"49";
constant J        : std_logic_vector(7 downto 0) := X"4A";
constant K        : std_logic_vector(7 downto 0) := X"4B";
constant L        : std_logic_vector(7 downto 0) := X"4C";
constant M        : std_logic_vector(7 downto 0) := X"4D";
constant N        : std_logic_vector(7 downto 0) := X"4E";
constant O        : std_logic_vector(7 downto 0) := X"4F";
constant P        : std_logic_vector(7 downto 0) := X"50";
constant Q        : std_logic_vector(7 downto 0) := X"51";
constant R        : std_logic_vector(7 downto 0) := X"52";
constant S        : std_logic_vector(7 downto 0) := X"53";
constant T        : std_logic_vector(7 downto 0) := X"54";
constant U        : std_logic_vector(7 downto 0) := X"55";
constant V        : std_logic_vector(7 downto 0) := X"56";
constant W        : std_logic_vector(7 downto 0) := X"57";
constant X        : std_logic_vector(7 downto 0) := X"58";
constant Y        : std_logic_vector(7 downto 0) := X"59";
constant Z        : std_logic_vector(7 downto 0) := X"5A";
constant Space    : std_logic_vector(7 downto 0) := X"20";
constant Dot      : std_logic_vector(7 downto 0) := X"2E";

constant ZeroE    : std_logic_vector(7 downto 0) := X"30";
constant One      : std_logic_vector(7 downto 0) := X"31";
constant Two      : std_logic_vector(7 downto 0) := X"32";
constant Three    : std_logic_vector(7 downto 0) := X"33";
constant Four     : std_logic_vector(7 downto 0) := X"34";
constant Five     : std_logic_vector(7 downto 0) := X"35";
constant Six      : std_logic_vector(7 downto 0) := X"36";
constant Seven    : std_logic_vector(7 downto 0) := X"37";
constant Eight    : std_logic_vector(7 downto 0) := X"38";
constant Nine     : std_logic_vector(7 downto 0) := X"39";

signal SPI_Analog_Driver_Version_Name_i   : std_logic_vector(255 downto 0); 
signal SPI_Analog_Driver_Version_Number_i : std_logic_vector(63 downto 0); 

  type SPI_Drive_states is (idle,Convertion_Start,CS_on,FE_1,RE_1,Cycle_cnt,wait_1,Wait_Bit_Rate_1,Wait_Bit_Rate_2);
  
  signal SPI_Drive_state       : SPI_Drive_states;  

  signal EnableRateGenarator   : std_logic;
  signal Bit_Rate_Enable       : std_logic;
  signal SPI_data_o            : std_logic_vector(15 downto 0);
  signal SPI_data_i            : std_logic_vector(15 downto 0);
  signal nCS_i                 : std_logic;
  signal CS1_i                 : std_logic;
  signal CS2_i                 : std_logic;  
  signal CS3_i                 : std_logic;
  signal CS4_i                 : std_logic;
  signal OuS_Enable_i          : std_logic;
 
  begin
 
 nCS_1           <= CS1_i;
 nCS_2           <= CS2_i;
 nCS_3           <= CS3_i;
 nCS_4           <= CS4_i;
 nCS             <= nCS_i;
   
-- SPI driver read all 8 channel automatically
    SPI_Driver: process (CLK_I, RST_I)
      variable bit_cnt       : integer range 0 to 50;
      variable bit_number    : integer range 0 to 16;
      variable wait_bit_cnt  : integer range 0 to 60;
    begin
      if RST_I = '0' then 
         bit_cnt                            := 0;
         bit_number                         := 16;
         wait_bit_cnt                       := 0;
         Bit_Rate_Enable                    <= '0';
         Sclk                               <= '1'; 
         nCS_i                              <= '1';
         CS1_i                              <= '0';
         CS2_i                              <= '0';
         CS3_i                              <= '0';
         CS4_i                              <= '0'; 			
         MOSI                               <= 'Z';
         Data_valid                         <= '0';
         AD_data                            <= (others => '0');
         SPI_data_o                         <= (others => '0');
         SPI_data_i                         <= (others => '0');         
         EnableRateGenarator                <= '0';
         SPI_Analog_Driver_Version_Name     <= (others => '0');
         SPI_Analog_Driver_Version_Name_i   <= (others => '0');
         SPI_Analog_Driver_Version_Number   <= (others => '0'); 
         SPI_Analog_Driver_Version_Number_i <= (others => '0');
         SPI_Analog_Driver_Version_Ready    <= '0'; 
              report "The version number of SPI_Analog is 1.0." severity note;  
      elsif CLK_I'event and CLK_I = '1' then

         SPI_Analog_Driver_Version_Name_i   <= S & P & I & Space & A & N & A & L & O & G & Space & D & R & I & V & E & R &
                                               Space & Space & Space & Space & Space & Space & Space & 
                                               Space & Space & Space & Space & Space & Space & Space &
                                               Space;
         SPI_Analog_Driver_Version_Number_i <= ZeroE & ZeroE & Dot & ZeroE & One & Dot & ZeroE & Two;

         if Module_Number = X"04" then
            if SPI_Analog_Driver_Version_Request = '1' then
               SPI_Analog_Driver_Version_Ready   <= '1';
               SPI_Analog_Driver_Version_Name    <= SPI_Analog_Driver_Version_Name_i;
               SPI_Analog_Driver_Version_Number  <= SPI_Analog_Driver_Version_Number_i;  
            else
               SPI_Analog_Driver_Version_Ready <= '0';
            end if;
         else   
               SPI_Analog_Driver_Version_Ready <= '0'; 
         end if; 

-- Bit clock 50MHz to 2MHz 50MHz = 20 nSec 2MHz = 500 nSEC 500/20 = 25
         if EnableRateGenarator = '1' then
            bit_cnt                  := bit_cnt + 1;
         end if;            

         if bit_cnt = 25 then
            Bit_Rate_Enable          <= '1';
            bit_cnt                  := 0;                      
         else
            Bit_Rate_Enable          <= '0';                 
         end if;
         
         if nCS_i = '0' then                                       
	          CS1_i             <= CS1;
            CS2_i             <= CS2;
            CS3_i             <= CS3;
            CS4_i             <= CS4;                       
         else
            CS1_i             <= '0';
            CS2_i             <= '0';
            CS3_i             <= '0';
            CS4_i             <= '0'; 
         end if;
                             
-- SPI Driver State Machine
         case SPI_Drive_State is
          when idle =>
               Sclk                   <= '1';
               nCS_i                  <= '1';
               MOSI                   <= 'Z';
               Data_valid             <= '0';
               if convert = '1' then
                  bit_number          := 16;
                  bit_cnt             := 0;
                  EnableRateGenarator <= '1';
                  SPI_Drive_State     <= Convertion_Start;
               end if;
               
          when Convertion_Start =>            
               SPI_data_i             <= Dontc & Zero & Address
                                         & Ref_enabled & PM10_normal_operation
                                         & pad_byte;
               nCS_i                  <= '0';
               SPI_Drive_State        <= CS_on;
               
                          

-- Chip Sellect assertion               
          when CS_on =>
                         
               SPI_Drive_State    <= FE_1;
-- Falling edge genaration
          when FE_1 =>
               Sclk             <= '0';               
               if (bit_number > 9) or(bit_number = 9) then
                  MOSI          <= SPI_data_i(bit_number - 1);
               else
                  MOSI          <= 'Z';
               end if;
               SPI_Drive_State  <= Wait_Bit_Rate_1;
               
          when Wait_Bit_Rate_1 =>     
               if Bit_Rate_Enable = '1' then                                
                  SPI_Drive_State  <= RE_1;
               else
                  SPI_Drive_State  <= Wait_Bit_Rate_1;   
               end if;
-- Rising edge genaration
          when RE_1 =>
               Sclk             <= '1';
               SPI_data_o(bit_number - 1) <= MISO;
               SPI_Drive_State            <= Wait_Bit_Rate_2;
               
           when Wait_Bit_Rate_2 =>     
               if Bit_Rate_Enable = '1' then                                                      
                  SPI_Drive_State         <= Cycle_cnt;
               else
                  SPI_Drive_State         <= Wait_Bit_Rate_2;   
               end if;
               
--Cycle counter for testing number of Bit send and recieved
          when Cycle_cnt =>
               bit_number := bit_number - 1;
               if bit_number = 0  then                 
                  SPI_Drive_State          <= wait_1;
                  AD_data                  <= SPI_data_o;
               else
                  SPI_Drive_State          <= FE_1;
               end if;

          when wait_1 =>
              
               if wait_bit_cnt = 50 then
                  Data_valid             <= '1';
                  SPI_Drive_State        <= idle;
                  EnableRateGenarator    <= '0';                   
                  wait_bit_cnt           := 0;   
               elsif wait_bit_cnt = 5 then 
                   nCS_i                 <= '1';
                   wait_bit_cnt          :=  wait_bit_cnt + 1;
               else
                   wait_bit_cnt          :=  wait_bit_cnt + 1;
               end if;
                
          when others =>
               SPI_Drive_State <= idle;  
         end case;    
      end if;
    end process SPI_Driver;  
  end Arch_DUT;

