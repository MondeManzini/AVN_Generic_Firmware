
-- ===========
--
-- APE Test System FPGA Firmware Top Module
--
-- 
-- Written by       : Monde Manzini
-- Tested           : 
-- Last update      : 09/06/2021 
-- Version          :  

-- Last update      : 29/06/2021 
--                  : Removed RF Controller Modules

-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Analog_Input_Test_Code is

  port (

--------------------------Clock Input  ---------------------------------
    CLOCK_50                            : in    std_logic;                      --      50 MHz          
--------------------------Push Button  ---------------------------------                        
    KEY                                 : in    std_logic_vector(1 downto 0);   --      Pushbutton[1:0]                   
--------------------------DPDT Switch  ---------------------------------
    SW                                  : in    std_logic_vector(3 downto 0);   --      Toggle Switch[3:0]              
--------------------------LED    ------------------------------------
    LED                                 : out   std_logic_vector(7 downto 0);   --      LED [7:0]     
--------------------------SDRAM Interface  ---------------------------
    --DRAM_DQ                             : inout std_logic_vector(15 downto 0);  --      SDRAM Data bus 16 Bits
    --DRAM_DQM                            : out   std_logic_vector(1 downto 0);   --      SDRAM Data bus 2 Bits
    --DRAM_ADDR                           : out   std_logic_vector(12 downto 0);  --      SDRAM Address bus 13 Bits
    --DRAM_WE_N                           : out   std_logic;                      --      SDRAM Write Enable
    --DRAM_CAS_N                          : out   std_logic;                      --      SDRAM Column Address Strobe
    --DRAM_RAS_N                          : out   std_logic;                      --      SDRAM Row Address Strobe
    --DRAM_CS_N                           : out   std_logic;                      --      SDRAM Chip Select
    --DRAM_BA                             : out   std_logic_vector(1 downto 0);   --      SDRAM Bank Address 0
    --DRAM_CLK                            : out   std_logic;                      --      SDRAM Clock
    --DRAM_CKE                            : out   std_logic;                      --      SDRAM Clock Enable
 
--------------------------Accelerometer and EEPROM----------------
    --G_SENSOR_CS_N                       : out     std_logic;  
    --G_SENSOR_INT                        : in      std_logic;  
    I2C_SCLK                            : out     std_logic;  
    I2C_SDAT                            : inout   std_logic;  
--------------------------ADC--------------------------------------------------------
    --ADC_CS_N                            : out     std_logic;   
    --ADC_SADDR                           : out     std_logic; 
    --ADC_SCLK                            : out     std_logic; 
    --ADC_SDAT                            : in      std_logic;
--------------------------2x13 GPIO Header-----------------------------------------------
    GPIO_2_UP                           : inout   std_logic_vector(2 downto 0);
    GPIO_2                              : inout   std_logic_vector(8 downto 0);
    GPIO_2_IN                           : in      std_logic_vector(2 downto 0);
--------------------------GPIO_0, GPIO_0 connect to GPIO Default-----------------------
    GPIO_0                              : inout   std_logic_vector(33 downto 0);
    GPIO_0_IN                           : in      std_logic_vector(1 downto 0);
--------------------------GPIO_1, GPIO_1 connect to GPIO Default--------------------------
    GPIO_1                              : inout   std_logic_vector(33 downto 0);
    GPIO_1_IN                           : in      std_logic_vector(1 downto 0)
    );
end Analog_Input_Test_Code;

architecture Arch_DUT of Analog_Input_Test_Code is
  
-- Accelerometer and EEPROM
signal I2C_SCLK_i                       : std_logic;  
signal I2C_SDAT_i                       : std_logic; 

-- General Signals
signal RST_I_i                          : std_logic; 
signal CLK_I_i                          : STD_LOGIC;
signal One_uS_i                         : STD_LOGIC;     
signal One_mS_i                         : STD_LOGIC;              
signal Ten_mS_i                         : STD_LOGIC;
signal Twenty_mS_i                      : STD_LOGIC;             
signal Hunder_mS_i                      : STD_LOGIC;
signal UART_locked_i                    : STD_LOGIC;
signal One_Sec_i                        : STD_LOGIC;
signal Two_ms_i                         : STD_LOGIC;
signal One_mS_pulse_i                   : std_logic;
signal Twenty_Three_mS                  : std_LOGIC;

