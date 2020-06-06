--2018/11/20
--寄物櫃管理系統
--指令表：0xOO
--FF：空指令
--EE：軟體RESET
--AB：選取情形(單獨)
--CA：寄物
--CB：取物
--AC：使用狀況
--EA：操作結束
--99：無空櫃子
--AAAAAAAA
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Cont_2018_2 is
	port(	CLK:in std_logic;
			RST:in std_logic;
			--UART
			TX:out std_logic;
			RX:in std_logic;
			--KEY BOARD
			KB_ROW:in std_logic_vector(3 downto 0);
			KB_COL:out std_logic_vector(3 downto 0);
			--DIP
			DIP:in std_logic_vector(7 downto 0);
			--SEG1
			seg1_en:out std_logic_vector(3 downto 0);
			seg1s:out std_logic_vector(7 downto 0);
			--SEG2
			seg2_en:out std_logic_vector(3 downto 0);
			seg2s:out std_logic_vector(7 downto 0);
			--SEG3
			seg3_en:out std_logic_vector(3 downto 0);
			seg3s:out std_logic_vector(7 downto 0);
			--LCM
			LCM_RS:out std_logic;
			LCM_RW:out std_logic;
			LCM_EN:out std_logic;
			LCM_DB:out std_logic_vector(7 downto 0);
			--8X8 DOT
			COL:buffer std_logic_vector(7 downto 0);
			ROW_R:out std_logic_vector(7 downto 0);
			ROW_G:out std_logic_vector(7 downto 0);
			--LED
			LED_R:out std_logic;--92
			LED_G:out std_logic;--98
			LED_B:out std_logic;--95
			RGB:out std_logic_vector(2 downto 0);--92 98 95
			--Buzzer
			BEEP:out std_logic
			);
end Cont_2018_2;


architecture beh of Cont_2018_2 is
--UART TX
	component RS232_T1 is
	port(clk,reset:in std_logic;
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--000:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(1 downto 0);
		 TX_W:in std_logic;
		 TXData:in std_logic_vector(7 downto 0);
		 TX:out std_logic);
	end component RS232_T1;
--UART RX
	component RS232_R2 is
	port(Clk,Reset:in std_logic;
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--0xx:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(2 downto 0);
		 Rx_R:in std_logic;
		 RD:in std_logic;
		 RxDs:out std_logic_vector(7 downto 0));
	end component RS232_R2;





--Divider signal
signal Q:std_logic_vector(26 downto 0);
signal Q1:std_logic_vector(26 downto 0);
signal Q2:std_logic_vector(26 downto 0);
--Divided CLKs
signal scan_clk:std_logic;
signal LCM_clk:std_logic;
signal UART_CLK:std_logic;
signal MAIN_CLK:std_logic;
signal blink_clk:std_logic;
signal clk_8hz:std_logic;
--UART
	--Settings
constant DL:std_logic_vector(1 downto 0):="11";	 	 --00:5,01:6,10:7,11:8 Bit
constant ParityN:std_logic_vector(2 downto 0):="000";--0xx:None,100:Even,101:Odd,110:Space,111:Mark
constant StopN:std_logic_vector(1 downto 0):="00";	 --0x>1Bit,10>2Bit,11>1.5Bit
--constant F_Set:std_logic_vector(2 downto 0):="101";	 --9600 BaudRate
constant F_Set:std_logic_vector(2 downto 0):="010";	 --1200 BaudRate
	--Data
signal CMDn,CMDn_R:integer range 0 to 63;		--Rs232傳出數,接收數
		--上傳PC資料(6 byte)
type pc_up_data_T is array(0 to 49) of std_logic_vector(7 downto 0);
		--命令
signal pc_up_data:pc_up_data_T:=(others=>X"FF");
		--接收PC資料(3 byte)
type pc_down_data_T is array(0 to 2) of std_logic_vector(7 downto 0);
		--資料
signal pc_down_data:pc_down_data_T:=(X"FF",X"FF",X"FF");
signal S_RESET_T,S_RESET_R:std_logic;		--Rs232 reset
	--TX
signal TX_W:std_logic;							--寫入緩衝區
signal Status_Ts:std_logic_vector(1 downto 0);	--傳送狀態
signal TXData:std_logic_vector(7 downto 0);		--傳送資料
	--RX
Signal Rx_R:std_logic;
Signal Status_Rs:std_logic_vector(2 downto 0);
Signal RXData,RxDs:std_logic_vector(7 downto 0);
--LCM signals
type DDRAM is array(0 to 15) of std_logic_vector(7 downto 0);
type CGRAM is array(0 to 7) of std_logic_vector(7 downto 0);
type characters is array(0 to 7) of CGRAM;
	--顯示內容
signal LINE1:DDRAM;
signal LINE2:DDRAM;
	--動作完成
signal init_done:std_logic;
signal creat_char_done:std_logic;
--7SEG
type seg_data is array (0 to 3) of integer range 0 to 15;
signal seg1_d:seg_data;
signal seg2_d:seg_data;
signal seg3_d:seg_data;
--8X8 DOT
type x64data is array(0 to 7) of std_logic_vector(7 downto 0);
signal RDATA:x64data;
signal GDATA:x64data;
signal RD_bf:x64data;
signal GD_bf:x64data;
--KB scan & debounce
signal SCAN_CODE:std_logic_vector(3 downto 0);	--按鍵座標
signal VALID:std_logic;	--0無效 1有效(除彈跳完畢)
signal FREE:std_logic;	--按鍵狀態
signal operate_code:std_logic_vector(3 downto 0);

