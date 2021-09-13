-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- Transmitter baud rate generator
--
-- The firmware performs the following functions:
--
-- Receiver the required Buad rate for the transmitter.
-- The baud rate signal is then provide to the transmitter, this signal is
-- used to set the bit rate inside the transmitter.
--
-- Signals and registers
-- Bit_Rate_cnt:  this signal is used to count the 50MHz clock and provide the
-- bit rate to the transmitter as required.
-- 
---------------------
---------------------

-- Written by  : Glen Taylor
-- Edited By   : Monde Manzini  
-- Tested      : 26/05/2016 Simulation only - Buad rate Test.
--             : Test Bench file name- Baud_Rate_Generator_Test_Bench 
--               located at https://katfs.kat.ac.za/svnAfricanArray/Software Repository/CommonCode/ScrCommon
--             : Test do file is Baud_Rate_Generator_Test_Bench.do 
--               https://katfs.kat.ac.za/svnAfricanArray/Software Repository/CommonCode/Modelsim
-- Last update : Monde Manzini 26/05/2016
--               Added Header 

---------------------
---------------------
-- Last update          : Monde Manzini 06/02/2017  
--                      : Updated Header
--                      : Added Version Control
-- Version              : 1.1 
-- Change Note          : 
-- Tested               : 07/02/2017
-- Type of Test         : (Simulation only).
-- Test Bench file Name : Baud_Rate_Generator_Test_Bench
-- located at           : (https://katfs.kat.ac.za/svnAfricanArray/Software
--                        Repository/CommonCode/ScrCommon)
-- Test do file         : Baud_Rate_Generator_Test_Bench.do
-- located at            (https://katfs.kat.ac.za/svnAfricanArray/Software
--                        Repository/CommonCode/Modelsim)
-- Outstanding          : Integrated testing
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Baud_Rate_Generator is

  port (
    CLK                                 : in  std_logic;
    RST_I                               : in  std_logic;
-- Baud_Rate
    baud_rate                           : in  integer range 0 to 7;
-- Enabe_Clock
    Module_Number                       : in  std_logic_vector(7 downto 0);
    Baud_Rate_Generator_Version_Request : in  std_logic; 
    Baud_Rate_Generator_Version_Name    : out std_logic_vector(255 downto 0);
    Baud_Rate_Generator_Version_Number  : out std_logic_vector(63 downto 0);
    Baud_Rate_Generator_Version_Ready   : out std_logic; 
    Baud_Rate_Enable                    : out std_logic
    );
end Baud_Rate_Generator;

architecture Arch_DUT of Baud_Rate_Generator is

  signal baud_rate_reload     : integer range 0 to 6000;

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

constant Zero     : std_logic_vector(7 downto 0) := X"30";
constant One      : std_logic_vector(7 downto 0) := X"31";
constant Two      : std_logic_vector(7 downto 0) := X"32";
constant Three    : std_logic_vector(7 downto 0) := X"33";
constant Four     : std_logic_vector(7 downto 0) := X"34";
constant Five     : std_logic_vector(7 downto 0) := X"35";
constant Six      : std_logic_vector(7 downto 0) := X"36";
constant Seven    : std_logic_vector(7 downto 0) := X"37";
constant Eight    : std_logic_vector(7 downto 0) := X"38";
constant Nine     : std_logic_vector(7 downto 0) := X"39";

signal Baud_Rate_Generator_Version_Name_i     : std_logic_vector(255 downto 0); 
signal Baud_Rate_Generator_Version_Number_i   : std_logic_vector(63 downto 0);  
begin

  baud_rate_gen : process (Clk, RST_I)
    variable Baud_rate_cnt : integer range 0 to 6000;

  begin  -- process baud_rate_gen
    if RST_I = '0' then
       Baud_Rate_Enable                     <= '0';
       Baud_rate_cnt                        := 0;
       Baud_Rate_Generator_Version_Name     <= (others => '0');
       Baud_Rate_Generator_Version_Name_i   <= (others => '0');
       Baud_Rate_Generator_Version_Number   <= (others => '0'); 
       Baud_Rate_Generator_Version_Number_i <= (others => '0');
       Baud_Rate_Generator_Version_Ready    <= '0'; 
            report "The version number of Baud_Rate_Generator is 1.1." severity note;  -- [for simulation purpose - Must decide]
    elsif CLK'event and CLK = '1' then

       Baud_Rate_Generator_Version_Name_i    <= B & A & U & D & Space & R & A & T & E & Space & G & E & N & E & R & A & T & O & R &
                                               Space & Space & Space & Space & Space & Space & Space & Space &
                                               Space & Space & Space & Space & Space;
       Baud_Rate_Generator_Version_Number_i  <= Zero & Zero & Dot & Zero & One  & Dot & Zero & One;  
      
       if Module_Number = X"0a" then
          if Baud_Rate_Generator_Version_Request = '1' then
             Baud_Rate_Generator_Version_Ready    <= '1';
             Baud_Rate_Generator_Version_Name     <= Baud_Rate_Generator_Version_Name_i;
             Baud_Rate_Generator_Version_Number   <= Baud_Rate_Generator_Version_Number_i;  
          else
             Baud_Rate_Generator_Version_Ready <= '0';
          end if;
       else   
           Baud_Rate_Generator_Version_Ready <= '0'; 
       end if; 
       
      case baud_rate is
        when 0      =>                  -- 9600
          Baud_rate_reload <= 5208;     
        when 1      =>                  -- 19200
          Baud_rate_reload <= 2603;
        when 2      =>                  -- 38400
          Baud_rate_reload <= 1301;
        when 3      =>                  -- 57600
          Baud_rate_reload <= 868;
        when 4      =>                  -- 76800
          Baud_rate_reload <= 651;          
        when 5      =>                  --115200
          Baud_rate_reload <= 433;
        when others =>                  -- 9600
          Baud_rate_reload <= 5208;
      end case;

      if Baud_rate_cnt = 0 then
         Baud_rate_cnt     := Baud_rate_reload;
         Baud_Rate_Enable  <= '1';
      else
         Baud_rate_cnt     := Baud_rate_cnt - 1;
         Baud_Rate_Enable  <= '0';
      end if;
    end if;
  end process baud_rate_gen; 

end Arch_DUT;


