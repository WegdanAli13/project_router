
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Node is
    generic (
        SELF_X : unsigned(2 downto 0):="010";
        SELF_Y : unsigned(2 downto 0):="001"
    );
    Port ( Tx_up,Tx_down,Tx_left,Tx_right : out STD_LOGIC;
           Rx_up,Rx_down,Rx_left,Rx_right : in STD_LOGIC;
           clk : in STD_LOGIC;
           Hsync,Vsync : out std_logic;
           R,G,B : out std_logic_vector(3 downto 0);
           X, Y: in STD_LOGIC_VECTOR(2 downto 0);
           switch: in STD_LOGIC; 
           ps2_clk      : IN  STD_LOGIC;                     
           ps2_data     : IN  STD_LOGIC; 
           led : out std_logic_vector(7 downto 0)
           );
end Node;

architecture Behavioral of Node is
component VGA_writer is
    Port ( clk : in STD_LOGIC;
           Key_event : in STD_LOGIC;
           ASCII_in : in std_logic_vector(6 downto 0);
           R : out STD_LOGIC_VECTOR (3 downto 0);
           G : out STD_LOGIC_VECTOR (3 downto 0);
           B : out STD_LOGIC_VECTOR (3 downto 0);
           Hsync : out STD_LOGIC;
           Vsync : out STD_LOGIC);
end component;

component router is
    generic(
        RESERVE_PATH :unsigned(1 downto 0):="10";
        RELEASE_PATH : unsigned(7 downto 0):="01111111";
        ACK : unsigned(7 downto 0) := "11000000";
        SELF_X : unsigned(2 downto 0):="000";
        SELF_Y : unsigned(2 downto 0):="000"
      );
    Port ( clk : in STD_LOGIC;
           Tx_up,Tx_down,Tx_left,Tx_right,Tx_self : out STD_LOGIC_VECTOR (7 downto 0) := "00000000";
           Tx_valid : out std_logic_vector(4 downto 0) :="00000";
           Rx_up,Rx_down,Rx_left,Rx_right,Rx_self : in STD_LOGIC_VECTOR (7 downto 0);
           Rx_valid : in std_logic_vector(4 downto 0));

end component;
component UART_RX is
    generic(
        baud_rate : integer := 9600
    );
    Port (clk : in std_logic;
          Rx : in STD_LOGIC;
          Rx_data : out std_logic_vector(7 downto 0);
          data_valid : out std_logic
          );
end component;
component UART_Tx is
    generic(
        baud_rate : integer := 9600
    );
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_valid : in STD_LOGIC;
           Tx,Tx_BUSY : out STD_LOGIC;
           clk : in STD_LOGIC);
end component;
component clk_expander is
    generic (
        T : integer :=20
    );
    Port ( clk : in std_logic;
           input : in STD_LOGIC_VECTOR(7 downto 0);
           valid : in std_logic;
           output : out STD_LOGIC_VECTOR(7 downto 0);
           valid_out : out std_logic
           );
end component;

component Self_Port is
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
           switch: in STD_LOGIC; 
           Tx_valid: out STD_LOGIC;
           Tx: out STD_LOGIC_VECTOR(7 downto 0);
           screen: out STD_LOGIC_VECTOR(6 downto 0)
    );
end component;

component ps2_keyboard IS
  GENERIC(
    clk_freq              : INTEGER := 100_000_000; 
    debounce_counter_size : INTEGER := 4);         
  PORT(
    clk          : IN  STD_LOGIC;                     
    ps2_clk      : IN  STD_LOGIC;                     
    ps2_data     : IN  STD_LOGIC;                     
    ps2_code_new : OUT STD_LOGIC;                     
    ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); 
END component;
--constant SELF_X : unsigned(2 downto 0):="000";
--constant SELF_y : unsigned(2 downto 0):="000";

signal Tx_valid,Rx_valid,Rx_valid_expanded,Tx_valid_expanded: std_logic_vector(4 downto 0):="00000";
signal Tx_up_d,Tx_down_d,Tx_left_d,Tx_right_d,Rx_up_d,Rx_down_d,Rx_left_d,Rx_right_d,Rx_self_d,Tx_self_d: std_logic_vector(7 downto 0):="00000000";
signal Tx_up_d_expanded,Tx_down_d_expanded,Tx_left_d_expanded,Tx_right_d_expanded,Tx_self_d_expanded,Rx_up_d_expanded,Rx_down_d_expanded,Rx_left_d_expanded,Rx_right_d_expanded,Rx_self_d_expanded: std_logic_vector(7 downto 0):="00000000";
signal  ps2_code : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal ps2_code_new : std_logic;

