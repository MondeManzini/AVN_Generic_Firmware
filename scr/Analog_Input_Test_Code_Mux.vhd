--

-- DESCRIPTION
-- ===========
-- Transmitter Uart, this gets the data from the mux and send it back to the PC
-- Last update : 29/05/2021 - Monde Manzini

--              - Testbench: Main_Mux_Test_Bench located at
--                https://katfs.kat.ac.za/svnAfricanArray/SoftwareRepository/CommonCode/ScrCommon
--              - Main_Mux_Test_Bench.do file located at
--                https://katfs.kat.ac.za/svnAfricanArray/SoftwareRepository/CommonCode/Modelsim/ 
-- Version : 0.1

---------------------
---------------------

-- Edited By            : Monde Manzini
--                      : Changed the header
--                      : Updated version
-- Version              : 0.1 
-- Change Note          : 
-- Tested               : 07/05/2021
-- Test Bench file Name : Main_Mux_Test_Bench
-- located at           : (https://katfs.kat.ac.za/svnAfricanArray/Software
--                        Repository/CommonCode/ScrCommon)
-- Test do file         : Main_Mux_Test_Bench.do
-- located at            (https://katfs.kat.ac.za/svnAfricanArray/Software
--                        Repository/CommonCode/Modelsim)

-- Outstanding          : Integration ATP and Approval
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_UNSIGNED.all;
use work.Version_Ascii.all;

entity Analog_Input_Test_Code_Mux is
  port(
   CLK_I                      : in  std_logic;
   RST_I                      : in  std_logic;
-- Ser data out
   UART_TXD                   : out std_logic;
-- From Demux
    	 
-- Analog In        
   -- Analog InS        
   -- Analog In 1        
   Analog_Data                : in std_logic_vector(767 downto 0);
   Analog_Input_Valid         : in std_logic;
    
-- Requests
   Ana_In_Request             : out std_logic;
   Baud_Rate_Enable           : in  std_logic 
   );

end Analog_Input_Test_Code_Mux;

architecture Arch_DUT of Analog_Input_Test_Code_Mux is


  constant Preamble1        : std_logic_vector(7 downto 0) := X"A5";
  constant Preamble2        : std_logic_vector(7 downto 0) := X"5A";
  constant Preamble3        : std_logic_vector(7 downto 0) := X"7E";

  constant Analog_Card_1    : std_logic_vector(7 downto 0) := X"30";
  constant Analog_Card_2    : std_logic_vector(7 downto 0) := X"31";

  constant no_of_chars2send   : integer range 0 to 255   :=  103;

type tx_states 	is (idle, sync, send_start, send_data, CRC_ready, send_stop);
type tx_data_array is array (0 to 255) of std_logic_vector(7 downto 0);
type request_send_states is (Request_Idle, Requests_TX, Data_RX, Collect_Data);

signal data2send                  : tx_data_array;
signal CRC2send                   : tx_data_array;
signal tx_state                   : tx_states;
signal request_send_state         : request_send_states; 
-- end of state machines declaration

signal enable_div20               : std_logic;
signal sample_clock2              : std_logic;
signal no_of_chars                : integer range 0 to 255;  
--signal no_of_chars2send           : integer range 0 to 255;
signal baud_rate_reload           : integer range 0 to 6000;
signal busy                       : std_logic;
signal comms_done                 : std_logic;
signal done                       : std_logic;
signal send_msg                   : std_logic;
signal SerDataOut                 : std_logic;
signal CRCSerDataOut              : std_logic;
signal SerData_Byte               : std_logic_vector(7 downto 0);
-- CRC 16 Signals
signal X                          : std_logic_vector(15 downto 0);
signal CRC_Sum                    : std_logic_vector(15 downto 0);
signal crc16_ready                : std_logic;
signal add_crc                    : std_logic;
signal Send_Operation             : std_logic;
signal Send_ComPort_Data          : std_logic;
signal Send_ShaftEncoder          : std_logic;
signal lockout_trigger            : std_logic;  
signal lockout_Read_Trigger       : std_logic;
signal flag_WD                    : std_logic;
signal Message_done               : std_logic;
signal Data_Ready_i               : std_logic;

