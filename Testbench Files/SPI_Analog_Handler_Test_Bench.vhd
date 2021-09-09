-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- This file contains  modules which make up a testbench
-- suitable for testing the "device under test".
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

--library modelsim_lib;
--use modelsim_lib.util.all;

entity SPI_Analog_Handler_Test_Bench is

end SPI_Analog_Handler_Test_Bench;

architecture Archtest_bench of SPI_Analog_Handler_Test_Bench is
	

  component test_bench_T
    generic (
      Vec_Width  : positive := 4;
      ClkPer     : time     := 20 ns;
      StimuFile  : string   := "data.txt";
      ResultFile : string   := "results.txt"
      );
    port (
      oVec : out std_logic_vector(Vec_Width-1 downto 0);
      oClk : out std_logic;
      iVec : in std_logic_vector(3 downto 0)
      );
  end component;
  
  -- SPI Analog Driver Signals and Component
signal Address_i                            : std_logic_vector(2 downto 0);
signal nCS_1_i                              : std_logic;
signal nCS_2_i                              : std_logic;
signal nCS_3_i                              : std_logic;
signal nCS_4_i                              : std_logic;
signal Sclk_i                               : std_logic;
signal Mosi_i                               : std_logic;
signal Miso_i                               : std_logic;
signal Version_Driver_i                     : std_logic_vector(7 downto 0);
signal Address_out_1_i                      : std_logic_vector(2 downto 0);
signal Address_out_2_i                      : std_logic_vector(2 downto 0);
signal Data_valid_1_i                       : std_logic;
signal Data_valid_2_i                       : std_logic;
signal convert_1_i                          : std_logic;
signal convert_2_i                          : std_logic;
signal Analog_Input_Valid_1_i               : std_logic;
signal Analog_Input_Valid_2_i               : std_logic;
signal nCS_i                                : std_logic;
signal Version_Analog_Driver_i              : std_logic_vector(7 downto 0);
signal SPI_Analog_Driver_Version_Name_i     : std_logic_vector(255 downto 0); 
signal SPI_Analog_Driver_Version_Number_i   : std_logic_vector(63 downto 0);
signal SPI_Analog_Driver_Version_Ready_i    : std_logic;  
signal SPI_Analog_Driver_Version_Request_i  : std_logic; 

  component SPI_Analog_Driver is
    port (
      RST_I                             : in  std_logic;
      CLK_I                             : in  std_logic;
      CS1                               : in  std_logic; 
      CS2                               : in  std_logic; 
      CS3                               : in  std_logic; 
      CS4                               : in  std_logic;
      nCS                               : out std_logic;
      Address                           : in  std_logic_vector(2 downto 0);
      convert                           : in  std_logic;
      nCS_1                             : out std_logic;
      nCS_2                             : out std_logic;
      nCS_3                             : out std_logic;
      nCS_4                             : out std_logic;
      Sclk                              : out std_logic;
      Mosi                              : out std_logic;
      Miso                              : in  std_logic;
      AD_data                           : out std_logic_vector(15 downto 0);
      Data_valid                        : out std_logic;
      Module_Number                     : in  std_logic_vector(7 downto 0);
      SPI_Analog_Driver_Version_Request : in  std_logic;
      SPI_Analog_Driver_Version_Name    : out std_logic_vector(255 downto 0); 
      SPI_Analog_Driver_Version_Number  : out std_logic_vector(63 downto 0);
      SPI_Analog_Driver_Version_Ready   : out std_logic 
      );
  end component SPI_Analog_Driver;

-- SPI Analog Handler Signals and Component
signal Ana_In_Request_i                       : std_logic;
signal Address_out_i                          : std_logic_vector(2 downto 0);
signal convert_i                              : std_logic;
signal CS1_i                                  : std_logic;
signal CS2_i                                  : std_logic;
signal CS3_i                                  : std_logic;
signal CS4_i                                  : std_logic;
signal AD_data_i                              : std_logic_vector(15 downto 0);
signal Data_valid_i                           : std_logic;
signal Channel_i                              : std_logic_vector(775 downto 0);
signal Analog_Data_Valid_i                    : std_logic;
signal Analog_Busy_i                          : std_logic;
signal Version_Handler_i                      : std_logic_vector(7 downto 0);
signal AD_data_1_i                            : std_logic_vector(15 downto 0);
signal AD_data_2_i                            : std_logic_vector(15 downto 0);
signal Data_Ready_i                           : std_logic;
signal Analog_Data_i                          : std_logic_vector(767 downto 0);
signal Version_Analog_Handler_1_i             : std_logic_vector(7 downto 0);
signal Version_Analog_Handler_2_i             : std_logic_vector(7 downto 0);
signal SPI_Analog_Handler_Version_Request_i   : std_logic;
signal SPI_Analog_Handler_Version_Name_i      : std_logic_vector(255 downto 0); 
signal SPI_Analog_Handler_Version_Number_i    : std_logic_vector(63 downto 0);
signal SPI_Analog_Handler_Version_Ready_i     : std_logic;
signal Module_Number_i                        : std_logic_vector(7 downto 0);
signal Chip_Select_i                          : std_logic_vector(3 downto 0);

  component SPI_Analog_Handler is
    port (
      RST_I                               : in  std_logic;
      CLK_I                               : in  std_logic;
      One_mS_pulse                        : in  std_logic;
      Address_out                         : out std_logic_vector(2 downto 0);
      convert                             : out std_logic;
      Chip_Select                         : out std_logic_vector(3 downto 0); 
      AD_data_in                          : in  std_logic_vector(15 downto 0);
      Data_valid                          : in  std_logic;
      Analog_Data                         : out std_logic_vector(767 downto 0);
      Data_Ready                          : out std_logic;
      Ana_In_Request                      : in  std_logic;
      Module_Number                       : in  std_logic_vector(7 downto 0);
      SPI_Analog_Handler_Version_Request  : in  std_logic;
      SPI_Analog_Handler_Version_Name     : out std_logic_vector(255 downto 0); 
      SPI_Analog_Handler_Version_Number   : out std_logic_vector(63 downto 0);
      SPI_Analog_Handler_Version_Ready    : out std_logic 
      );
  end component SPI_Analog_Handler;