-- GPIO 0 Port Signals
signal FPGA_PPS_i                       : std_logic;
-- SPI Channel 1  
signal INT_1_1_i                        : std_logic;
signal MISO_1_i                         : std_logic;
signal INT_2_1_i                        : std_logic;       
signal SCKL_1_1_i                       : std_logic;
signal MOSI_1_i                         : std_logic;
signal CS_1_1_i                         : std_logic;       
signal CS_2_1_i                         : std_logic;

-- SPI Channel 2  
signal INT_1_2_i                        : std_logic;
signal MISO_2_i                         : std_logic;
signal INT_2_2_i                        : std_logic;
signal SCKL_1_2_i                       : std_logic;
signal CS_1_2_i                         : std_logic;              
signal MOSI_2_i                         : std_logic;       
signal CS_2_2_i                         : std_logic;

-- SPI Channel 3  
signal INT_1_3_i                        : std_logic;
signal INT_2_3_i                        : std_logic;
signal MISO_3_i                         : std_logic;
signal SCKL_1_3_i                       : std_logic;
signal CS_1_3_i                         : std_logic;
signal CS_2_3_i                         : std_logic;
signal CS_3_3_i                         : std_logic;
signal CS_4_3_i                         : std_logic;
signal MOSI_3_i                         : std_logic;

-- SPI Channel 4  
signal INT_1_4_i                        : std_logic;
signal MISO_4_i                         : std_logic;
signal INT_2_4_i                        : std_logic;
signal SCKL_1_4_i                       : std_logic;       
signal CS_2_4_i                         : std_logic;
signal CS_1_4_i                         : std_logic;
signal MOSI_4_i                         : std_logic;

-- SPI Channel 5
signal INT_1_5_i                        : std_logic;
signal MISO_5_i                         : std_logic;           
signal INT_2_5_i                        : std_logic;            
signal SCKL_1_5_i                       : std_logic;       
signal MOSI_5_i                         : std_logic;
signal CS_1_5_i                         : std_logic;
signal CS_2_5_i                         : std_logic;
  
-- GPIO 1 Port Signals
-- SPI Channel 6
signal INT_1_6_i                        : std_logic;
signal MISO_6_i                         : std_logic;
signal INT_2_6_i                        : std_logic;       
signal CS_1_6_i                         : std_logic;
signal CS_2_6_i                         : std_logic;
signal MOSI_6_i                         : std_logic;
signal SCKL_1_6_i                       : std_logic;

-- SPI Channel 7
signal MISO_7_i                         : std_logic;
signal INT_2_7_i                        : std_logic;       
signal INT_1_7_i                        : std_logic;              
signal CS_2_7_i                         : std_logic;
signal MOSI_7_i                         : std_logic;
signal SCKL_1_7_i                       : std_logic;
signal CS_1_7_i                         : std_logic;

-- SPI Channel 8
signal MISO_8_i                         : std_logic;
signal MOSI_8_i                         : std_logic;
signal INT_2_8_i                        : std_logic;
signal INT_1_8_i                        : std_logic;
signal CS_1_8_i                         : std_logic; 
signal CS_2_8A_i                        : std_logic;
signal SCKL_1_8_i                       : std_logic;

-- SPI Channel 9
signal MISO_9_i                         : std_logic;       
signal INT_2_9_i                        : std_logic;
signal INT_1_9_i                        : std_logic;       
signal CS_1_9_i                         : std_logic;
signal SCKL_1_9_i                       : std_logic;       
signal CS_2_9_i                         : std_logic;
signal MOSI_9_i                         : std_logic;

-- SPI Channel 10
signal INT_1_10_i                       : std_logic;
signal MISO_10_i                : std_logic;       
signal INT_2_10_i               : std_logic;   
signal MOSI_10_i                : std_logic;
signal SCKL_1_10_i              : std_logic;       
signal CS_2_10_i                : std_logic; 
signal CS_1_10_i                : std_logic;