signal Message_length_i           : std_logic_vector(7 downto 0);
signal Ana_In_Request_i           : std_logic;
signal Dig_In_Request_i           : std_logic;
signal Dig_Out_Request_i          : std_logic;
signal Busy_Latch                 : std_logic;
signal Ready_i                    : std_logic;
signal Stack_100mS_Data           : std_logic;
signal Lockout                    : std_logic;
signal Analog_Input_Ready         : std_logic;
signal All_Modules_Ready          : std_logic;
signal All_Modules_Trig           : std_logic;
signal Send_100mS_Data            : std_logic;
signal Send_All_Modules           : std_logic;
signal All_Data_Ready             : std_logic;
signal Request_Data_Strobe             : std_logic;
signal Send_Data_Strobe                : std_logic;
signal Analog_Trig                     : std_logic;
signal RTC_Build_Trig_Done_i           : std_logic;     
signal Analog_Input_Build_Trig_i       : std_logic;  
signal Analog_Input_Build_Trig_Done_i  : std_logic;  
signal Analog_Input_Load               : std_logic;

signal no_of_chars2snd                 : std_logic_vector(7 downto 0) := X"00";
signal mode_i                          : std_logic_vector(7 downto 0) := X"00";

type Time_Array is array (0 to 255) of std_logic_vector(7 downto 0);
signal Time_Data_Array        : Time_Array;

type Preamble_Array is array (0 to 255) of std_logic_vector(7 downto 0);
signal Preamble_Data_Array    : Preamble_Array;

type Analog_In_Array is array (0 to 767) of std_logic_vector(7 downto 0);
signal Analog_In_Data_Array   : Analog_In_Array;