-------------------------------------------------------------------------------
-- New Code Signal and Components
------------------------------------------------------------------------------- 
signal RST_I_i                  : std_logic;
signal CLK_I_i                  : std_logic;

signal Request_i                : std_logic;

---------------------------------------
----------------------------------------
-- General Signals
-------------------------------------------------------------------------------
  type Test_states is (idle, Data_Valid_Wait, Data_Valid_Count);
  
  signal Test_state       : Test_states;  


  signal  sClok,snrst,sStrobe,PWM_sStrobe,newClk,Clk : std_logic := '0';
  signal  stx_data,srx_data : std_logic_vector(3 downto 0) := "0000";
  signal  sCnt         : integer range 0 to 7 := 0;
  signal  cont         : integer range 0 to 100;  
  signal  oClk,OneuS_sStrobe, Quad_CHA_sStrobe, Quad_CHB_sStrobe,OnemS_sStrobe,cStrobe,sStrobe_A,Ten_mS_sStrobe,Twenty_mS_sStrobe, Fifty_mS_sStrobe, Hun_mS_sStrobe : std_logic;

begin
      
 RST_I_i         <= snrst;
 CLK_I_i         <= sClok;
 
-------------------------------------------------------------------------------
-- New test Code
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Leave in code
-------------------------------------------------------------------------------   
    T1: test_bench_T
     port map(
       oVec => stx_data,
       oClk => sClok,
       iVec => srx_data
       );             

-- SPI Analog Handler Instance
-- Analog In Handler 1
SPI_Analog_Handler_1: entity work.SPI_Analog_Handler
port map (
  RST_I                               => RST_I_i,
  CLK_I                               => CLK_I_i,
  Address_out                         => Address_out_1_i,
  convert                             => convert_1_i,
  Chip_Select                         => Chip_Select_i, 
  AD_data_in                          => AD_data_1_i,
  Data_valid                          => Data_valid_1_i,
  Analog_Data                         => Analog_Data_i, 
  Data_Ready                          => Analog_Input_Valid_1_i,
  Ana_In_Request                      => Ana_In_Request_i,
  Module_Number                       => Module_Number_i,
  SPI_Analog_Handler_Version_Request  => SPI_Analog_Handler_Version_Request_i,
  SPI_Analog_Handler_Version_Name     => SPI_Analog_Handler_Version_Name_i, 
  SPI_Analog_Handler_Version_Number   => SPI_Analog_Handler_Version_Number_i,
  SPI_Analog_Handler_Version_Ready    => SPI_Analog_Handler_Version_Ready_i  
  );
     
  -- SPI Analog Driver Instance
  SPI_Analog_1: entity work.SPI_Analog_Driver
    port map (
      RST_I                             => RST_I_i,
      CLK_I                             => CLK_I_i,
      CS1                               => Chip_Select_i(0),
      CS2                               => Chip_Select_i(1), 
      CS3                               => Chip_Select_i(2),
      CS4                               => Chip_Select_i(3),
      nCS                               => nCS_i,
      Address                           => Address_out_1_i,
      convert                           => convert_1_i,
      nCS_1                             => nCS_1_i,
      nCS_2                             => nCS_2_i,
      nCS_3                             => nCS_3_i,
      nCS_4                             => nCS_4_i,
      Sclk                              => Sclk_i,
      Mosi                              => Mosi_i,
      Miso                              => Miso_i,
      AD_data                           => AD_data_1_i,
      Data_valid                        => Data_Valid_1_i,
      Module_Number                     => Module_Number_i,
      SPI_Analog_Driver_Version_Request => SPI_Analog_Driver_Version_Request_i,
      SPI_Analog_Driver_Version_Name    => SPI_Analog_Driver_Version_Name_i, 
      SPI_Analog_Driver_Version_Number  => SPI_Analog_Driver_Version_Number_i,
      SPI_Analog_Driver_Version_Ready   => SPI_Analog_Driver_Version_Ready_i 
       );
              