begin
Rx_valid(4)<='0'; -- no self
led<=Tx_self_d;

keyboard: ps2_keyboard port map(clk,ps2_clk,ps2_data,ps2_code_new,ps2_code);

connect_self_port: Self_Port port map(clk, 
Rx_valid=>Tx_valid(4),
Rx=>Tx_self_d,
X=>X,
dataa=>ps2_code,
Y=>Y,
switch=>switch,
Tx_valid=>Rx_valid_expanded(4),
Tx=>Rx_self_d_expanded,
screen=>Tx_self_d_expanded
);

clk_expander_VGA_event: clk_expander generic map (T=> 100) port map (clk,Tx_self_d,Tx_valid(4),Tx_self_d_expanded,Tx_valid_expanded(4));

vga: VGA_writer port map (
           clk =>clk,
           Key_event=> Tx_valid_expanded(4), 
           ASCII_in => Tx_self_d_expanded(6 downto 0),
           R => R,
           G =>G,
           B=>B,
           Hsync=>Hsync,
           Vsync => Vsync
);

router_00: router generic map(SELF_X=>SELF_X, SELF_Y=>SELF_Y) 
port map(clk,
Tx_up_d,Tx_down_d,Tx_left_d,Tx_right_d,Tx_self_d,
Tx_valid,
Rx_up_d_expanded,Rx_down_d_expanded,Rx_left_d_expanded,Rx_right_d_expanded,Rx_self_d_expanded,
Rx_valid_expanded);

clk_expander_self_Rx: clk_expander port map (clk,Rx_self_d,Rx_valid(4),Rx_self_d_expanded,Rx_valid_expanded(4));


clk_expander_up_Rx: clk_expander port map (clk,Rx_up_d,Rx_valid(0),Rx_up_d_expanded,Rx_valid_expanded(0));

UART_RX_up: UART_Rx generic map(baud_rate=>9600) port map(
    Rx=>Rx_up,
    Rx_data=>Rx_up_d,
    data_valid=>Rx_valid(0),
    clk=>clk
);
clk_expander_down_Rx: clk_expander port map (clk,Rx_down_d,Rx_valid(1),Rx_down_d_expanded,Rx_valid_expanded(1));

UART_RX_down: UART_Rx generic map(baud_rate=>9600) port map(
    Rx=>Rx_down,
    Rx_data=>Rx_down_d,
    data_valid=>Rx_valid(1),
    clk=>clk
);
clk_expander_left_Rx: clk_expander port map (clk,Rx_left_d,Rx_valid(2),Rx_left_d_expanded,Rx_valid_expanded(2));

UART_RX_left: UART_Rx generic map(baud_rate=>9600) port map(
    Rx=>Rx_left,
    Rx_data=>Rx_left_d,
    data_valid=>Rx_valid(2),
    clk=>clk
);
clk_expander_right_Rx: clk_expander port map (clk,Rx_right_d,Rx_valid(3),Rx_right_d_expanded,Rx_valid_expanded(3));

UART_RX_right: UART_Rx generic map(baud_rate=>9600) port map(
    Rx=>Rx_right,
    Rx_data=>Rx_right_d,
    data_valid=>Rx_valid(3),
    clk=>clk
);
------------- UART_Tx -------------------------------------
UART_Tx_up: UART_Tx generic map(baud_rate=>9600) port map(
    Tx=>Tx_up,
    data_in=>Tx_up_d,
    data_valid=>Tx_valid(0),
    Tx_BUSY=> open,
    clk=>clk
);
UART_Tx_down: UART_Tx generic map(baud_rate=>9600) port map(
    Tx=>Tx_down,
    data_in=>Tx_down_d,
    data_valid=>Tx_valid(1),
    Tx_BUSY=> open,
    clk=>clk
);
UART_Tx_left: UART_Tx generic map(baud_rate=>9600) port map(
    Tx=>Tx_left,
    data_in=>Tx_left_d,
    data_valid=>Tx_valid(2),
    Tx_BUSY=> open,
    clk=>clk
);
UART_Tx_right: UART_Tx generic map(baud_rate=>9600) port map(
    Tx=>Tx_right,
    data_in=>Tx_right_d,
    data_valid=>Tx_valid(3),
    Tx_BUSY=> open,
    clk=>clk
);


end Behavioral;