function reverse_any_bus (a : in std_logic_vector)
return std_logic_vector is
      variable result   :    std_logic_vector(a'range);
      alias aa          :    std_logic_vector(a'reverse_range) is a;
      begin
         for i in aa'range loop
            result(i) := aa(i);
            end loop;
            return result;
end;  -- function reverse_any_bus

begin

UART_TXD     	          <= SerDataOut;
Ana_In_Request           <= Ana_In_Request_i;

-- Build message
gen_tx_ser_data : process (CLK_I, RST_I)
  
variable Delay                               : integer range 0 to 50;
variable Request_Data_cnt                    : integer range 0 to 5000001;
variable send_data_cnt                       : integer range 0 to 10;
variable wait_cnt_rtc                        : integer range 0 to 50;
variable wait_cnt_all                        : integer range 0 to 100;
variable analog_data_load                    : integer range 0 to 100;
begin
   if RST_I = '0' then
      Preamble_Data_Array(0)     <= x"a5";
      Preamble_Data_Array(1)     <= x"5a";
      Preamble_Data_Array(2)     <= x"7e";
      data2send                  <= (others => (others => '0'));
      CRC2send                   <= (others => (others => '0'));
      Analog_In_Data_Array       <= (others => (others => '0'));
      --no_of_chars2send           <= 0;
      send_msg                   <= '0';
      Message_done               <= '0';
      Send_100mS_Data            <= '0';    
      Stack_100mS_Data           <= '0';
      Ana_In_Request_i           <= '0';
      Analog_Input_Ready         <= '0';
      Analog_Trig                <= '0';
      Analog_Input_Build_Trig_i        <= '0';
      Analog_Input_Build_Trig_Done_i   <= '0';
      Lockout                          <= '0';
      Send_Operation             <= '0';
      Request_Data_cnt           := 0;
      send_data_cnt              := 0;
      analog_data_load           := 0;
      Request_Data_Strobe        <= '0'; 
      Send_Data_Strobe           <= '0';
      Send_All_Modules           <= '0';  
      request_send_state         <= Request_Idle;
      report "The version number of Analog_Input_Test_Code_Mux is 00.01.06." severity note;  
   elsif CLK_I'event and CLK_I = '1' then

      case Request_Send_State is
         when Request_Idle =>
            -----------------------------      
            -- Modules Request Generator    
                  --100mS
            -----------------------------
            Ana_In_Request_i                 <= '0';
            if Request_Data_cnt = 500000 then  -- 100 ms Retrieve 0 for 5000_000
               Send_Data_Strobe     <= '1';                  
               Request_Data_cnt     := 0;
               Request_Send_State   <= Data_RX;
            elsif Request_Data_cnt = 490000 then -- 90 ms Retrieve 0 for 4900_000
               Request_Data_Strobe  <= '1';
               Request_Data_cnt     := Request_Data_cnt + 1;
               Request_Send_State   <= Requests_TX;
            else
               Request_Data_cnt        := Request_Data_cnt + 1;
               Analog_Input_Load       <= '0';
               Request_Send_State      <= Request_Idle;
            end if; 

         when Requests_TX =>
            Request_Data_Strobe  <= '0';
            if Busy = '0' then
               Ana_In_Request_i     <= '1';
               Request_Send_State   <= Request_Idle;
            end if;
            -----------------------------      
            -- End of Modules Request Generator    
            -----------------------------
         when Data_RX =>
            if Send_Data_Strobe = '1' then
               Send_Data_Strobe     <= '0';
               Analog_Trig          <= '1';
               Request_Send_State   <= Collect_Data;
            else
               Request_Send_State   <= Collect_Data;
            end if;

         when Collect_Data =>
               
      -- Analog Input Data Validity Generator
            
            if Analog_Input_Valid = '1' and Analog_Trig = '1' then
               Analog_Input_Load <= '1';  
               --no_of_chars2send  <= 103;      -- Latch AI no of chars
            end if;  

            if Analog_Input_Load = '1' then
               if analog_data_load = 100 then
                  analog_data_load     := 0;
                  Analog_Input_Ready   <= '1';        -- Latch AI
                  Request_Send_State   <= Request_Idle;
               else
                  analog_data_load := analog_data_load + 1;
                  for i in 0 to 95 loop
                     if i = 0 then
                        Analog_In_Data_Array(0) <= Analog_Card_1;
                     elsif i > 0 then
                        --Analog_In_Data_Array(i) <= Analog_Data((15+(i * 16)) downto (0+(i * 16)));
                        Analog_In_Data_Array(i-1) <= Analog_Data((7+((i-1) * 8)) downto (0+((i-1) * 8))); 
                        --Analog_In_Data_Array(24-1) <= Analog_Data((7+((24-1) * 8)) downto (0+((24-1) * 8)));
                        --Analog_In_Data_Array(24-1) <= Analog_Data((191 downto 184);  
                        --Analog_In_Data_Array(25-1) <= Analog_Data((7+((25-1) * 8)) downto (0+((25-1) * 8)));
                        --Analog_In_Data_Array(25-1) <= Analog_Data((199 downto 192);  
                        --Analog_In_Data_Array(26-1) <= Analog_Data((7+((26-1) * 8)) downto (0+((26-1) * 8)));
                        --Analog_In_Data_Array(26-1) <= Analog_Data((207 downto 200);  

                        --Analog_In_Data_Array(49-1) <= Analog_Data((7+((49-1) * 8)) downto (0+((49-1) * 8)));
                        --Analog_In_Data_Array(49-1) <= Analog_Data((391 downto 384);  

                        --Analog_In_Data_Array(96-1) <= Analog_Data((7+((96-1) * 8)) downto (0+((96-1) * 8)));
                        --Analog_In_Data_Array(96-1) <= Analog_Data((207 downto 200);  
                     end if;  
                  end loop;
               end if;
            end if;
      end case;
   -- Timestamp and Stacking

         if Analog_Input_Ready = '1' then       
            Analog_Input_Load          <= '0';
            Analog_Input_Build_Trig_i  <= '1';
         end if; 

         if Analog_Input_Build_Trig_i = '1' then
            Analog_Input_Ready         <= '0';       
            if wait_cnt_all = 100 then
               wait_cnt_all                   := 0;
               Analog_Input_Build_Trig_Done_i <= '1';
            else
               wait_cnt_all      := wait_cnt_all + 1;
               -- Build Message
               no_of_chars2snd   <= std_logic_vector(to_unsigned(no_of_chars2send, no_of_chars2snd'length));
               mode_i            <= x"80";
               for i in 0 to no_of_chars2send loop
                  if i < 3 THEN
                     data2send(i)   <= Preamble_Data_Array(i);
                     CRC2send(i)    <= Preamble_Data_Array(i);
                  elsif (i = 3) then
                     data2send(i)   <= no_of_chars2snd;
                     CRC2send(i)    <= no_of_chars2snd;
                  elsif (i = 4) then
                     data2send(i)   <= mode_i;
                     CRC2send(i)    <= mode_i;
                  elsif (i > 4) then
                     -- Analog Input Message
                     data2send(i)   <= Analog_In_Data_Array(i-5);
                     CRC2send(i)    <= Analog_In_Data_Array(i-5);
                  end if;
               end loop;
            end if;
         end if;   

         if Analog_Input_Build_Trig_Done_i = '1' then
            Analog_Input_Build_Trig_Done_i   <= '0';
            Analog_Input_Build_Trig_i        <= '0';
            if (Busy = '1') then
               Stack_100mS_Data           <= '1';
               Send_100mS_Data            <= '0';
            else
               Send_100mS_Data            <= '1';
               Stack_100mS_Data           <= '0';
            end if; 
         end if;
                                  
   -- Send when Not Busy       
         if (Busy = '0') and (Lockout = '0') then
            if Send_100mS_Data = '1' then
               Send_Operation         <= '1';
               Send_100mS_Data        <= '0';
               Lockout                <= '1';
            elsif (Send_100mS_Data = '1') and (Stack_100mS_Data = '1') then
               Send_Operation       <= '1';
               Stack_100mS_Data     <= '0';
               Lockout              <= '1';       
            end if;
         else
            Send_100mS_Data         <= '0';
         end if;   
         
         if busy = '1' and Lockout = '1' then
            lockout <= '0';
         end if;

-----------------------------------------
-- Operation
-----------------------------------------

      if Send_Operation = '1' then
         Send_100mS_Data  <= '0';
         Send_Operation   <= '0';
         send_msg         <= '1';
      else
        send_msg        <= '0';
        Message_done    <= '0';
      end if;
              
      if add_crc = '1' then
         data2send(no_of_chars2send - 2) <= CRC_Sum(15 downto 8);
         data2send(no_of_chars2send - 1) <= CRC_Sum(7 downto 0);
      end if;

   end if;

  end process gen_tx_ser_data;

  --Send message out

  uart_tx : process (CLK_I, RST_I)

    variable tx_counter  : integer range 0 to 15;
    variable bit_counter : integer range 0 to 8;
    variable tx_en       : std_logic;
    variable Wait_cnt    : integer range 0 to 50;
  begin
    if RST_I = '0' then
      tx_state      <= idle;
      tx_counter    := 0;
      SerDataOut    <= '1';             --idle
      CRCSerDataOut <= '1';
      bit_counter   := 0;
      tx_en         := '0';
      no_of_chars   <= 0;
      busy          <= '0';
      Busy_Latch    <= '0';
      done          <= '0';
      comms_done    <= '0';
      X             <= (others => '1');
      add_crc       <= '0';
      Wait_cnt      := 0;
      crc16_ready   <= '0';
      SerData_Byte  <= (others => '0');
      flag_WD       <= '0';      
    elsif CLK_I'event and CLK_I = '1' then

      if Baud_Rate_Enable = '1' then  
         tx_en := '1';
      else
         tx_en := '0';
      end if;

      case tx_state is

        when idle =>
          
             done       <= '0';
             comms_done <= '0';
             busy       <= '0';

             if send_msg = '1' then
                tx_state      <= sync;
                busy          <= '1';
                
                bit_counter   := 0;
                CRCSerDataOut <= '1';
                SerDataOut    <= '1';       --idle state on line
             else
                tx_state      <= idle;
             end if;

        when sync =>
             add_crc  <= '0';
             tx_state <= send_start;


        when send_start =>
             if tx_en = '1' then
                SerDataOut    <= '0';       --start bit
                CRCSerDataOut <= '0';
                tx_state      <= send_data;
             end if;

        when send_data =>
             crc16_ready       <= '0';
             if tx_en = '1' then
                if bit_counter = 8 then
                   bit_counter := 0;
                   tx_state      <= send_stop;
                   no_of_chars   <= no_of_chars + 1;
                   SerDataOut    <= '1';     --stop_bit
                   CRCSerDataOut <= '1';
                else
                   SerDataOut    <= data2send(no_of_chars)(bit_counter);
                   CRCSerDataOut <= CRC2send(no_of_chars)(bit_counter);
                   SerData_Byte  <= data2send(no_of_chars);
                   bit_counter   := bit_counter + 1;
                   tx_state      <= CRC_ready;
                   Wait_cnt      := 0;
                end if;
             end if;

        when CRC_ready =>
             if Wait_cnt = 30 then
                crc16_ready <= '1';
                tx_state    <= send_data;
             else
                wait_cnt := wait_cnt + 1;
             end if;

        when send_stop =>
             if tx_en = '1' then
                if no_of_chars = no_of_chars2send then
                   tx_state    <= idle;
                   no_of_chars <= 0;
                   done        <= '1';
                   comms_done  <= '1';
                   busy        <= '0';
                elsif no_of_chars = 3 then
                   tx_state    <= sync;
                   X           <= (others => '1');
                elsif no_of_chars = no_of_chars2send - 2 then
                   tx_state    <= sync;
                   add_crc     <= '1';
                else
                  tx_state    <= sync;
                  comms_done  <= '0';
                end if;
             end if;
        end case;

        if crc16_ready = '1' then
           X(0)  <= CRCSerDataOut xor X(15);   
           X(1)  <= X(0);
           X(2)  <= X(1);
           X(3)  <= X(2);
           X(4)  <= X(3);
           X(5)  <= X(4) xor CRCSerDataOut xor X(15);
           X(6)  <= X(5);
           X(7)  <= X(6);
           X(8)  <= X(7);
           X(9)  <= X(8);
           X(10) <= X(9);
           X(11) <= X(10);
           X(12) <= X(11) xor CRCSerDataOut xor X(15);
           X(13) <= X(12);
           X(14) <= X(13);
           X(15) <= X(14);
        end if;
        CRC_Sum  <= X;
    end if;
  end process uart_tx;

end Arch_DUT;