Miso_i    <= -- Card 1 Port 1 to 8 
              '0', '1'  after 1.00425 ms, '0' after 1.00629 ms, '1' after 1.00829 ms,
              '0'       after 1.01033 ms, '1' after 1.01233 ms, '1' after 1.01247 ms, '1' after 1.01637 ms,
              '0'       after 1.01841 ms, '1' after 1.02041 ms, '0' after 1.02245 ms, '0' after 1.02538 ms,
              '1'       after 1.02649 ms, '0' after 1.027 ms, '1'   after 1.029 ms, '0'   after 1.033 ms,
              '0'       after 1.034 ms,   '1' after 1.035 ms, '1'   after 1.039 ms, '0'   after 1.042 ms, 
              '1'       after 1.045 ms,   '0' after 1.047 ms, '0'   after 1.049 ms, '1'   after 1.052 ms, 
              '0'       after 1.055 ms,   '0' after 1.058 ms, '1'   after 1.060 ms, '0'   after 1.062 ms,
              '0'       after 1.063 ms,   '1' after 1.065 ms, '0'   after 1.067 ms,      
              '0'       after 1.081 ms,   '1' after 1.08425 ms, '0' after 1.08629 ms, '1' after 1.08829 ms,
              '1'       after 1.09033 ms, '1' after 1.09233 ms, '0' after 1.09247 ms, '1' after 1.09637 ms,
              '0'       after 1.09841 ms, '1' after 1.10041 ms, '0' after 1.12245 ms, '1' after 1.12538 ms,
              '0'       after 1.144 ms; 
               
Time_Stamping: process (CLK_I_i, RST_I_i)
  
  variable mS_Cnt  : integer range 0 to 7500;
  variable Req_Cnt : integer range 0 to 201;
  begin

    if RST_I_i = '0' then
       mS_Cnt           := 0;
       Ana_In_Request_i <= '0';
       Test_state       <= Idle;
    elsif CLK_I_i'event and CLK_I_i='1' then
       
       if OnemS_sStrobe = '1' then
          Ana_In_Request_i <= '1';
       else
          Ana_In_Request_i <= '0';
       end if;     

    end if;
  end process Time_Stamping;
       
   strobe: process
   begin
     sStrobe <= '0', '1' after 200 ns, '0' after 430 ns;  
     wait for 200 us;
   end process strobe;

   strobe_SPI: process
   begin
     sStrobe_A <= '0', '1' after 200 ns, '0' after 430 ns;  
     wait for 1 ms;
   end process strobe_SPI;
  
    uS_strobe: process
    begin
      OneuS_sStrobe <= '0', '1' after 1 us, '0' after 1.020 us;  
      wait for 1 us;
    end process uS_strobe;

    mS_strobe: process
    begin
      OnemS_sStrobe <= '0', '1' after 1 ms, '0' after 1.00002 ms;  
      wait for 1.0001 ms;
    end process mS_strobe;

  Ten_mS_strobe: process
    begin
      Ten_mS_sStrobe <= '0', '1' after 10 ms, '0' after 10.00002 ms;  
      wait for 10.0001 ms;
    end process Ten_mS_strobe;

  Twenty_mS_strobe: process
    begin
      Twenty_mS_sStrobe <= '0', '1' after 20 ms, '0' after 20.00002 ms;  
      wait for 20.0001 ms;
    end process Twenty_mS_strobe;

  Fifty_mS_strobe: process
    begin
      Fifty_mS_sStrobe <= '0', '1' after 50 ms, '0' after 50.00002 ms;  
      wait for 50.0001 ms;
    end process Fifty_mS_strobe;  

  Hun_mS_strobe: process
    begin
      Hun_mS_sStrobe <= '0', '1' after 100 ms, '0' after 100.00002 ms;  
      wait for 100.0001 ms;
    end process Hun_mS_strobe;   

 
  Gen_Clock: process
  begin
    newClk <= '0', '1' after 40 ns;
    wait for 80 ns;
  end process Gen_Clock;
  
  Do_reset: process(sClok)
  begin
    if (sClok'event and sClok='1') then 
      if sCnt = 7 then
        sCnt <= sCnt;
      else 
        sCnt <= sCnt + 1;

        case sCnt is
          when 0 => snrst <= '0';
          when 1 => snrst <= '0';
          when 2 => snrst <= '0';
          when 3 => snrst <= '0';
          when 4 => snrst <= '0';
          when others => snrst <= '1';
        end case;

      end if;
   
  end if;
  end process;

end Archtest_bench;

