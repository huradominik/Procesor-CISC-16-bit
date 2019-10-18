LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE WORK.DE2_PKG.all;

ENTITY de2top IS
	PORT(
		 CLOCK_50				: IN	STD_LOGIC;	

		 LCD_RS, LCD_EN, LCD_ON 	: OUT	STD_LOGIC;
		 LCD_RW						: BUFFER STD_LOGIC;
		 LCD_DATA				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		 
		 HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : OUT LED_character;
		 SW				: IN	STD_LOGIC_VECTOR(17 DOWNTO 0);
		 LEDR				: OUT	STD_LOGIC_VECTOR(17 DOWNTO 0);
		 LEDG				: OUT	STD_LOGIC_VECTOR(8 DOWNTO 0);
		 KEY				: IN	STD_LOGIC_VECTOR(3 DOWNTO 0));
		 
END de2top;


ARCHITECTURE RTL OF de2top IS

component de2top is
  port(x, y, clk, reset : in std_logic;
        reg_out : out std_logic_vector (15 downto 0);
		  	  state_r: out std_logic_vector (2 downto 0));
end component;

component razem is

port(
clock,reset : IN STD_LOGIC;
acc : OUT STD_LOGIC_VECTOR (7 downto 0);
pc : OUT STD_LOGIC_VECTOR (11 downto 0);
R0,R1,R2,R3 : OUT STD_LOGIC_VECTOR (7 downto 0);
cy_flag,zero_flag : OUT STD_LOGIC
);

end component razem;

COMPONENT LCD_CTRL IS
	PORT(
		 CLK_400HZ				: IN	STD_LOGIC;	
		 RESET_EXT : IN	STD_LOGIC;
		 -- data for LCD to display
		 LCD_upper : IN LCD_ROW;
		 LCD_lower : IN LCD_ROW;
		 -- DE2 LCD display control signals
		 LCD_RS, LCD_EN, LCD_ON 	: OUT	STD_LOGIC;
		 LCD_RW			: BUFFER STD_LOGIC;
		 -- DE2 LCD display data bus
		 LCD_DATA		: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
		 ); 
END COMPONENT LCD_CTRL;

   SIGNAL LCD_upper_x : LCD_ROW;
	SIGNAL LCD_lower_x : LCD_ROW;
	
	--TYPE SEG7DISP is array (0 to 7) of STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL HEX : LED7SEG_DISP;
	
	SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
	SIGNAL CLK_COUNT_10HZ: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	SIGNAL reset, reset1, clkx2, clk, X, Y, CLK_50MHZ, CLK_400HZ, CLK_10HZ : STD_LOGIC;
	SIGNAL Xi, Xex, Yi, Yex : STD_LOGIC;	
	SIGNAL CNT10, CNT32, CNT54, CNT76 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL TSEC: STD_LOGIC_VECTOR(3 DOWNTO 0);
	
	SIGNAL reg : STD_LOGIC_VECTOR (15 downto 0);
	SIGNAL state : STD_LOGIC_VECTOR (2 downto 0);
	
	SIGNAL acc1 : STD_LOGIC_VECTOR (7 downto 0);
	SIGNAL pc1 : STD_LOGIC_VECTOR (11 downto 0);
	SIGNAL R_0, R_1, R_2, R_3 : STD_LOGIC_VECTOR (7 downto 0);
	
BEGIN

	CLK_50MHZ <= CLOCK_50;

--uut:FSMreg1 port map (xi, yi, clk, reset, reg, state);
uut : razem port map (
clock => clkx2,
reset => reset1,
pc => pc1,
acc => acc1,
R0 => R_0,
R1 => R_1,
R2 => R_2,
R3 => R_3,
cy_flag => Xi,
zero_flag => Yi
);

	PROCESS
	BEGIN
	 WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
		IF reset = '0' THEN
		 CLK_COUNT_400HZ <= X"00000";
		 CLK_400HZ <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"0F424" THEN 
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";
				 CLK_400HZ <= NOT CLK_400HZ;
				END IF;
		END IF;
	END PROCESS;
	
	PROCESS (CLK_400HZ)
	BEGIN
		IF CLK_400HZ'EVENT AND CLK_400HZ = '1' THEN
	-- GENERATE 1/10 SEC CLOCK SIGNAL FOR SECOND COUNT PROCESS
			IF CLK_COUNT_10HZ < 19 THEN
				CLK_COUNT_10HZ <= CLK_COUNT_10HZ + 1;
			ELSE
				CLK_COUNT_10HZ <= X"00";
				CLK_10HZ <= NOT CLK_10HZ;
			END IF;
		END IF;		
	END PROCESS;

LCD_CTRL1 : LCD_CTRL	PORT MAP(
		 CLK_400HZ,			
		 KEY(3), --reset
		 LCD_upper_x,
		 LCD_lower_x, 
		 -- DE2 LCD display control signals
		 LCD_RS, LCD_EN, LCD_ON,
		 LCD_RW,
		 -- DE2 LCD display data bus
		 LCD_DATA
		 ); 

	
	
	PROCESS (Clk_10hz, reset)
	BEGIN
		IF reset = '0' THEN	
			TSEC <= (others =>'0'); 
			CNT10 <= (others =>'0');
			CNT32 <= (others =>'0');
			CNT54 <= (others =>'0');
			CNT76 <= (others =>'0');

		ELSIF clk_10HZ'EVENT AND clk_10HZ = '1' THEN