-- GPIO 2 Port Signals
signal PC_Relay_Control_i       : std_logic; 

-- Timestamp from Tcl Script
signal Version_Timestamp_i      : STD_LOGIC_VECTOR(111 downto 0);       -- Ex. 20181120105439

-- Tope Level Firmware Module Name
constant ISC_Controller_name_i  : STD_LOGIC_VECTOR(23 downto 0) := x"495343";  -- RFC

-- Version Major Number - Hardcoded
constant Version_Major_High_i   : STD_LOGIC_VECTOR(7 downto 0) := x"30";  -- 0x
constant Version_Major_Low_i    : STD_LOGIC_VECTOR(7 downto 0) := x"31";  -- x1   -- Change to 00

constant Dot_i                  : STD_LOGIC_VECTOR(7 downto 0) := x"2e";  -- .
-- Version Minor Number - Hardcoded
constant Version_Minor_High_i   : STD_LOGIC_VECTOR(7 downto 0) := x"30";  -- 0x
constant Version_Minor_Low_i    : STD_LOGIC_VECTOR(7 downto 0) := x"30";  -- x0
-- Null Termination
constant Null_i                 : STD_LOGIC_VECTOR(7 downto 0) := x"00";  -- termination
signal Version_Register_i       : STD_LOGIC_VECTOR(199 downto 0);
signal Module_Number_i          : std_logic_vector(7 downto 0);
signal APE_Test_System_FPGA_Firmware_Version_Request_i : std_logic;

----------------------------------------------------------------------
-- Version Logger
----------------------------------------------------------------------
signal Version_Data_Ready_i                         : std_logic;
signal Version_Name_i                               : std_logic_vector(255 downto 0); 
signal Version_Number_i                             : std_logic_vector(63 downto 0);
signal APE_Test_System_FPGA_Firmware_Version_Ready_i    : std_logic;
signal APE_Test_System_FPGA_Firmware_Version_Name_i     : std_logic_vector(255 downto 0);
signal APE_Test_System_FPGA_Firmware_Version_Number_i   : std_logic_vector(63 downto 0);
signal APE_Test_System_FPGA_Firmware_Version_Load_i     : std_logic;


----------------------------------------------------------------------
-- Analog Input Driver Signals and Component
----------------------------------------------------------------------
signal CS1_i                                : std_logic;
signal CS2_i                                : std_logic;
signal CS3_i                                : std_logic;
signal CS4_i                                : std_logic;
signal CS1_1_i                              : std_logic;
signal CS2_1_i                              : std_logic;
signal CS3_1_i                              : std_logic;
signal CS4_1_i                              : std_logic;
signal CS1_2_i                              : std_logic;
signal CS2_2_i                              : std_logic;
signal CS3_2_i                              : std_logic;
signal CS4_2_i                              : std_logic;
signal nCS_i                                : std_logic;
signal Address_out_i                        : std_logic_vector(2 downto 0);
signal convert_i                            : std_logic;
signal nCS_1_1_i                            : std_logic;
signal nCS_2_1_i                            : std_logic;
signal nCS_3_1_i                            : std_logic;
signal nCS_4_1_i                            : std_logic;
signal nCS_1_2_i                            : std_logic;
signal nCS_2_2_i                            : std_logic;
signal nCS_3_2_i                            : std_logic;
signal nCS_4_2_i                            : std_logic;
signal AD_data_i                            : std_logic_vector(15 downto 0);
signal Data_valid_i                         : std_logic;
signal Analog_Input_Valid_i                 : std_logic;
signal nCS1_i                               : std_logic;
signal nCS2_i                               : std_logic;
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

