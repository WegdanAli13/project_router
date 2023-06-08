----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/31/2023 06:12:25 AM
-- Design Name: 
-- Module Name: Self_Port - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Self_Port is
    generic(
        RESERVE_PATH :unsigned(1 downto 0):="10";
        RELEASE_PATH : unsigned(7 downto 0):="01111111";
        ACK : unsigned(1 downto 0) := "11";
        SELF_X : unsigned(2 downto 0):="000";
        SELF_Y : unsigned(2 downto 0):="000"
    );
    Port ( clk : in STD_LOGIC;
           Rx_valid: in STD_LOGIC;
           Rx, dataa: in STD_LOGIC_VECTOR(7 downto 0);
           X, Y: in STD_LOGIC_VECTOR(2 downto 0);
           switch: in STD_LOGIC; -- if 1 go to idle of transmitter.
           Tx_valid: out STD_LOGIC;
           Tx: out STD_LOGIC_VECTOR(7 downto 0);
           screen: out STD_LOGIC_VECTOR(6 downto 0)
    );
end Self_Port;

architecture Behavioral of Self_Port is

type states_r is (Idle, Acknowledgement, Data, release);
type states_t is (Idle, Acknowledgement, Data,release);
signal current_state_r : states_r := Idle;
signal current_state_t : states_t := Idle;
signal clk_out: STD_LOGIC:='1';
signal flag,flag_t: STD_LOGIC:='0';
signal count: integer range 0 to 9600;
signal x_sender, y_sender,x_temp, y_temp: STD_LOGIC_VECTOR(2 downto 0);
signal screen_temp: STD_LOGIC_VECTOR(6 downto 0);

begin

-- Clock Division
--process(clk) 
--begin
--    if(rising_edge(clk))then
--        count <= count + 1;            
--        if count = 4800 then
--            clk_out <= '1';
--        end if;
--        if count = 9600 then
--             clk_out <= '0';
--             count<= 1;
--        end if;
--    end if;   
--end process;

process(clk) 
begin
if rising_edge(clk) then


    if (Rx(7 downto 6) = "10" and Rx_valid = '1') then -- 10 is reserved path.
        flag <= '1'; -- Flag is to control that when returning to idle state, you don't do anything unless path is reserved & Rx_valid = 1
        current_state_r <= Idle;
        x_temp<=Rx(5 downto 3);
        y_temp<=Rx(2 downto 0);
    end if;
    
    case current_state_r is
    when Idle =>
        if (flag = '1') then
            count <= count+1;
            if (count = 19200) then
                x_sender <= x_temp; -- Determine the address of the sender.
                y_sender <= y_temp;
                current_state_r <= Acknowledgement;
                count <= 0;
            else
                current_state_r <= Idle;
            end if;
        end if;
    when Acknowledgement =>
        count <= count+1;
        screen_temp <= Rx(6 downto 0);
        if (count = 19200) then
            Tx <= "11" & x_sender & y_sender; -- 11 is ack.
            current_state_r <= Data;
            count <= 0;
        else
            current_state_r <= Acknowledgement;
        end if;        
    when Data =>
        
        count <= count+1;
        if (count = 19200) then
            screen <= screen_temp;
            count <= 0;
            current_state_r <= release;

         else
             current_state_r <= Data;
         end if;    
         
      when release =>
        count <= count+1;
        if (count = 19200 and Rx= "01111111") then
             flag <= '0';
             count <= 0;
            current_state_r <= Idle;
        else
            current_state_r <= release;
        end if; 
    when others => current_state_r <= Idle; 
    end case;
 
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
   
    
    if (switch = '1') then
        flag_t <= '1'; -- Flag is to control that when returning to idle state, you don't do anything unless path is reserved & Rx_valid = 1
        current_state_t <= Idle;
    end if;

    case current_state_t is
    when Idle=>
        if (flag_t = '1') then
            count <= count+1;
            if (count = 19200) then
                Tx <= "10" & X & Y;
                Tx_valid <= '1';
                count <= 0;
                current_state_t <= Acknowledgement;
            else
                current_state_t <= Idle;
            end if;
        end if;
     when Acknowledgement=>
        count <= count+1;
        if (count <= 300000 and Rx(7 downto 6) = "11") then 
            current_state_t <= Data; 
            count <= 0; 
        elsif (count <= 300000 and Rx(7 downto 6) /= "11") then
            current_state_t <= Acknowledgement;
        else
            current_state_t <= release;
            Tx_valid <= '0';
            count <= 0;
        end if;
        
     when Data=>
        count <= count+1;
        if (count = 19200) then
            count <= 0;
            Tx <= dataa; 
            current_state_t <= release; 
        else
            current_state_t <= Data;
        end if; 
                 
     when release =>
       count <= count+1;
       if (count = 19200) then
            Tx<="01111111";
            flag_t <= '0';
            Tx_valid <= '0';
            count <= 0;
           current_state_t <= Idle;
       else
           current_state_t <= release;
       end if; 
     end case;
      
end if;
end process;
end Behavioral;