-- TENTHS OF SECONDS
		IF TSEC < 9 THEN
		 TSEC <= TSEC + 1;
		ELSE
		 TSEC <= X"0";
-- SECONDS
		CNT10 <= CNT10+1;
		CNT32 <= CNT32-1;
		CNT54 <= CNT54+1;
		CNT76 <= CNT76-1;
       END IF;
	end if;
 END PROCESS;

LCD_upper_x (1 to 16) <= (1=> Hex2char(pc1(11 downto 8)),
								  2=> Hex2char(pc1(7 downto 4)),
								  3=> Hex2char(pc1(3 downto 0)),
								  4=> X"20",
								  5=> Hex2char(X"A"),
								  6=> Hex2char(X"C"),
								  7=> Hex2char(X"C"),
								  8=> (X"20"), 9=> X"20",
								10=> Hex2char(R_0(7 downto 4)), 11=> Hex2char(R_0(3 downto 0)),12=> X"20",
                       13=> X"20",14=> X"63",15=> Hex2char(X"E"), 16=> Hex2char(X"F"));
							  
LCD_lower_x (1 to 16) <= (1=> Hex2char(acc1(7 downto 4)), 2=> Hex2char(acc1(3 downto 0)),
									3=> X"20", 4=> X"20",5=> X"20",6=> X"20",7=> X"20",8=> X"20",9=> X"20",10=> X"20",11=> X"20",
									12=> X"20",
									13=> X"20",14=> X"20",15=> X"20",16=> X"20");

								  

--HEX <= (0=> X"0", 1=> X"1", 2=> X"2",3=> X"3",4=> X"4",5=> X"5",6=> X"6",7=> X"7");
--HEX <= (0=> X"8", 1=> X"9", 2=> X"A",3=> X"B",4=> X"C",5=> X"D",6=> X"E",7=> X"F");

HEX(0) <= reg (3 downto 0);
HEX(1) <= reg (7 downto 4);
HEX(2) <= reg (11 downto 8);
HEX(3) <= reg (15 downto 12);
--HEX(0) <= CNT10(3 downto 0);
--HEX(3) <= CNT32(7 downto 4);
--HEX(2) <= CNT32(3 downto 0);
--HEX(5) <= CNT54(7 downto 4);
--HEX(4) <= CNT54(3 downto 0);
--HEX(7) <= CNT76(7 downto 4);
--HEX(6) <= CNT76(3 downto 0);

--HEX(0) <= "0000";
--HEX(3) <= "0000";
--HEX(2) <= "0000";
HEX(5) <= "0000";
HEX(4) <= "0000";
HEX(7) <= '0'&state;
HEX(6) <= "0000";

HEX6 <= SEG7DEC (R_0( 3 downto 0));
HEX7 <= SEG7DEC (R_0(7 downto 4));
HEX4 <= SEG7DEC (R_1(3 downto 0));
HEX5 <= SEG7DEC (R_1(7 downto 4));
HEX2 <= SEG7DEC (R_2(3 downto 0));
HEX3 <= SEG7DEC (R_2(7 downto 4));
HEX0 <= SEG7DEC (R_3(3 downto 0));
HEX1 <= SEG7DEC (R_3(7 downto 4));
--HEX3 <= SEG7DEC (reg(15 downto 12));
--HEX2 <= SEG7DEC (reg(11 downto 8));
--HEX1 <= SEG7DEC (reg(7 downto 4));
--HEX0 <= SEG7DEC (reg(3 downto 0));

--LEDR (17 downto 16) <= SW (17 downto 16);
--LEDR (15 downto 0) <= reg;

reset1 <= Key(0);
LEDG(0) <= Key(0);
--LEDG(0) <= reset;

clkx2 <= KEY (1);
process (clkx2, reset)
begin
if reset='0' then clk<='0';
elsif clkx2'event and clkx2='1' then
clk <= not clk;
end if;
end process;
LEDG(3) <= clk;
LEDG(2) <= clk;

LEDG(7) <=Xi;
LEDG(6) <=Yi;

--Xex <= KEY (3);
--process (Xex, reset)
--begin
--if reset='0' then Xi<='0';
--elsif Xex'event and Xex='1' then
--Xi <= not Xi;
--end if;
--end process;
--LEDG(7) <= Xi;
--LEDG(6) <= Xi;
--
--Yex <= KEY (2);
--process (Yex, reset)
--begin
--if reset='0' then Yi<='0';
--elsif Yex'event and Yex='1' then
--Yi <= not Yi;
--end if;
--end process;
--LEDG(5) <= Yi;
--LEDG(4) <= Yi;








--process (clk, reset)
--begin
--  if reset='0' then
--    reg <= (others => '0');
--  elsif clk'event and clk='1' then
--    reg <= not reg(0) & reg(15 downto 1);
--  end if;
-- end process;
 
END RTL;