----------------------------------------------------------------------
-- Analog In Handler Signals and Component
----------------------------------------------------------------------
signal Data_Ready_i                           : std_logic;
signal Analog_Data_i                          : std_logic_vector(767 downto 0);
signal Chip_Select_i                          : std_logic_vector(3 downto 0);
signal Version_Analog_Handler_1_i             : std_logic_vector(7 downto 0);
signal Version_Analog_Handler_2_i             : std_logic_vector(7 downto 0);
signal SPI_Analog_Handler_Version_Request_i   : std_logic;
signal SPI_Analog_Handler_Version_Name_i    : std_logic_vector(255 downto 0); 
signal SPI_Analog_Handler_Version_Number_i  : std_logic_vector(63 downto 0);
signal SPI_Analog_Handler_Version_Ready_i   : std_logic;

component SPI_Analog_Handler is
    port (
      RST_I                              : in  std_logic;
      CLK_I                              : in  std_logic;
      Address_out                        : out std_logic_vector(2 downto 0);
      convert                            : out std_logic;
      Analog_Data                        : out std_logic_vector(767 downto 0);
      Chip_Select                        : out std_logic_vector(3 downto 0); 
      AD_data_in                         : in  std_logic_vector(15 downto 0);
      Data_valid                         : in  std_logic;
      Data_Ready                         : out std_logic;
      Ana_In_Request                     : in  std_logic;
      Module_Number                      : in  std_logic_vector(7 downto 0);
      SPI_Analog_Handler_Version_Request : in  std_logic;
      SPI_Analog_Handler_Version_Name    : out std_logic_vector(255 downto 0); 
      SPI_Analog_Handler_Version_Number  : out std_logic_vector(63 downto 0);
      SPI_Analog_Handler_Version_Ready   : out std_logic 
      );
  end component SPI_Analog_Handler;

----------------------------------------------------------------------
-- Mux Signals and Component
----------------------------------------------------------------------
signal Controller_to_Software_UART_TXD_i  : std_logic;
signal Message_Length_i                   : std_logic_vector(7 downto 0);
signal Message_ID1_i                      : std_logic_vector(7 downto 0);
signal Digital_Input_Valid_i              : std_logic;
signal Dig_Card1_2_B0_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B1_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B2_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B3_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B4_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B5_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B6_i                   : std_logic_vector(7 downto 0);
signal Dig_Card1_2_B7_i                   : std_logic_vector(7 downto 0);
signal Digital_Output_Valid_i             : std_logic;
signal Tx_Rate_i                          : integer range 0 to 255;
signal Mux_Baud_Rate_Enable_i             : std_logic;
signal SYCN_Pulse_i                       : std_logic;
signal Watchdog_Reset_i                   : std_logic;
signal Watchdog_Status_in_i               : std_logic_vector(15 downto 0);
signal Mux_watchdog_i                     : std_logic;
signal Ana_In_Request_i                   : std_logic;
signal Dig_Out_1_B0_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B1_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B2_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B3_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B4_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B5_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B6_i                     : std_logic_vector(7 downto 0);
signal Dig_Out_1_B7_i                     : std_logic_vector(7 downto 0);
signal Dig_In_1_B0_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B1_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B2_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B3_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B4_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B5_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B6_i                      : std_logic_vector(7 downto 0);
signal Dig_In_1_B7_i                      : std_logic_vector(7 downto 0);
signal Main_Mux_Version_Name_i            : std_logic_vector(255 downto 0);
signal Main_Mux_Version_Number_i          : std_logic_vector(63 downto 0);
signal Main_Mux_Version_Ready_i           : std_logic; 
signal Main_Mux_Version_Request_i         : std_logic;

component Analog_Input_Test_Code_Mux is
    port (
      Clk                     : in  std_logic;
      RST_I                   : in  std_logic;
      UART_TXD                : out std_logic;
      Analog_Data             : in  std_logic_vector(767 downto 0);        
      Analog_Input_Valid      : in  std_logic;
      One_mS_pulse            : in  std_logic;
      Baud_Rate_Enable        : in  std_logic;
      Data_Ready              : in  std_logic;
      Ana_In_Request          : out std_logic
    );
end component Analog_Input_Test_Code_Mux;