--MAIN signals
type control_flow is (idle ,check ,selection ,set_pw ,result ,placing ,password ,pw_error ,pw_correct ,unavailable ,done ,endop ,update);
signal customer_flow:control_flow;
type LCD_ROM is array(0 to 13) of DDRAM;
signal  L1_RAM:LCD_ROM:=(
((others => X"FE")),																											--0全白
(X"53",X"74",X"61",X"6e",X"64",X"20",X"62",X"79",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--1 stand by
(X"57",X"65",X"6c",X"63",X"6f",X"6d",X"65",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--2 welcome
(X"50",X"6f",X"73",X"74",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--3 post
(X"53",X"65",X"6c",X"65",X"63",X"74",X"20",X"4e",X"6f",X"3a",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--4 select no:(編號)
(X"50",X"6f",X"73",X"74",X"69",X"6e",X"67",X"2e",X"2e",X"2e",X"2e",X"2e",X"FE",X"FE",X"FE",X"FE"),	--5 posing.....
(X"4E",X"6F",X"74",X"20",X"61",X"76",X"61",X"69",X"6C",X"61",X"62",X"6C",X"65",X"21",X"FE",X"FE"),	--6 not available
(X"54",X"68",X"61",X"6E",X"6B",X"20",X"79",X"6F",X"75",X"21",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--7 3Q
(X"54",X"61",X"6b",X"65",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--8 take
(X"50",X"72",X"65",X"73",X"73",X"20",X"50",X"61",X"73",X"73",X"77",X"6f",X"72",X"64",X"3a",X"FE"),	--9 press password
(X"50",X"61",X"73",X"73",X"77",X"6f",X"72",X"64",X"20",X"4f",X"4b",X"21",X"FE",X"FE",X"FE",X"FE"),	--10 passwordok!
(X"46",X"61",X"69",X"6c",X"65",X"64",X"20",X"31",X"21",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--11 failed x! 7
(X"4e",X"6f",X"3a",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--12 No:(3)(明細表)
(X"54",X"61",X"6b",X"65",X"69",X"6e",X"67",X"2e",X"2e",X"2e",X"2e",X"2e",X"FE",X"FE",X"FE",X"FE"));--13 takeing
signal L2_RAM:LCD_ROM:=(
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),--4 (No.)
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),--9 (password)
((others => X"FE")),
((others => X"FE")),
(X"50",X"61",X"73",X"73",X"77",X"6f",X"72",X"64",X"3a",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),--(12)(9) Password:(明細表)
((others => X"FE")));
signal LCD_data_pointer:integer range 0 to 15;

type storer_available is array(0 to 23) of std_logic_vector(15 downto 0);
signal database:storer_available;--資料
type chest_pw_form is array(0 to 23) of std_logic_vector(23 downto 0);
signal chest_pw:chest_pw_form;--密碼(6位 24bit)


signal DIP_deb:std_logic_vector(39 downto 0);
signal DIP_deb_done:std_logic_vector(7 downto 0);
signal single_trigger:std_logic;
signal DIP_trigger:std_logic_vector(7 downto 0);
signal clo_num:integer range 0 to 15;
--92 95 98
signal rent_take:std_logic;
signal pw_pointer:integer range 0 to 6;
type PWs is array(0 to 5) of integer range 0 to 15;
signal passwords:PWs;
signal PW:std_logic_vector(23 downto 0);
signal count_ables:std_logic;
type data_sel is array(0 to 7) of std_logic_vector(7 downto 0);

--variable data_selected:data_sel;
signal data_sel_pointer:integer range 0 to 15;
signal receipt_sel:integer range 0 to 7;

signal pw_wrong_times:integer range 0 to 3;
signal out_reg : std_logic_vector(3 downto 0):="0000";

--LED_ENs
signal LED_Ren:std_logic;
signal LED_Gen:std_logic;
signal LED_Ben:std_logic;
signal RGBen:std_logic_vector(2 downto 0);
signal beep_en:std_logic;
signal beep_t:integer range 0 to 3;
signal return_idle:std_logic;
signal delay1s:std_logic;
signal quest_rst:std_logic;
signal rst_done:std_logic;
signal delay_done:std_logic;
signal delay_2s:std_logic;
signal delay1s_done:std_logic;
signal blink_clk_dot5:std_logic;
	procedure dot8X8	(displays:in std_logic_vector(1 downto 0);
							numbers:in std_logic_vector(7 downto 0)) is
	begin
		--點矩陣顯示
		case numbers is
			when X"01"=>
				GD_bf(0)(0)<=displays(0);RD_bf(0)(0)<=displays(1);
			when X"02"=>
				GD_bf(1)(0)<=displays(0);RD_bf(1)(0)<=displays(1);
			when X"03"=>
				GD_bf(2)(0)<=displays(0);RD_bf(2)(0)<=displays(1);
			when X"04"=>
				GD_bf(3)(0)<=displays(0);RD_bf(3)(0)<=displays(1);
			when X"05"=>
				GD_bf(0)(1)<=displays(0);RD_bf(0)(1)<=displays(1);
			when X"06"=>
				GD_bf(1)(1)<=displays(0);RD_bf(1)(1)<=displays(1);
			when X"07"=>
				GD_bf(2)(1)<=displays(0);RD_bf(2)(1)<=displays(1);
			when X"08"=>
				GD_bf(3)(1)<=displays(0);RD_bf(3)(1)<=displays(1);
			
			when X"09"=> GD_bf(0)(2)<=displays(0);RD_bf(0)(2)<=displays(1);
			when X"10"=> GD_bf(1)(2)<=displays(0);RD_bf(1)(2)<=displays(1);
			when X"11"=> GD_bf(2)(2)<=displays(0);RD_bf(2)(2)<=displays(1);
			when X"12"=> GD_bf(3)(2)<=displays(0);RD_bf(3)(2)<=displays(1);
			when others=>
		end case;
	end dot8X8;
--UART controls
begin
U1:RS232_T1 Port Map(UART_CLK,S_RESET_T,DL,ParityN,StopN,F_Set,Status_Ts,TX_W,TXData,TX);
U2:RS232_R2 Port Map(UART_CLK,S_RESET_R,DL,ParityN,StopN,F_Set,Status_Rs,Rx_R,RX,RxDs);

Divider:
process(RST,CLK)
	variable LCM_CNT:integer;
begin
	if RST='0' then
		Q<= (others => '0');
		Q1<= (others => '0');
		Q2<= (others => '0');
		blink_clk<='0';
		clk_8hz<='0';
		LCM_clk<='0';
		LCM_CNT:=0;
	elsif rising_edge(CLK) then
		Q<=Q+1;
		if LCM_CNT=50_000 then	--50M/(2*50K)=0.5K=500 Hz
			LCM_CNT:=0;
			LCM_clk<=not LCM_clk;
		else
			LCM_CNT:=LCM_CNT+1;
		end if;
		if Q1=50_000_000 then
			blink_clk<=not blink_clk;
			Q1<= (others=> '0');
		else
			Q1<=Q1+1;
		end if;
		
		if Q2=3_125_000 then --50M/(2x)=8  x=3125000
			clk_8hz<=not clk_8hz;
			Q2<= (others => '0');
		else
			Q2<=Q2+1;
		end if;
	end if;
end process;
UART_CLK<=Q(0);
scan_clk<=Q(14);
MAIN_CLK<=Q(16);
LCM_EN<=LCM_clk;
	
delay:
process(rst_done,CLK)
	variable count:integer range 0 to 1023;
	variable count1s:integer range 0 to 1023;
	variable count2:integer range 0 to 1023;
begin
	if rst_done='0' then
		count:=0;
		count1s:=0;
		count2:=0;
		delay_done<='0';
		delay_2s<='0';
		delay1s_done<='0';
		blink_clk_dot5<='0';
	elsif rising_edge(LCM_clk) then --500hz
		if count>=500 then
			delay_done<='1';
		else
			count:=count+1;
			delay_done<='0';
		end if;
		
		if return_idle='1' then
		--計算延遲
			case count2 is
				when 0 to 250=>blink_clk_dot5<='0';
				when 251 to 500=>blink_clk_dot5<='1';
				when 501 to 750=>blink_clk_dot5<='0';
				when 751 to 1000=>blink_clk_dot5<='1';
				when others=>
			end case;
			if count2>=1000 then
				delay_2s<='1';
			else
				count2:=count2+1;
				delay_2s<='0';
			end if;
		else
			delay_2s<='0';
			blink_clk_dot5<='0';
			count2:=0;
		end if;
		
		if delay1s='1' then
		--計算延遲
			if count1s<=250 then
				blink_clk_dot5<='0';
			elsif count1s<=500 then
				blink_clk_dot5<='1';
			else
				blink_clk_dot5<='0';
			end if;
			if count1s>=1000 then
				delay1s_done<='1';
			else
				count1s:=count1s+1;
				delay1s_done<='0';
			end if;
		else
			delay1s_done<='0';
			count1s:=0;
		end if;
	end if;
end process;

--DIP除彈跳
debounce:
process(RST,scan_clk)
begin
	if RST='0' then
		DIP_deb<=(others=>'0');
		DIP_deb_done<="00000000";
	elsif rising_edge(scan_clk) then
		for i in 0 to 7 loop
			DIP_deb(5*i+4 downto 5*i)<= DIP(i) & DIP_deb(5*i+4 downto 5*i+1);
			if DIP_deb(5*i+4 downto 5*i)="11111" then
				DIP_deb_done(i)<='1';
			elsif DIP_deb(5*i+4 downto 5*i)="00000" then
				DIP_deb_done(i)<='0';
			end if;
		end loop;
	end if;
end process;

--上傳PC資料
TXData<=	pc_up_data(CMDn-1);
--pc_down_data:

--LCD資料
LINE1<=L1_RAM(LCD_data_pointer);
LINE2<=L2_RAM(LCD_data_pointer);

Main:
process(RST,quest_rst,MAIN_CLK)
	variable delayss:std_logic;
	variable data_placed:std_logic;
	variable selected:std_logic;
	variable data_selected:data_sel;
	variable dot_displays:std_logic_vector(1 downto 0);
	variable LCD_displays:integer range 0 to 7;
	variable storer_ables:integer range 0 to 31;
	variable price:integer range 0 to 2047;
	
	variable nums:integer range 0 to 31;
	variable row:integer range 0 to 7;
	variable col:integer range 0 to 7;
	variable sel_big:integer range 0 to 15;
	variable sel_med:integer range 0 to 15;
	variable sel_small:integer range 0 to 15;
	variable rnd_num:integer range 0 to 9;
begin
	if RST='0' or quest_rst='1' then
		customer_flow<=idle;
		--UART RST
		Rx_R<='0';			--取消讀取信號
		TX_W<='0';			--取消資料載入信號
		S_RESET_T<='0';		--關閉RS232傳送
		S_RESET_R<='0';		--關閉RS232接收
		CMDn<=1;			--上傳6byte(上傳AD)
		CMDn_R<=3;			--接收數量(3byte)
		return_idle<='0';
		delay1s<='0';
		pc_down_data<=(X"FF",X"FF",X"FF");
		--UART transaction
		pc_up_data(0)<=X"EE";--0xEE 軟體RST
		--顯示資料
L1_RAM<=(
((others => X"FE")),																											--0全白
(X"53",X"74",X"61",X"6e",X"64",X"20",X"62",X"79",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--1 stand by (8~14)可加(full!)
(X"57",X"65",X"6c",X"63",X"6f",X"6d",X"65",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--2 welcome
(X"53",X"65",X"6c",X"65",X"63",X"74",X"20",X"73",X"65",X"72",X"76",X"69",X"63",X"65",X"3a",X"FE"),	--3 select service(diposit)
(X"53",X"65",X"6c",X"65",X"63",X"74",X"20",X"6c",X"75",X"67",X"67",X"61",X"67",X"65",X"FE",X"FE"),	--4 select luggage
(X"44",X"65",X"70",X"6f",X"73",X"69",X"74",X"20",X"6c",X"75",X"67",X"67",X"61",X"67",X"65",X"FE"),	--5 Deposit luggage
(X"4E",X"6F",X"74",X"20",X"61",X"76",X"61",X"69",X"6C",X"61",X"62",X"6C",X"65",X"21",X"FE",X"FE"),	--6 not available
(X"54",X"68",X"61",X"6E",X"6B",X"20",X"79",X"6F",X"75",X"21",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--7 3Q
(X"53",X"65",X"6c",X"65",X"63",X"74",X"20",X"73",X"65",X"72",X"76",X"69",X"63",X"65",X"3a",X"FE"),	--8 select service(take out)
(X"45",X"6e",X"74",X"65",X"72",X"20",X"70",X"61",X"73",X"73",X"77",X"6f",X"72",X"64",X"3a",X"FE"),	--9 enter password
(X"53",X"65",X"74",X"20",X"70",X"61",X"73",X"73",X"77",X"6f",X"72",X"64",X"3a",X"FE",X"FE",X"FE"),	--10 set password:
(X"46",X"61",X"69",X"6c",X"65",X"64",X"20",X"31",X"21",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--11 failed x! 7
(X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE"),	--12 No:(3)(明細表)
(X"54",X"61",X"6b",X"65",X"20",X"6f",X"75",X"74",X"20",X"6c",X"75",X"67",X"67",X"61",X"67",X"65"));--13 Take out luggage
L2_RAM<=(
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
(X"44",X"65",X"70",X"6f",X"73",X"69",X"74",X"20",X"6c",X"75",X"67",X"67",X"61",X"67",X"65",X"FE"),--3 Deposit luggage
((others => X"FE")),--4 (No.)
((others => X"FE")),
((others => X"FE")),
((others => X"FE")),
(X"54",X"61",X"6b",X"65",X"20",X"6f",X"75",X"74",X"20",X"6c",X"75",X"67",X"67",X"61",X"67",X"65"),--8 Take out luggage
((others => X"FE")),--9 (password)
((others => X"FE")),--10 set password
((others => X"FE")),
((others => X"FE")),--(12)(9) Password:(明細表)
((others => X"FE")));
		RD_bf<=(others=>X"FF");
		GD_bf<=(others=>X"00");
		LED_Ren<='1';
		LED_Gen<='1';
		LED_Ben<='1';
		RGBen<="111";
		LCD_data_pointer<=0; --LCD:全白
		LCD_displays:=0;
		data_placed:='0';
		seg1_d<=	(0,0,0,0);--left 金額
		seg2_d<=	(0,0,0,0);--right 櫃子數量
		row:=0;
		col:=0;
		--UART transaction
		--data RST
		rent_take<='0'; --寄物
		sel_big:=0;
		sel_med:=0;
		sel_small:=0;
		delayss:='0';
		selected:='0';
		beep_en<='0';
		single_trigger<='0'; --單次觸發
		DIP_trigger<="00000000";
		dot_displays:="00";
		price:=0;
		storer_ables:=0;
		count_ables<='0';
		data_sel_pointer<=0;
		data_selected:=((0 to 7=>X"FF"));
		database<=( --櫃子狀態 前2編號 後2狀態(X0可用X1已用1X被選)
		X"0100",X"0200",
		X"0300",X"0400",
		X"0500",X"0600",
		X"0700",X"0800",
		X"0900",X"1000",
		X"1100",X"1200",
		X"1300",X"1400",
		X"1500",X"1600",
		X"1700",X"1800",
		X"1900",X"2000",
		X"2100",X"2200",
		X"2300",X"2400");
		rst_done<='0';
		--TEST
	elsif (Rx_R='1' and Status_Rs(2)='0') then	--rs232接收即時處理
		Rx_R<='0';								--即時取消讀取信號
	elsif rising_edge(MAIN_CLK) then
		S_RESET_R<='1';
		S_RESET_T<='1';
		rst_done<='1';
		--TX
		if CMDn>0 and S_RESET_T='1' then--上傳剩餘數量
			if Status_Ts(1)='0' then	--傳送緩衝區已空
				if TX_W='1' then
					TX_W<='0';			--取消傳送資料載入時脈
					CMDn<=CMDn-1;		--指標指向下一筆資料
				else
					TX_W<='1';			--傳送資料載入時脈
				end if;
			end if;
		--RX
		elsif Status_Rs(2)='1' Then	--已接收PC資料
			Rx_R<='1';				--讀取信號
			CMDn_R<=CMDn_R-1;
			--PC命令解析-------------------
			RXData<=RxDs;			--取出資料
			pc_down_data(CMDn_R-1)<=RxDs;
			if RxDs=X"CA" or RxDs=X"CB" then --接收櫃子情況
				pc_down_data(2)<=RxDs;
				CMDn_R<=0;
			elsif RxDs=X"AB" then --目前找不到問題 固強制把CMDn_R接成2(3-1) [選取情形]
				pc_down_data(2)<=RxDs;
				CMDn_R<=2;
			end if;
		elsif CMDn_R=0 then --完全接收完畢
			CMDn_R<=3; --重置接收數量
			--資料處理
			case pc_down_data(2) is
				when X"AB"=>--接收選取情形 1編號 0狀態
					for i in 0 to 11 loop
						if database(i)(15 downto 8) = pc_down_data(1) then
							database(i)(7 downto 4)<=pc_down_data(0)(7 downto 4); --選擇狀態
						end if;
						if i<8 then
							if pc_down_data(0)(7 downto 4)=X"1" then --選取
								if data_selected(i)=X"FF" then
									data_selected(i):=pc_down_data(1);
									data_sel_pointer<=data_sel_pointer+1;
								end if;
							elsif pc_down_data(0)(7 downto 4)=X"0" then --取消選取
								if data_selected(i)=pc_down_data(1) then
									data_selected(i):=X"FF";
									data_sel_pointer<=data_sel_pointer-1;
								end if;
							end if;
						end if;
					end loop;
				when X"CA"=>--寄物
					rent_take<=pc_down_data(2)(0);
				when X"CB"=>--取物
					rent_take<=pc_down_data(2)(0);
				when others=>
			end case;
		else --主動作
			---------------------------UART above
			--主流程-------------------
			case customer_flow is
				when idle=> --待機狀態
					if delay_done='1' then --reset計時完畢
						RD_bf<=(others=>X"00");
						GD_bf<=(	"11111110",
									"00010000",
									"00010000",
									"11111110",
									"00000000",
									"00000000",
									"11110100",
									"00000000");
						LCD_data_pointer<=2; --LCD:welcome
						seg1_d<=	(0,0,0,0);--left 金額
						seg2_d<=	(0,0,0,0);--right (選擇)櫃子數量
						price:=0;
						selected:='0';
						data_sel_pointer<=0;
						data_selected:=((0 to 7=>X"FF"));
						if single_trigger='1' and FREE='1' then 		--未按下
							single_trigger<='1';								--單次觸發標示1
						elsif single_trigger='1' and FREE='0' then	--按下
							single_trigger<='0';								--單次觸發標示0
						elsif operate_code="0100" and FREE='1' then 	--放開
							single_trigger<='1';								--單次觸發
							LCD_data_pointer<=2; --welcome
							storer_ables:=0;
							RD_bf<=(others=>X"00");
							GD_bf<=(others=>X"00");
							customer_flow<=check;
						end if;
					end if;
					
				when check=> --確認狀態(寄或取)
					pw_wrong_times<=0;
					for i in 0 to 11 loop --檢查所有櫃子狀態
						--更新點矩陣畫面
						if database(i)(0)='0' then
							dot_displays:="01"; --RG
						else
							dot_displays:="10";
						end if;
						--點矩陣顯示
						dot8X8(dot_displays,database(i)(15 downto 8));
					end loop;
					if rent_take='0' then --寄物
						--已租暗 可租綠 未付款橙(其他不顯示) 關櫃後暗 只剩綠(可租)
						LCD_data_pointer<=3; --post
					else --取物
						--已租紅 可租暗 未打密碼橙(其他不顯示) 開櫃後暗 只剩紅(已租)
						LCD_data_pointer<=8; --take
					end if;
					
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						if operate_code="0100" then					--確認
							return_idle<='0';
							delay1s<='0';
							for i in 0 to 12 loop
								if i<12 then
									pc_up_data(2*i to 2*i+1)<=(database(i)(7 downto 0),database(i)(15 downto 8));
									if database(i)(3 downto 0)=X"0" then
										storer_ables:=storer_ables+1;
									end if;
								else
									pc_up_data(2*i to 2*i+1)<=(X"AC",X"FF");--0xAC 使用狀況
								end if;
							end loop;
							CMDn<=25;
							customer_flow<=selection;
						elsif operate_code="1000" then 				--返回
							pc_up_data(0)<=X"EA";--0xEA 操作結束
							CMDn<=1;
							customer_flow<=idle;
						end if;
					end if;
				
				when selection=> --顯示選取項目
					LCD_data_pointer<=4; --select luggage
					
					for i in 0 to 6 loop																--排序(小to大)
						for j in 0 to 6-i loop
							if data_selected(j+1)<data_selected(j) then
								data_selected(j):=data_selected(j+1)+data_selected(j);	--將兩項先+到前項
								data_selected(j+1):=data_selected(j)-data_selected(j+1);	--後項=前項(總和)-後項(較小者)
								data_selected(j):=data_selected(j)-data_selected(j+1);	--前項=前項(總和)-後項(變成較大者)
							end if;
						end loop;
					end loop;
					if rent_take='1' then --取物
						for i in 0 to 11 loop --檢查所有櫃子狀態
							--更新點矩陣畫面
							if database(i)(0)='1' then
								dot_displays:="10"; --RG
							else
								dot_displays:="00";
							end if;
							--點矩陣顯示
							dot8X8(dot_displays,database(i)(15 downto 8));
						end loop;
						if single_trigger='1' and FREE='1' then 		--未按下
							single_trigger<='1';								--單次觸發標示1
						elsif single_trigger='1' and FREE='0' then	--按下
							single_trigger<='0';								--單次觸發標示0
						elsif FREE='1' then 	--放開
							single_trigger<='1';								--單次觸發
							return_idle<='0';
							delay1s<='0';
							customer_flow<=password;
						end if;
					else --寄物
						for i in 0 to 11 loop --檢查所有櫃子狀態
							--更新點矩陣畫面
							if database(i)(0)='0' then
								dot_displays:="01"; --RG
							else
								dot_displays:="00";
							end if;
							--點矩陣顯示
							dot8X8(dot_displays,database(i)(15 downto 8));
						end loop;
						if single_trigger='1' and FREE='1' then 		--未按下
							single_trigger<='1';								--單次觸發標示1
						elsif single_trigger='1' and FREE='0' then	--按下
							single_trigger<='0';								--單次觸發標示0
						elsif FREE='1' then 	--放開
							single_trigger<='1';								--單次觸發
							if operate_code="0100" then					--確認
								price:=0;
								for i in 0 to 11 loop
									if database(i)(7 downto 4)=X"1" then
										case i is
											when 0 to 3 => price:=price+50;sel_small:=sel_small+1;
											when 4 to 8=> price:=price+100;sel_med:=sel_med+1;
											when others=> price:=price+150;sel_big:=sel_big+1;
										end case;
									end if;
								end loop;
								customer_flow<=set_pw;
							elsif operate_code="1000" then				--返回
								if rent_take='0' then
									LCD_data_pointer<=3; --post
								else
									LCD_data_pointer<=8; --take
								end if;
								seg1_d<=(0,0,0,0);
								customer_flow<=check;
							end if;
						end if;
					end if;
				
				when set_pw=> --設定密碼
					LCD_data_pointer<=10; --set password
					for i in 0 to 3 loop
						L2_RAM(10)(i)<=conv_std_logic_vector(48+passwords(i),8);
					end loop;
					for i in 0 to 11 loop --檢查所有櫃子狀態
						--更新點矩陣畫面
						if database(i)(0)='0' and database(i)(7 downto 4)=X"1" then
							dot_displays:="01"; --RG
						else
							dot_displays:="00";
						end if;
						--點矩陣顯示
						dot8X8(dot_displays,database(i)(15 downto 8));
					end loop;
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						for i in 0 to 11 loop
							if database(i)(4)='1' then
								chest_pw(i)<=PW;
							end if;
						end loop;
						if operate_code="0100" then					--確認
							customer_flow<=result;
						elsif operate_code="1000" then				--返回
							customer_flow<=selection;
						end if;
					end if;
				when password=> --輸入密碼(取物)
					LCD_data_pointer<=9; --press password
					if delay1s_done='1' then
						delay1s<='0';
					end if;
					nums:=(10*conv_integer(data_selected(0)(7 downto 4)) + conv_integer(data_selected(0)(3 downto 0)))-1;
					--密碼處理最下方
					for i in 0 to 3 loop
						L2_RAM(9)(i)<=conv_std_logic_vector(48+passwords(i),8);
					end loop;
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						return_idle<='0';
						if operate_code="0100" then					--確認
							if PW=chest_pw(nums) then
								customer_flow<=pw_correct;
							else
								return_idle<='1';
								pw_wrong_times<=pw_wrong_times+1;
								customer_flow<=pw_error;
							end if;
						elsif operate_code="1000" then				--返回
							LCD_data_pointer<=8; --take
							customer_flow<=check;
						end if;
					end if;
					
				when pw_correct=> --密碼正確 取物中
					LCD_data_pointer<=13; --takeing
					for j in 0 to 7 loop
						if DIP_trigger(j)='0' and DIP_deb_done(j)='0' then --上一次動作尚未放開
							DIP_trigger(j)<='0'; 							--單次觸發鎖在1
						elsif DIP_deb_done(j)='1' then 					--放開
							DIP_trigger(j)<='1'; 							--釋放
						elsif DIP_trigger(j)='1' and DIP_deb_done(j)='0' then 	--確認鍵
							DIP_trigger(j)<='0';								--產生觸發
							clo_num<=j;
							return_idle<='1';
							seg1_d<=(0,0,0,0);
							seg2_d<=	(0,0,0,0);--right 櫃子數量
						end if;
					end loop;
					if delay_2s='1' then
						return_idle<='0';
						for i in 0 to 11 loop
							if database(i)(15 downto 8)=data_selected(7-clo_num) then --被選 可取
								database(i)(7 downto 0)<=X"00";--已取
								storer_ables:=storer_ables+1;
							end if;
						end loop;
					end if;
					for i in 0 to 11 loop
						--更新點矩陣畫面
						if database(i)(7 downto 0)=X"11" then
							dot_displays:="11"; --RG
						elsif database(i)(7 downto 0)=X"01" then
							dot_displays:="10";
						else
							dot_displays:="00";
						end if;
						--點矩陣顯示
						dot8X8(dot_displays,database(i)(15 downto 8));
					end loop;
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						if operate_code="0100" then					--確認
							LCD_data_pointer<=7; --3Q
							return_idle<='1'; --開始計算延遲
							customer_flow<=done;
						elsif operate_code="1000" then				--返回
							customer_flow<=password;
						end if;
					end if;
					
				when pw_error=>
					LCD_data_pointer<=11; --password error
					L1_RAM(11)(7)<=X"3" & conv_std_logic_vector(pw_wrong_times,4);
					if delay_2s='1' then
						delay1s<='1';
						return_idle<='0';
						if pw_wrong_times=3 then
							customer_flow<=idle;
						else
							customer_flow<=password;
						end if;
					end if;
					
				when result=> --明細(寄物)
					seg1_d<=(price/1000,(price/100)mod 10,(price/10)mod 10,price mod 10);
					seg2_d<=(sel_big+sel_med+sel_small,sel_big,sel_med,sel_small);
					LCD_data_pointer<=12; --No:(明細表)
					nums:=(10*conv_integer(data_selected(receipt_sel)(7 downto 4)) + conv_integer(data_selected(receipt_sel)(3 downto 0)))-1;
					row:=(nums/4)+1;
					col:=(nums mod 4)+1;
					L1_RAM(12)(0 to 2)<=(X"3" & conv_std_logic_vector(row,4),X"2D",X"3" & conv_std_logic_vector(col,4));
					nums:=(10*conv_integer(data_selected(receipt_sel+1)(7 downto 4)) + conv_integer(data_selected((receipt_sel)+1)(3 downto 0)))-1;
					row:=(nums/4)+1;
					col:=(nums mod 4)+1;
					L2_RAM(12)(0 to 2)<=(X"3" & conv_std_logic_vector(row,4),X"2D",X"3" & conv_std_logic_vector(col,4));
					for i in 0 to 11 loop --檢查所有櫃子狀態
						--更新點矩陣畫面
						if database(i)(0)='0' and database(i)(4)='1' then
							dot_displays:="01"; --RG
						else
							dot_displays:="00";
						end if;
						--點矩陣顯示
						dot8X8(dot_displays,database(i)(15 downto 8));
					end loop;
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						return_idle<='0';
						if operate_code="0100" then					--確認
							customer_flow<=placing;
						elsif operate_code="1000" then				--返回
							customer_flow<=selection;
						end if;
					end if;
					
				when placing=> --寄物
					LCD_data_pointer<=5; --posting.....
					seg1_d<=(0,0,0,0);
					seg2_d<=	(0,0,0,0);--right 櫃子數量
					for j in 0 to 7 loop
						if DIP_trigger(j)='0' and DIP_deb_done(j)='0' then 		--上一次動作尚未放開
							DIP_trigger(j)<='0'; 							--單次觸發鎖在1
						elsif DIP_deb_done(j)='1' then 	--放開
							DIP_trigger(j)<='1'; 							--釋放
						elsif DIP_trigger(j)='1' and DIP_deb_done(j)='0' then 	--確認鍵
							DIP_trigger(j)<='0';								--產生觸發
							clo_num<=j;
							return_idle<='1'; --計算2S
						end if;
					end loop;
					if delay_2s='1' then
						return_idle<='0';
						for i in 0 to 11 loop
							if database(i)(15 downto 8)=data_selected(7-clo_num) then --被選 可用
								database(i)(7 downto 0)<=X"01";--已用
								storer_ables:=storer_ables-1;
							end if;
							--點矩陣顯示
						end loop;
					end if;
					for i in 0 to 11 loop
						--更新點矩陣畫面
						if database(i)(7 downto 0)=X"10" then
							dot_displays:="11"; --RG
						elsif database(i)(7 downto 0)=X"00" then
							dot_displays:="01";
						else
							dot_displays:="00";
						end if;
						--點矩陣顯示
						dot8X8(dot_displays,database(i)(15 downto 8));
					end loop;
					if single_trigger='1' and FREE='1' then 		--未按下
						single_trigger<='1';								--單次觸發標示1
					elsif single_trigger='1' and FREE='0' then	--按下
						single_trigger<='0';								--單次觸發標示0
					elsif FREE='1' then 	--放開
						single_trigger<='1';								--單次觸發
						if operate_code="0100" then					--確認
							LCD_data_pointer<=7; --3Q
							return_idle<='1'; --開始計算延遲
							customer_flow<=done;
						elsif operate_code="1000" then				--返回
							customer_flow<=result;
						end if;
					end if;
					
				when unavailable=>
					if delay_2s='1' then
						if rent_take='0' then
							LCD_data_pointer<=3; --post
						else
							LCD_data_pointer<=8; --take
						end if;
						return_idle<='0';
						customer_flow<=check;
					end if;
				when done=>
					if delay_2s='1' then
						if storer_ables=0 then
							L1_RAM(1)(8 to 14)<=(X"28",X"46",X"75",X"6c",X"6c",X"21",X"29");
							pc_up_data(0 to 1)<=(X"99",X"EA");--0x99 無空櫃子
							CMDn<=2;
						else
							L1_RAM(1)(8 to 14)<=(X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE");
							pc_up_data(0)<=X"EA";--0xEA 操作結束
							CMDn<=1;
						end if;
						for i in 0 to 11 loop --檢查所有櫃子狀態
							--更新點矩陣畫面
							if database(i)(0)='0' then
								dot_displays:="01"; --RG
							else
								dot_displays:="10";
							end if;
							--點矩陣顯示
							dot8X8(dot_displays,database(i)(15 downto 8));
						end loop;
						seg1_d<=(0,0,0,0);
						seg2_d<=(0,0,0,0);
						storer_ables:=0;
						return_idle<='0'; --取消計算延遲
						customer_flow<=idle;
					end if;
				when endop=>
				when update=>
			end case;
			-----------------------------------------
		end if;
	end if;
end process;

--未拿起油槍 選定LED恆亮 其餘閃爍
--拿起油槍時 選定LED恆亮 其餘恆滅
LED_R<= 	'1' when customer_flow/=idle else
			'0';
LED_G<= '1';
LED_B<= 	blink_clk when customer_flow=pw_correct or customer_flow=placing else
			'0';
RGB(0)<=	blink_clk_dot5 when customer_flow=password or customer_flow=pw_error else
			'0';
RGB(2)<=	'0' when customer_flow=idle else
			'1' when rent_take='1' else
			'0';
RGB(1)<=	'0' when customer_flow=idle else
			'1' when rent_take='0' else
			'0';
BEEP<=LCM_clk when blink_clk_dot5='1' and (customer_flow=pw_error or customer_flow=idle) and pw_wrong_times>=3 else --任何按鈕被按下時鳴叫
		'0';
		
--RESET時RED亮1秒
--其餘根據選擇油品顯示
RDATA<=	RD_bf;
GDATA<=	GD_bf;
		
		--7段顯示
seg3_d<=	(0,0,0,0);
--7SEG 顯示處理
x1:block
signal EN:std_logic_vector(3 downto 0);
signal seg1_num:integer range 0 to 15;
signal seg2_num:integer range 0 to 15;
signal seg3_num:integer range 0 to 15;
begin
	SEG_SCAN:
	process(RST,scan_clk)
	begin
		if RST='0' then
			EN<="0111";
		elsif rising_edge(scan_clk) then
			EN<= EN(0) & EN(3 downto 1);
		end if;
	end process;
	seg1_en<=EN; seg2_en<=EN; seg3_en<=EN;
	with EN select
	seg1_num<=	seg1_d(3)when "0111",
					seg1_d(2)when "1011",
					seg1_d(1)when "1101",
					seg1_d(0)when "1110",
					11			when others;
	with EN select
	seg2_num<=	seg2_d(3)when "0111",
					seg2_d(2)when "1011",
					seg2_d(1)when "1101",
					seg2_d(0)when "1110",
					11			when others;
	with EN select
	seg3_num<=	seg3_d(3) when "0111",
					seg3_d(2) when "1011",
					seg3_d(1) when "1101",
					seg3_d(0) when "1110",
					11			when others;
	with seg1_num select
	seg1s<=	"11111100"	when 0,
					"01100000"	when 1,
					"11011010"	when 2,
					"11110010"	when 3,
					"01100110"	when 4,
					"10110110"	when 5,
					"10111110"	when 6,
					"11100000"	when 7,
					"11111110"	when 8,
					"11110110"	when 9,
					"00011100"	when 10,--L
					"00000000"	when others;
	with seg2_num select
	seg2s<=	"11111100"	when 0,
					"01100000"	when 1,
					"11011010"	when 2,
					"11110010"	when 3,
					"01100110"	when 4,
					"10110110"	when 5,
					"10111110"	when 6,
					"11100000"	when 7,
					"11111110"	when 8,
					"11110110"	when 9,
					"00011100"	when 10,--L
					"00000000"	when others;
	with seg3_num select
	seg3s<=	"11111100"	when 0,
					"01100000"	when 1,
					"11011010"	when 2,
					"11110010"	when 3,
					"01100110"	when 4,
					"10110110"	when 5,
					"10111110"	when 6,
					"11100000"	when 7,
					"11111110"	when 8,
					"11110110"	when 9,
					"00011100"	when 10,--L
					"00000000"	when others;
end block x1;
	
	
--8X8 DOT 顯示處理
x2:block
	signal ROW_SCAN:std_logic_vector(15 downto 0);
	signal ROW_COUNT:integer range 0 to 15;
	signal RDATA_bf:x64data;
	signal GDATA_bf:x64data;
begin
	process(RST,scan_clk)
	begin
		if RST='0' then
			ROW_SCAN<="1111111111111110";
			ROW_COUNT<=0;
		elsif rising_edge(scan_clk) then
			ROW_SCAN<=ROW_SCAN(14 downto 0) & ROW_SCAN(15);
			ROW_COUNT<=ROW_COUNT+1;
		end if;
	end process;
	G1:for i in 0 to 7 generate
		RDATA_bf(i)<=RDATA(i);
		GDATA_bf(i)<=GDATA(i);
	end generate G1;
	with ROW_COUNT select
	COL <=	RDATA_bf(7) when 15,
				RDATA_bf(6) when 14,
				RDATA_bf(5) when 13,
				RDATA_bf(4) when 12,
				RDATA_bf(3) when 11,
				RDATA_bf(2) when 10,
				RDATA_bf(1) when 9,
				RDATA_bf(0) when 8,
				
				GDATA_bf(7) when 7,
				GDATA_bf(6) when 6,
				GDATA_bf(5) when 5,
				GDATA_bf(4) when 4,
				GDATA_bf(3) when 3,
				GDATA_bf(2) when 2,
				GDATA_bf(1) when 1,
				GDATA_bf(0) when 0,
				"11111111" when others;
	ROW_R<=ROW_SCAN(15 downto 8);
	ROW_G<=ROW_SCAN(7 downto 0);
end block x2;
	
--LCD 初始化 建立自建字型 顯示處理
x3:block
		--初始化訊號
	signal init_count:integer range 0 to 63;
	type initialize is array(0 to 8) of std_logic_vector(7 downto 0);
	constant init_data:initialize:=(	
		"00111000",
		"00111000",
		"00111000",
		"00111000",
		"00001000",	--display off
		"00000001",	--clear display
		"00000110",	--set input 0000 01(I/D)S
		"00001100",	--open display 0000 1DCB
		"10000000"	--row1 col1
		);
		--自建字形
	constant CHARS:characters:=((	"00000000",		--heart symbol
											"00000000",
											"00001010",
											"00011111",
											"00011111",
											"00001110",
											"00000100",
											"00000000"),
											
										(	"00010000",		--年
											"00011111",
											"00000010",
											"00001111",
											"00001010",
											"00011111",
											"00000010",
											"00000000"),
											
										(	"00001111",		--月
											"00001001",
											"00001111",
											"00001001",
											"00001111",
											"00001001",
											"00010011",
											"00000000"),
											
										(	"00001111",		--日
											"00001001",
											"00001001",
											"00001111",
											"00001001",
											"00001001",
											"00001111",
											"00000000"),
											(others=>"00000000"),(others=>"00000000"),(others=>"00000000"),(others=>"00000000")
											);
		--自建字形訊號
	signal char_count:integer range 0 to 7;
		--內部資料
	signal LINE_buffer:std_logic_vector(7 downto 0);
	signal RS_bf:std_logic;
	signal RW_bf:std_logic;
		--位置指標
	signal col_pointer:integer range 0 to 15;
	signal row_pointer:std_logic;
		--設定座標
	signal set_addr:std_logic;
begin
	process(RST,LCM_clk)
	begin
		if RST='0' or quest_rst='1' then
			col_pointer<=0;
			row_pointer<='0';
			init_count<=0;
			init_done<='0';
			creat_char_done<='0';
			set_addr<='1';
			char_count<=0;
		elsif rising_edge(LCM_clk) then
			---------------------------------------計數器
			if init_done='0' then				--initialize
				if init_count>=8 then
					init_count<=0;
					init_done<='1';
				else
					init_count<=init_count+1;
				end if;
			elsif creat_char_done='0' then	--creat character
				if init_count>=8 then
					init_count<=0;
					if char_count<=3 then			--自建字形數
						char_count<=char_count+1;
					else
						creat_char_done<='1';
					end if;
				else
					init_count<=init_count+1;
				end if;
			else										--display
				if set_addr='1' then
					--pointer
					if col_pointer=15 then	--需要換行時
						col_pointer<=0;
						row_pointer<=not row_pointer;
						set_addr<='0';			--設定座標
					else
						col_pointer<=col_pointer+1;
					end if;
				else
					set_addr<='1';
				end if;
			end if;
			---------------------------------------資料準備
			if init_done='0' then	--initialize
				RS_bf<='0';			--command
				RW_bf<='0';			--write
				LINE_buffer<=init_data(init_count);
			elsif creat_char_done='0' then
				if init_count=0 then	--creat character
					RS_bf<='0';			--command
					case char_count is
						when 0=>
							LINE_buffer<=X"40";	--CGRAM address 0x40
						when 1=>
							LINE_buffer<=X"48";	--CGRAM address 0x48
						when 2=>
							LINE_buffer<=X"50";	--CGRAM address 0x50
						when 3=>
							LINE_buffer<=X"58";	--CGRAM address 0x58
						when 4=>
							LINE_buffer<=X"60";	--CGRAM address 0x60
						when 5=>
							LINE_buffer<=X"68";	--CGRAM address 0x68
						when 6=>
							LINE_buffer<=X"70";	--CGRAM address 0x70
						when 7=>
							LINE_buffer<=X"78";	--CGRAM address 0x78
					end case;
				else
					RS_bf<='1';	--data
					LINE_buffer<=CHARS(char_count)(init_count-1);	--第char_count個字型中 第init_count-1筆資料
				end if;
			else
				--data select
				if set_addr='1' then		--座標設定完成
					RS_bf<='1';	--data
					if row_pointer='0' then
						LINE_buffer<=LINE1(col_pointer);
					else
						LINE_buffer<=LINE2(col_pointer);
					end if;
				else							--設定座標
					RS_bf<='0';	--command
					if row_pointer='0' then
						LINE_buffer<="10000000";	--0
					else
						LINE_buffer<="11000000";	--1
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(RST,LCM_clk)
	begin
		if RST='0' then
			NULL;
		elsif falling_edge(LCM_clk) then
			---------------------------------------傳送資料
			LCM_RW<=RW_bf;
			LCM_RS<=RS_bf;
			LCM_DB<=LINE_buffer;
		end if;
	end process;
end block x3;

--Keyboard 掃描
x4:block
signal PR_ZERO:std_logic_vector(2 downto 0);
signal PR_ONE:std_logic_vector(2 downto 0);
signal PRESS:std_logic;
begin
	--SCAN_CODE:"0000"左上 "1111"右下
	--由上而下，由左至右
	KB_scan:--鍵盤電路
	process(scan_clk,RST)
	begin
		case SCAN_CODE(3 downto 2) is
			when "00"=> KB_COL<="1110";
			when "01"=> KB_COL<="1101";
			when "10"=> KB_COL<="1011";
			when "11"=> KB_COL<="0111";
		end case;
		case SCAN_CODE(1 downto 0) is
			when "00"=> PRESS<=KB_ROW(0);
			when "01"=> PRESS<=KB_ROW(1);
			when "10"=> PRESS<=KB_ROW(2);
			when "11"=> PRESS<=KB_ROW(3);
		end case;
		if RST='0' then
			PR_ZERO<="000";
			PR_ONE<="000";
			VALID<='0';
		elsif rising_edge(scan_clk) then
			if PRESS='1' then
				SCAN_CODE<=SCAN_CODE+1;
				PR_ZERO<="000";
				PR_ONE<=PR_ONE+1;
			elsif PRESS='0' then
				PR_ZERO<=PR_ZERO+1;
				PR_ONE<="000";
			end if;
			if PR_ZERO="101" and FREE='1' then
				VALID<='1';
				if SCAN_CODE="0000" then --除彈跳完畢並且RST鍵則重置
					quest_rst<='1';
				end if;
				FREE<='0';
			else
				VALID<='0';
			end if;
			if PR_ONE="101" then
				FREE<='1';
				PR_ZERO<="000";
				quest_rst<='0'; --放開時取消
			end if;
		end if;
	end process;
	
	process(RST,VALID)
		variable type_num:integer range 0 to 15;
	begin
		if quest_rst='1' or RST='0' or customer_flow=pw_error then
			operate_code<="0000";
			receipt_sel<=0;
			pw_pointer<=0;
			PW<=X"FFFFFF";
			passwords<=(15,15,15,15,15,15);
		elsif rising_edge(VALID) then
			--依照按鍵選擇功能
			operate_code<=SCAN_CODE;
			if customer_flow=password or customer_flow=pw_correct or customer_flow=result or customer_flow=set_pw then
				case SCAN_CODE is
					when "0001"=> type_num:=1;--1
					when "0101"=> type_num:=2;--2
					when "1001"=> type_num:=3;--3
					when "0010"=> type_num:=4;--4
					when "0110"=> type_num:=5;--5
					when "1010"=> type_num:=6;--6
					when "0011"=> type_num:=7;--7
					when "0111"=> type_num:=8;--8
					when "1011"=> type_num:=9;--9
					when "1110"=> type_num:=0;--0
					when "1111"=>				  --CLR
						if pw_pointer>0 then
							passwords(pw_pointer-1)<=15;
							PW(23-4*(pw_pointer-1) downto 20-4*(pw_pointer-1))<="1111";
							pw_pointer<=pw_pointer-1;
						end if;
					when "1100"=> --上
						if receipt_sel>0 then
							receipt_sel<=receipt_sel-1;
						end if;
					when "1101"=> --下
						if receipt_sel<data_sel_pointer then
							receipt_sel<=receipt_sel+1;
						end if;
					when others=>
				end case;
				if SCAN_CODE/="1111" and SCAN_CODE/="0100" then
					if pw_pointer<4 then
						passwords(pw_pointer)<=type_num;
						PW(23-4*pw_pointer downto 20-4*pw_pointer)<=conv_std_logic_vector(type_num,4);
						pw_pointer<=pw_pointer+1;
					end if;
				end if;
			else
				pw_pointer<=0;
				PW<=X"FFFFFF";
				passwords<=(15,15,15,15,15,15);
			end if;
		end if;
	end process;
end block x4;

x5:block --產生亂數密碼
signal pw_count:integer range 0 to 7;
signal chest_pointer:integer range 0 to 31;
signal rnd_done:std_logic;
--偽亂數產生器 LFSR
signal feedback : std_logic;
begin
	--LFSR 偽亂數
	feedback <= not (out_reg(3) xor out_reg(2));
	process (CLK,RST)
	begin
		 if (RST='0') then
			  out_reg <= "0000";
		 elsif (rising_edge(CLK)) then
			  out_reg <= out_reg(2 downto 0) & feedback;
		 end if;
	end process;

	process(CLK,RST)
	begin
		if (RST='0') or (quest_rst='1') then
			pw_count<=0;
			chest_pointer<=0;
			rnd_done<='0';
		elsif rising_edge(CLK) then
--			if rnd_done='0' then
--				if (out_reg<=X"9") then
--					if (database(chest_pointer)(4) or database(chest_pointer)(0))='0' then
--						chest_pw(chest_pointer)(4*pw_count+3 downto 4*pw_count)<=out_reg;
--						if pw_count=5 then
--							if chest_pointer=23 then
--								chest_pointer<=0;
--								rnd_done<='1';
--							else
--								chest_pointer<=chest_pointer+1;
--							end if;
--							pw_count<=0;
--						else
--							pw_count<=pw_count+1;
--						end if;
--					else
--						if chest_pointer=23 then
--								chest_pointer<=0;
--								rnd_done<='1';
--							else
--								chest_pointer<=chest_pointer+1;
--							end if;
--							pw_count<=0;
--					end if;
--				end if;
--			end if;
		end if;
	end process;
end block x5;
end beh;