----------------------------------------------------------------------
-- Baud Rate for Mux Signals and Component
----------------------------------------------------------------------
signal baud_rate_i                            : integer range 0 to 7;
signal Baud_Rate_Enable_i                     : std_logic;  
signal Version_Baud_1_i                       : std_logic_vector(7 downto 0);
signal Version_Baud_2_i                       : std_logic_vector(7 downto 0);
signal Baud_Rate_Generator_Version_Name_1_i   : std_logic_vector(255 downto 0); 
signal Baud_Rate_Generator_Version_Number_1_i : std_logic_vector(63 downto 0); 
signal Baud_Rate_Generator_Version_Ready_1_i  : std_logic; 
signal Baud_Rate_Generator_Version_Name_2_i   : std_logic_vector(255 downto 0); 
signal Baud_Rate_Generator_Version_Number_2_i : std_logic_vector(63 downto 0); 
signal Baud_Rate_Generator_Version_Ready_2_i  : std_logic; 
signal Baud_Rate_Generator_Version_Request_i  : std_logic;  

component Baud_Rate_Generator is
  port (
    Clk                                 : in  std_logic;
    RST_I                               : in  std_logic;
    baud_rate                           : in  integer range 0 to 7;
    Baud_Rate_Enable                    : out std_logic;
    Module_Number                       : in  std_logic_vector(7 downto 0);
    Baud_Rate_Generator_Version_Request : in  std_logic; 
    Baud_Rate_Generator_Version_Name    : out std_logic_vector(255 downto 0);
    Baud_Rate_Generator_Version_Number  : out std_logic_vector(63 downto 0);
    Baud_Rate_Generator_Version_Ready   : out std_logic   
    );
end component Baud_Rate_Generator;

-- Temps
signal Temp_Tester 	: std_logic;
signal One_Sec_Delay : std_logic;

signal KEY_0       : std_logic;
signal KEY_1       : std_logic;
-- End of Signals and Components

-------------------------------------------------------------------------------
-- Clock for Genlock
-------------------------------------------------------------------------------  
signal PC_Comms_RX_i        : std_logic;
signal PC_Comms_TX_i        : std_logic;
signal Pieter_PC_Comms_RX_i : std_logic;
signal Pieter_PC_Comms_TX_i : std_logic;

signal Busy_In_i       : std_logic;
signal Busy_Out_i      : std_logic;
signal SPI_Inpor_i     : std_logic_vector(15 downto 0);
signal Data_Out_Ready  : std_logic;
signal PC_Comms_TX     : std_logic;

signal One_Milli        : std_logic;
signal SET_Timer_i      : std_logic;

-------------------------------------------------------------------------------
-- Code Start
-------------------------------------------------------------------------------  
  Begin
-------------------------------------------------------------------------------    
--  Wire
-------------------------------------------------------------------------------    
CLK_I_i             <= CLOCK_50;
       
              
-- SPI 3 Analog Input
       
-- OUTS__________        
GPIO_1(0)           <= Controller_to_Software_UART_TXD_i;
       
       -- SPI 3 Analog Input
       
--    Version 1
       
       -- INS_________3		 
MISO_3_i            <= GPIO_0(1);
       
-- OUTS________3
GPIO_0(0)           <= CS_1_3_i;
GPIO_0(3)           <= MOSI_3_i;  
GPIO_0(5)           <= SCKL_1_3_i;  
GPIO_0(7)           <= CS_4_3_i;   
GPIO_0(2)           <= CS_2_3_i;       
GPIO_0(4)           <= CS_3_3_i;    

       
-- INS___________

           
-- Update Version Number when functionality changed
Version_Register_i <=  ISC_Controller_name_i & Null_i & Version_Major_High_i & Version_Major_Low_i & Dot_i &
Version_Minor_High_i & Version_Minor_Low_i & Dot_i &
Version_Timestamp_i & Null_i; 
-------------------------------------------------------------------------------    
--  Instantiations of Modules
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Analog In Driver Instance - Module 4
-------------------------------------------------------------------------------
SPI_Analog_Driver_1: SPI_Analog_Driver
port map (
  RST_I                             => RST_I_i,
  CLK_I                             => CLK_I_i,
  CS1                               => Chip_Select_i(0),
  CS2                               => Chip_Select_i(1),
  CS3                               => Chip_Select_i(2),
  CS4                               => Chip_Select_i(3),
  nCS                               => nCS_i,
  Address                           => Address_out_i,  
  convert                           => convert_i,
  nCS_1                             => CS_1_3_i,
  nCS_2                             => CS_2_3_i,
  nCS_3                             => CS_3_3_i,
  nCS_4                             => CS_4_3_i,
  Sclk                              => SCKL_1_3_i,  
  Mosi                              => MOSI_3_i,
  Miso                              => MISO_3_i,
  AD_data                           => AD_data_i,
  Data_valid                        => Data_valid_i,
  Module_Number                     => Module_Number_i,
  SPI_Analog_Driver_Version_Request => SPI_Analog_Driver_Version_Request_i,
  SPI_Analog_Driver_Version_Name    => SPI_Analog_Driver_Version_Name_i, 
  SPI_Analog_Driver_Version_Number  => SPI_Analog_Driver_Version_Number_i,
  SPI_Analog_Driver_Version_Ready   => SPI_Analog_Driver_Version_Ready_i   
  );

-------------------------------------------------------------------------------                      
-- Analog In Handler 1 - Module 5
-------------------------------------------------------------------------------
SPI_Analog_Handler_1: SPI_Analog_Handler
port map (
  RST_I           => RST_I_i,
  CLK_I           => CLK_I_i,
  Address_out     => Address_out_i,
  convert         => convert_i,
  Chip_Select     => Chip_Select_i,                            
  AD_data_in      => AD_data_i,
  Data_valid      => Data_valid_i,
  Analog_Data     => Analog_Data_i,
  Data_Ready      => Analog_Input_Valid_i,
  Ana_In_Request  => Ana_In_Request_i,
  Module_Number                     => Module_Number_i,
  SPI_Analog_Handler_Version_Request => SPI_Analog_Handler_Version_Request_i,
  SPI_Analog_Handler_Version_Name    => SPI_Analog_Handler_Version_Name_i, 
  SPI_Analog_Handler_Version_Number  => SPI_Analog_Handler_Version_Number_i,
  SPI_Analog_Handler_Version_Ready   => SPI_Analog_Handler_Version_Ready_i         
  );
 

-------------------------------------------------------------------------------
-- Endat Firmware Controller Mux 
-------------------------------------------------------------------------------
Analog_Input_Test_Code_Mux_1: entity work.Analog_Input_Test_Code_Mux
port map (
  CLK_I               => CLK_I_i,
  RST_I               => RST_I_i,
  UART_TXD            => Controller_to_Software_UART_TXD_i,
  Analog_Data         => Analog_Data_i,
  Analog_Input_Valid  => Analog_Input_Valid_i,
  Ana_In_Request      => Ana_In_Request_i,
  Baud_Rate_Enable    => Mux_Baud_Rate_Enable_i
  );                              

-------------------------------------------------------------------------------
-- Baud Instance for Mux  
-------------------------------------------------------------------------------     
Analog_Input_Test_Code_Baud_1: entity work.Baud_Rate_Generator
port map (
  Clk                                 => CLK_I_i,
  RST_I                               => RST_I_i,
  baud_rate                           => 5,
  Baud_Rate_Enable                    => Mux_Baud_Rate_Enable_i,
  Module_Number                       => Module_Number_i,
    Baud_Rate_Generator_Version_Request => Baud_Rate_Generator_Version_Request_i,
    Baud_Rate_Generator_Version_Name    => Baud_Rate_Generator_Version_Name_1_i,
    Baud_Rate_Generator_Version_Number  => Baud_Rate_Generator_Version_Number_1_i,
    Baud_Rate_Generator_Version_Ready   => Baud_Rate_Generator_Version_Ready_1_i
  );

-------------------------------------------------------------------------------
-- Test Only
------------------------------------------------------------------------------- 
-- add switches and Leds
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
       
 Time_Trigger: process(RST_I_i,CLOCK_50)
    variable bit_cnt_OuS       : integer range 0 to 100;
    variable bit_cnt_OmS       : integer range 0 to 60000;
    variable bit_cnt_TmS       : integer range 0 to 600000;
    variable bit_cnt_20mS      : integer range 0 to 2000000;       
    variable bit_cnt_HmS       : integer range 0 to 6000000;
    variable Sec_Cnt           : integer range 0 to 11;
    variable Two_ms_cnt        : integer range 0 to 3;
	 variable Oms_Cnt           : integer range 0 to 30;
    variable Ana_In_Request_cnt  : integer range 0 to 50000000;
    begin
      if RST_I_i = '0' then
         bit_cnt_OuS       := 0;
         bit_cnt_OmS       := 0;
         bit_cnt_TmS       := 0;         
         bit_cnt_HmS       := 0;
         bit_cnt_20mS      := 0;          
         One_uS_i          <= '0';
         One_mS_i          <= '0';        
         Ten_mS_i          <= '0';
         Twenty_mS_i       <= '0';
         Hunder_mS_i       <= '0';
         One_Sec_i         <= '0';
         Ana_In_Request_cnt := 0;
      elsif CLOCK_50'event and CLOCK_50 = '1' then      

         if Ana_In_Request_i = '1' then
            LED(0)               <= '1';
         end if;

         if Ana_In_Request_cnt = 5000000 THEN
            Ana_In_Request_cnt   := 0;
            LED(0)               <= '0';
         else
            Ana_In_Request_cnt   := Ana_In_Request_cnt + 1;
         end if;
         
--1uS
            if bit_cnt_OuS = 50 then
               One_uS_i         <= '1';
               bit_cnt_OuS      := 0;                      
            else
               One_uS_i        <= '0';
               bit_cnt_OuS      := bit_cnt_OuS + 1;
            end if;
--1mS            
            if bit_cnt_OmS = 50000 then
               One_mS_i         <= '1';                 
               bit_cnt_OmS      := 0;
               Two_ms_cnt       := Two_ms_cnt + 1;
					OmS_Cnt          := OmS_Cnt + 1;
            else
               One_mS_i   <= '0';
               bit_cnt_OmS      := bit_cnt_OmS + 1;
            end if;
-- 2 ms
            if Two_ms_cnt = 2 then
               Two_ms_i     <= '1';
               Two_ms_cnt   := 0;
            else
               Two_ms_i      <= '0';
            end if;   
-- 10ms            
            if bit_cnt_TmS = 500000 then
               Ten_mS_i   <= '1';
               bit_cnt_TmS      := 0;                      
            else
               Ten_mS_i   <= '0';
               bit_cnt_TmS      := bit_cnt_TmS + 1;
            end if;

-- 20mS         
            if bit_cnt_20mS = 1000000 then
               Twenty_mS_i   <= '1';
               bit_cnt_20mS  := 0;                      
            else
               Twenty_mS_i   <= '0';
               bit_cnt_20mS  := bit_cnt_20mS + 1;
            end if;    

-- 23 ms For Send Test
            if Oms_Cnt = 23 then
               Oms_Cnt := 0;
	            Twenty_Three_mS <= '1';
	         else
               Twenty_Three_mS <= '0';
            end if;					
            
--100Ms
            if bit_cnt_HmS = 5000000 then
               Hunder_mS_i      <= '1';                  
               bit_cnt_HmS      := 0;
               Sec_Cnt          := Sec_Cnt + 1;
            else
               Hunder_mS_i      <= '0';
               bit_cnt_HmS      := bit_cnt_HmS + 1;
            end if;

-- 1 sec
            if Sec_Cnt = 10 then
               One_Sec_i <= '1';
               Sec_Cnt   := 0;
            else
              One_Sec_i  <= '0';
            end if;  
      end if;
 end process Time_Trigger;
                            
  Reset_gen : process(CLOCK_50)
          variable cnt : integer range 0 to 255;
        begin
          if (CLOCK_50'event) and (CLOCK_50 = '1') then            
            if cnt = 255 then
               RST_I_i <= '1';
            else
               cnt := cnt + 1;
               RST_I_i <= '0';
             end if;
          end if;
        end process Reset_gen; 
  
  end Arch_DUT;

