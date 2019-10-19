--2018/11/21
--OLED + 7段 + SD178BMI + TSL2561
--00:播放特定次數音樂
--01:調整聲道並播放亮度值
--10:調整MO狀態及OLED右上到右半滿畫面
--11:播放選定WAV特定秒數
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Cont_2018 is
	port	(	CLK:in std_logic;
				RST:in std_logic;
				DIP:in std_logic_vector(1 downto 0);
				DIP_sec:in std_logic_vector(5 downto 0);
				--KEY BOARD
				KB_ROW:in std_logic_vector(3 downto 0);
				KB_COL:out std_logic_vector(3 downto 0);
				--OLED
				OLED_SCL:inout std_logic;
				OLED_SDA:inout std_logic;
				--TSL2561
				TSL_SCL:inout std_logic;
				TSL_SDA:inout std_logic;
				--SD178BMI
				SD_SCL:inout std_logic;
				SD_SDA:inout std_logic;
				--SEG1
				seg1_en:out std_logic_vector(3 downto 0);
				seg1s:out std_logic_vector(7 downto 0);
				--SEG2
				seg2_en:out std_logic_vector(3 downto 0);
				seg2s:out std_logic_vector(7 downto 0)
				);
end Cont_2018;

architecture beh of Cont_2018 is
--OLED_driver
component ssd1306_i2c2wdriver4 is
   port(  I2CCLK,RESET:in std_logic;				--系統時脈,系統重置
		  SA0:in std_logic;							--裝置碼位址
		  CoDc:in std_logic_vector(1 downto 0);		--Co & D/C
		  Data_byte:in std_logic_vector(7 downto 0);--資料輸入
		  reLOAD:out std_logic;						--載入旗標:0 可載入Data Byte
		  LoadCK:in std_logic;						--載入時脈
		  RWN:in integer range 0 to 15;				--嘗試讀寫次數
		  I2Cok,I2CS:buffer std_logic;				--I2Cok,CS 狀態
		  SCL:inout std_logic;						--介面IO:SCL,如有接提升電阻時可設成inout
		  SDA:inout std_logic						--SDA輸入輸出
		);
end component ssd1306_i2c2wdriver4;
--TSL2561 driver
component TSL2561 is
	port	(CLK:in std_logic;
			RST:in std_logic;
			ena:in std_logic;
			act_done:buffer std_logic;
			light_ready:buffer std_logic;
			data_ch0:out std_logic_vector(15 downto 0);
			data_ch1:out std_logic_vector(15 downto 0);
			data_has_read:in std_logic;
			SCL:inout std_logic;
			SDA:inout std_logic
				);
end component TSL2561;
--SD178BMI_driver
component SD178BMI_driver is
	port	(CLK:in std_logic;
			RST:in std_logic;
			ena:in std_logic;
         data_in:in std_logic_vector(7 downto 0);
			data_out:out std_logic_vector(7 downto 0);
			trans_done:in std_logic;
         data_sended:out std_logic;
			act_done:out std_logic;
			SD_onoff:buffer std_logic;
			SCL:inout std_logic;
			SDA:inout std_logic
				);
end component SD178BMI_driver;
--divider
	signal Q:std_logic_vector(27 downto 0);
	signal Q1:std_logic_vector(27 downto 0);
	signal Q2:std_logic_vector(27 downto 0);
	signal Q3:std_logic_vector(27 downto 0);
    signal MAIN_CLK:std_logic;
	signal scan_clk:std_logic;
	signal ms_clk:std_logic;
	signal deb_clk:std_logic;
	signal clk_2sec:std_logic;
	signal clk_4sec:std_logic;
	signal clk_1sec:std_logic;
	signal blink_clk:std_logic;
--OLED
	--OLED=0:OLED初始化128x64
	signal OLED_init:integer range 0 to 63;
	signal OLED_inits:integer range 0 to 63;
	type OLED_T is array (0 to 38) of std_logic_vector(7 downto 0);
	signal OLED_RUNT:OLED_T;
	constant OLED_IT:OLED_T:=(	X"26",--0 指令長度
								X"AE",--1 display off
							
								X"D5",--2 設定除頻比及振盪頻率
								
								X"80",--3 [7:4]振盪頻率,[3:0]除頻比
								
								X"A8",--4 設COM N數
								X"3F",--5 1F:32COM(COM0~COM31 N=32),3F:64COM(COM0~COM31 N=64)
								
								X"40",--6 設開始顯示行:0(SEG0)
								
						X"E3",--X"A1",--7 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"C8",--8 掃瞄方向:COM0->COM(N-1) COM31,C8:COM(N-1) COM31->COM0
								
								X"DA",--9 設COM Pins配置
								X"12",--10 02:順配置(Disable COM L/R remap)
											--12:交錯配置(Disable COM L/R remap)
											--22:順配置(Enable COM L/R remap)
											--32:交錯配置(Enable COM L/R remap)
								
								X"81",--11 設對比
								X"EF",--12 越大越亮
								
								X"D9",--13 設預充電週期
								X"F1",--14 [7:4]PHASE2,[3:0]PHASE1
								
								X"DB",--15 設Vcomh值
								X"30",--16 00:0.65xVcc,20:0.77xVcc,30:0.83xVcc
								
								
								X"A4",--17 A4:由GDDRAM決定顯示內容,A5:全部亮(測試用)
								
								X"A6",--18 A6:正常顯示(1亮0不亮),A7反相顯示(0亮1不亮)
								
								X"D3",--19 設顯示偏移量Offset
								X"00",--20 00
								
						X"E3",--X"20",--21 設GDDRAM pointer模式
						X"E3",--X"02",--22 00:水平模式,  01:垂直模式,02:頁模式
								
								--頁模式column start address=[higher nibble,lower nibble] [00]
						X"E3",--X"00",--23 頁模式下設column start address(lower nibble):0
								
						X"E3",--X"10",--24 頁模式下設column start address(higher nibble):0
								
						X"E3",--X"B0",--25 頁模式下設Page start address
								
								X"20",--26 設GDDRAM pointer模式
								X"00",--27 00:水平模式,  01:垂直模式,02:頁模式
								
								X"21",--28 水平模式下設行範圍:
								X"00",--29 行開始位置0(Column start address)
								X"7F",--30 行結束位置127(Column end address)
								
								X"22",--31 水平模式下設頁範圍:
								X"00",--32 頁開始位置0(Page start address)
								X"07",--33 頁結束位置7(Page end address)
								
								X"A1",--34 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"8D",--35 設充電Pump
								X"14",--36 14:開啟,10:關閉
								
								X"AF",--37 display on
								X"E3" --38 nop
							);
	--OLED common signals
	signal OLED_I2CCLK:std_logic;
	signal OLED_RST:std_logic;
	signal OLED_CoDC:std_logic_vector(1 downto 0);
	signal OLED_load:std_logic;
	signal OLED_RWN:integer range 0 to 15;
	signal OLED_SA0:std_logic;
	signal OLED_reload:std_logic;
	signal OLED_I2Cok,OLED_I2CS:std_logic;
	signal OLED_data:std_logic_vector(7 downto 0);
	--OLED1 right
	signal OLED1_data:std_logic_vector(7 downto 0);
	--OLED2 left
	signal OLED2_data:std_logic_vector(7 downto 0);
	--OLED control
	signal OLED_c_RST:std_logic;
	signal OLED_c_ok:std_logic;
	signal dual_OLED_RST:std_logic_vector(1 downto 0);
	signal OLED_p_RST:std_logic;
	signal OLED_p_ok:std_logic;
	signal times:integer range 0 to 2047;		--停頓時間 當=0時觸發OLED動作(更新畫面)
	--OLED GDDRAM pointers
	signal GDDRAM_col_pointer:integer range 0 to 127;
	signal GDDRAM_page:integer range 0 to 15;
	--GDDRAM
	signal GDDRAMo,GDDRAMo1:std_logic_vector(7 downto 0);
	signal GDDRAM2o,GDDRAM2o1:std_logic_vector(7 downto 0);
--TSL2561
	type D7_T is array(0 to 3) of integer range 0 to 15;
	signal TSL_act:std_logic;
	signal TSL_done:std_logic;
	signal TSL_data_ready:std_logic;
	signal TSL_data_ch0:std_logic_vector(15 downto 0);
	signal TSL_data_ch1:std_logic_vector(15 downto 0);
	signal TSL_data_read:std_logic;
	signal LUXS,LUXS1,LUXS2,LUXS3,LUXS4:integer range 0 to 65535;	--16bit:0~2^16-1
	Signal LUX:D7_T:=(0,0,0,0);			--顯示資料
	--TSL2561 control signals
	signal TSL_open:std_logic;
	signal TSL_channel:std_logic;
	signal TSL_readed:std_logic;
--SD178BMI
	signal SD_ena:std_logic;
	signal SD_data:std_logic_vector(7 downto 0);
	signal SD_data_read:std_logic_vector(7 downto 0);
	signal SD_sended:std_logic;
	signal SD_done:std_logic;
	signal SD_onoff:std_logic;
	signal SD_stop:std_logic;
	--SD178BMI control signals
	signal SD_open:std_logic;
   signal SD_play:std_logic;
	signal SD_clr_buffer:std_logic;
	signal delay_done:std_logic;
	signal delay_en:std_logic;
	signal delay_count:integer range 0 to 31;
	signal startup_count:integer range 0 to 31;
	signal pointer:integer range 0 to 31;	--data pointer
	signal speed:integer range 0 to 63;
	signal volume:integer range 0 to 255;
	signal channel:std_logic_vector(1 downto 0);
	signal played:std_logic;
	--SD178BMI datas
	type change_set_type is array(0 to 1) of std_logic_vector(7 downto 0);
	signal change_speed:change_set_type;
	signal change_volume:change_set_type;
	signal change_channel:change_set_type;
	signal change_MO:change_set_type;
	signal MO:std_logic_vector(2 downto 0);
	type play_card_data is array(0 to 4) of std_logic_vector(7 downto 0);
	--(16進位) 88 檔名(2byte) 次數(2byte)
	constant play9998:play_card_data :=(X"88",X"27",X"0E",X"00",X"01");
	constant play5687:play_card_data :=(X"88",X"16",X"37",X"00",X"01");
	constant play1469:play_card_data :=(X"88",X"05",X"BD",X"00",X"01");
	signal play_music:play_card_data;
--KB scan & debounce
	signal SCAN_CODE:std_logic_vector(3 downto 0);	--按鍵座標
	signal PR_ZERO:std_logic_vector(2 downto 0);
	signal PR_ONE:std_logic_vector(2 downto 0);
	signal PRESS:std_logic;
	signal VALID:std_logic;	--0無效 1有效(除彈跳完畢)
	signal FREE:std_logic;	--按鍵狀態
	signal request:std_logic;
	signal operate_code:std_logic_vector(3 downto 0);
--7seg
	signal seg:std_logic_vector(3 downto 0);
	signal seg1_num:integer range 0 to 31;
	signal seg2_num:integer range 0 to 31;
--電路主訊號
	signal scan_mode:std_logic_vector(1 downto 0);	--OLED scan
	signal scan_done:std_logic;
	signal scan_en:std_logic;
	signal SD_LR:std_logic_vector(1 downto 0);
	signal sel_mode:std_logic_vector(2 downto 0);
	--顯示資料
	signal GDDRAM_LR:std_logic_vector(7 downto 0);
	signal GDDRAM_sdmode:std_logic_vector(7 downto 0);
	signal GDDRAM_blink:std_logic_vector(7 downto 0);
	signal GDDRAM_channels:std_logic_vector(7 downto 0);
	signal GDDRAM_scan:std_logic_vector(7 downto 0);
	signal GDDRAM_scan2:std_logic_vector(7 downto 0);
	signal GDDRAM_mark:std_logic_vector(7 downto 0);
	signal GDDRAM_number:std_logic_vector(7 downto 0);
	signal GDDRAM_volume:std_logic_vector(7 downto 0);
	signal GDDRAM_speed:std_logic_vector(7 downto 0);
	signal GDDRAM_lux:std_logic_vector(7 downto 0);
	signal GDDRAM_lux2:std_logic_vector(7 downto 0);
	signal GDDRAM_hor:std_logic_vector(7 downto 0);
	signal GDDRAM_ver:std_logic_vector(7 downto 0);
	signal GDDRAM_ver2:std_logic_vector(7 downto 0);
	signal hor_data:std_logic_vector(63 downto 0);
	
	signal OLED_enable:std_logic;
	signal TSL_enable:std_logic;
	signal SD_enable:std_logic;
	signal seg7_enable:std_logic;
	signal seg1_int:std_logic_vector(7 downto 0);
	signal seg2_int:std_logic_vector(7 downto 0);
	signal blink_en:std_logic;
	signal general_en:std_logic;
	signal message:std_logic_vector(3 downto 0);
	signal init_scan:std_logic;
	signal wav_select:integer range 0 to 7;
	signal play_times:integer range 0 to 15;
	signal played_times:integer range 0 to 15;
	signal seconds:integer range 0 to 255;
	signal rest_sec:integer range 0 to 255;
	signal per_volume:integer range 0 to 15;
	signal startstop:std_logic;
	signal pined:std_logic;
	signal sets:std_logic_vector(1 downto 0);
	signal stop_play:std_logic;
	signal data_switch:std_logic;
	signal data_switch_done:std_logic;
    signal times2:integer range 0 to 2047;
	type segs is array(0 to 3) of integer;
	signal seg_mark:segs;
	signal seg1_mark:segs;
	
	type TTS1 is array(0 to 15) of std_logic_vector(7 downto 0);
	constant start_voice:TTS1:=(X"A5",X"FA",X"B7",X"50",X"A7",X"55",X"AF",X"76",X"A8",X"74",X"B2",X"CE",X"B1",X"D2",X"B0",X"CA");
	constant sleep_voice:TTS1:=(X"A8",X"74",X"B2",X"CE",X"B6",X"69",X"A4",X"4A",X"BA",X"CE",X"AF",X"76",X"BC",X"D2",X"A6",X"A1");
	type TTS2 is array(0 to 13) of std_logic_vector(7 downto 0);--(4)~(7)為數值(ASCII)S
	signal light:TTS2:=(X"AB",X"47",X"AB",X"D7",X"31",X"39",X"39",X"39",X"B0",X"C7",X"A7",X"4A",X"B4",X"B5");
	type TTS3 is array(0 to 11) of std_logic_vector(7 downto 0);
	constant play_voice:TTS3:=(X"BC",X"BD",X"A9",X"F1",X"31",X"34",X"36",X"39",X"2E",X"77",X"61",X"76");
	constant cont_play:TTS3:=(X"A8",X"74",X"B2",X"CE",X"AB",X"F9",X"C4",X"F2",X"BC",X"BD",X"A9",X"F1");
	
	type image_128X24 is array(0 to 383) of std_logic_vector(7 downto 0);
	constant char_volume:image_128X24:=(
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"E0", X"00", X"00", X"40", X"40", X"40", X"40", X"40",
X"C0", X"40", X"40", X"40", X"A0", X"20", X"00", X"00", X"00", X"00", X"20", X"C0", X"00", X"00", X"00", X"00",
X"00", X"00", X"E0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"40", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"E0", X"A0",
X"A0", X"A0", X"A0", X"A0", X"A0", X"A0", X"A0", X"A0", X"A0", X"E0", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"82", X"42", X"FF", X"22", X"10", X"40", X"A5", X"A7", X"94", X"8C",
X"FF", X"8C", X"94", X"96", X"A5", X"44", X"00", X"00", X"01", X"01", X"FF", X"11", X"11", X"11", X"F1", X"20",
X"18", X"67", X"81", X"01", X"E1", X"1F", X"01", X"01", X"00", X"00", X"00", X"10", X"11", X"D1", X"53", X"55",
X"59", X"51", X"51", X"51", X"59", X"55", X"53", X"D1", X"11", X"10", X"00", X"00", X"08", X"08", X"EB", X"AA",
X"AA", X"AA", X"AA", X"EA", X"AA", X"AA", X"AA", X"AA", X"AA", X"EB", X"08", X"08", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"20", X"20", X"3F", X"00", X"00", X"00", X"3F", X"12", X"12", X"12",
X"1F", X"12", X"12", X"12", X"3F", X"00", X"00", X"00", X"30", X"0E", X"01", X"20", X"20", X"20", X"1F", X"20",
X"10", X"18", X"0F", X"06", X"09", X"10", X"10", X"20", X"00", X"00", X"00", X"00", X"00", X"3F", X"12", X"12",
X"12", X"12", X"12", X"12", X"12", X"12", X"12", X"3F", X"00", X"00", X"00", X"00", X"20", X"28", X"2B", X"2A",
X"2A", X"2A", X"2A", X"3F", X"2A", X"2A", X"2A", X"2A", X"2A", X"2B", X"28", X"20", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");
	constant char_speed:image_128X24:=(
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"E0", X"00", X"00", X"40", X"40", X"40", X"40", X"40", X"C0",
X"40", X"40", X"40", X"A0", X"20", X"00", X"00", X"00", X"00", X"20", X"C0", X"00", X"00", X"00", X"00", X"00",
X"00", X"E0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"20", X"40", X"80", X"00", X"00", X"80",
X"80", X"80", X"80", X"E0", X"80", X"80", X"80", X"80", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"40", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"82", X"42", X"FF", X"22", X"10", X"40", X"A5", X"A7", X"94", X"8C", X"FF",
X"8C", X"94", X"96", X"A5", X"44", X"00", X"00", X"01", X"01", X"FF", X"11", X"11", X"11", X"F1", X"20", X"18",
X"67", X"81", X"01", X"E1", X"1F", X"01", X"01", X"00", X"00", X"02", X"62", X"52", X"4A", X"C6", X"00", X"3C",
X"24", X"A4", X"64", X"FF", X"A4", X"24", X"24", X"3C", X"00", X"00", X"00", X"00", X"00", X"FF", X"01", X"09",
X"09", X"7D", X"49", X"49", X"49", X"49", X"49", X"7D", X"09", X"09", X"09", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"20", X"20", X"3F", X"00", X"00", X"00", X"3F", X"12", X"12", X"12", X"1F",
X"12", X"12", X"12", X"3F", X"00", X"00", X"00", X"30", X"0E", X"01", X"20", X"20", X"20", X"1F", X"20", X"10",
X"18", X"0F", X"06", X"09", X"10", X"10", X"20", X"00", X"00", X"40", X"20", X"18", X"0E", X"11", X"14", X"22",
X"23", X"21", X"20", X"2F", X"20", X"21", X"21", X"22", X"24", X"00", X"00", X"20", X"1C", X"23", X"20", X"21",
X"23", X"25", X"19", X"19", X"19", X"19", X"15", X"27", X"23", X"20", X"20", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");
	type image_128X64 is array(0 to 1023) of std_logic_vector(7 downto 0);
	type image_64X64 is array(0 to 511) of std_logic_vector(7 downto 0);
	constant channels:image_64X64:=(
	X"00", X"00", X"00", X"00", X"C0", X"40", X"40", X"40", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"30", X"43", X"86", X"84", X"88", X"78", X"00", X"00", X"02", X"7F", X"82", X"82", X"42",
X"00", X"00", X"7C", X"8A", X"8A", X"4A", X"0C", X"00", X"00", X"82", X"FE", X"82", X"02", X"02", X"00", X"00",
X"7C", X"8A", X"8A", X"4A", X"0C", X"00", X"38", X"44", X"82", X"82", X"82", X"7C", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"44", X"C6", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"80", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"FF", X"00", X"00", X"00", X"80", X"00", X"00", X"F8", X"14", X"14", X"94", X"18",
X"00", X"00", X"00", X"FF", X"04", X"00", X"00", X"00", X"00", X"04", X"FE", X"04", X"04", X"84", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"88", X"8C", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"01", X"01", X"01", X"01", X"01", X"01", X"00", X"00", X"00", X"01", X"01", X"00", X"00",
X"00", X"00", X"01", X"01", X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"01", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"FF", X"11", X"71", X"91", X"0E", X"00", X"00", X"00", X"09", X"F9", X"00", X"00",
X"00", X"00", X"F8", X"88", X"88", X"70", X"08", X"00", X"01", X"FF", X"08", X"08", X"08", X"F0", X"00", X"00",
X"08", X"FC", X"08", X"08", X"08", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"18", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"02", X"03", X"02", X"00", X"01", X"02", X"00", X"00", X"00", X"02", X"03", X"02", X"00",
X"00", X"06", X"05", X"05", X"05", X"06", X"06", X"00", X"02", X"03", X"00", X"00", X"02", X"03", X"00", X"00",
X"00", X"01", X"02", X"02", X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");
	type image_40X24 is array(0 to 119) of std_logic_vector(7 downto 0);
	constant volume_graph:image_40X24:=(
	X"00", X"00", X"00", X"C0", X"00", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"40", X"C0", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"07", X"1C", X"03", X"00", X"1E",
X"12", X"11", X"12", X"0C", X"00", X"00", X"1F", X"00", X"00", X"1E", X"10", X"10", X"1E", X"00", X"1E", X"01",
X"1E", X"11", X"1E", X"0E", X"16", X"15", X"16", X"04", X"00", X"00", X"32", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");
	type image_24X24 is array(0 to 71) of std_logic_vector(7 downto 0);
	constant circle:image_24X24:=(
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF", X"00", X"00", X"00", X"1C", X"22", X"41", X"41", X"41",
X"3E", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF");
	constant cross:image_24X24:=(
	X"00", X"00", X"00", X"00", X"00", X"80", X"00", X"00", X"80", X"80", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF", X"00", X"00", X"00", X"00", X"20", X"38", X"0B", X"06",
X"39", X"20", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"FF", X"FF", X"FF", X"FF", X"FF", X"FF");


	constant triangle:image_128X64:=(--LIN_SQ
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"01", X"FF", X"FF", X"41", X"41", X"41", X"22", X"1C", X"00", X"00", X"00", X"00",
X"03", X"FF", X"00", X"00", X"00", X"00", X"00", X"60", X"50", X"10", X"10", X"90", X"E0", X"00", X"00", X"10",
X"30", X"F0", X"00", X"00", X"D0", X"30", X"10", X"00", X"00", X"00", X"00", X"31", X"F3", X"00", X"00", X"00",
X"00", X"00", X"E0", X"20", X"10", X"10", X"10", X"E0", X"00", X"00", X"00", X"E0", X"10", X"10", X"10", X"20",
X"D0", X"30", X"00", X"00", X"00", X"00", X"20", X"60", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"10", X"1F", X"1F", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10",
X"10", X"1F", X"10", X"00", X"00", X"00", X"04", X"1E", X"11", X"11", X"11", X"08", X"1F", X"10", X"00", X"00",
X"40", X"41", X"7F", X"0E", X"01", X"00", X"00", X"00", X"00", X"00", X"10", X"18", X"1F", X"10", X"00", X"00",
X"00", X"10", X"1F", X"10", X"00", X"00", X"10", X"1F", X"10", X"00", X"20", X"7D", X"4A", X"4A", X"4A", X"4B",
X"51", X"30", X"00", X"00", X"00", X"00", X"18", X"18", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"40", X"C0", X"E0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"80", X"E0", X"00", X"00", X"00", X"00", X"00", X"C0", X"20", X"20", X"A0", X"C0", X"00", X"00", X"00", X"80",
X"E0", X"20", X"20", X"60", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"FF", X"FF", X"00", X"00", X"00", X"00", X"00", X"70", X"4C", X"43",
X"40", X"FF", X"40", X"40", X"00", X"00", X"7F", X"E9", X"04", X"04", X"04", X"F8", X"00", X"00", X"00", X"0F",
X"9C", X"10", X"10", X"10", X"FF", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"02", X"3E", X"C0", X"E2", X"3E", X"C0", X"FA", X"06", X"00", X"80", X"CC", X"2A", X"22", X"22", X"12", X"FC",
X"00", X"00", X"02", X"06", X"3E", X"E0", X"80", X"72", X"0E", X"02", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"02", X"03", X"03", X"02", X"00", X"00", X"00", X"00", X"00", X"00", X"02",
X"02", X"03", X"02", X"02", X"00", X"00", X"00", X"01", X"02", X"02", X"03", X"01", X"00", X"00", X"00", X"00",
X"01", X"02", X"02", X"01", X"00", X"00", X"00", X"00", X"03", X"03", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"03", X"00", X"00", X"03", X"00", X"00", X"00", X"00", X"03", X"02", X"02", X"02", X"01", X"03",
X"02", X"00", X"00", X"00", X"00", X"01", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");


	type image_96X32 is array(0 to 383) of std_logic_vector(7 downto 0);
type oled_num_tb is array (0 to 12,0 to 99) of std_logic_vector(7 downto 0);  --10個數值資料 + 2個英文字資料 + % 20X40(5 PAGE)
constant num_table:oled_num_tb:=
(
   ( --0 
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"E0", X"70", X"30", X"18", X"08", X"08", X"08", X"18",
   X"30", X"E0", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"FE", X"FF", X"07", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"1F", X"FF", X"F8", X"00", X"00", X"00", X"00", X"07", X"FF", X"FF",
   X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"E0", X"FF", X"7F", X"00", X"00", X"00",
   X"00", X"00", X"00", X"07", X"0F", X"1C", X"30", X"20", X"40", X"40", X"40", X"20", X"30", X"1E", X"0F", X"03",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"40", X"20", X"20", X"30", X"F0", X"F8", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"FF", X"FF", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"FF", X"FF", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"20", X"20", X"20", X"20", X"3F", X"3F", X"30", X"20", X"20", X"20", X"00", X"00",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"60", X"30", X"10", X"18", X"18", X"18", X"38", X"70",
   X"F0", X"E0", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"07", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"80", X"FF", X"7F", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"80", X"C0", X"70", X"18", X"0E", X"07", X"01", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"20", X"30", X"38", X"36", X"33", X"31", X"30", X"30", X"30", X"30", X"30", X"30", X"30", X"38",
   X"06", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"20", X"10", X"10", X"08", X"08", X"18", X"18",
   X"38", X"F0", X"E0", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"00", X"00", X"00", X"00",
   X"80", X"80", X"C0", X"C0", X"E0", X"98", X"0F", X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"01", X"00", X"00", X"00", X"01", X"03", X"07", X"1F", X"FE", X"F8", X"00", X"00", X"00",
   X"00", X"00", X"00", X"10", X"30", X"70", X"70", X"60", X"60", X"20", X"20", X"20", X"10", X"18", X"0C", X"03",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"E0",
   X"F8", X"F8", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"60", X"38",
   X"0C", X"07", X"01", X"FF", X"FF", X"FF", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"60", X"78", X"6C",
   X"67", X"61", X"60", X"60", X"60", X"60", X"60", X"FF", X"FF", X"FF", X"60", X"60", X"60", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"3F", X"3F", X"3F", X"00", X"00",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"70", X"30", X"30", X"30", X"30",
   X"30", X"30", X"38", X"18", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"20", X"18", X"1F", X"3B", X"38",
   X"38", X"78", X"70", X"F0", X"E0", X"C0", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"07", X"FF", X"FC", X"00", X"00", X"00", X"00",
   X"00", X"00", X"10", X"30", X"30", X"70", X"60", X"60", X"60", X"20", X"20", X"10", X"18", X"0C", X"03", X"00",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"C0", X"60", X"20", X"30", X"10",
   X"18", X"08", X"08", X"08", X"00", X"00", X"00", X"00", X"00", X"00", X"E0", X"F8", X"FE", X"CF", X"43", X"60",
   X"20", X"20", X"60", X"60", X"E0", X"C0", X"80", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"FF", X"FF",
   X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"1F", X"FF", X"FC", X"00", X"00", X"00",
   X"00", X"00", X"01", X"07", X"0E", X"18", X"30", X"20", X"20", X"20", X"20", X"20", X"20", X"18", X"0F", X"07",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"80", X"F0", X"30", X"30", X"10", X"10", X"10", X"10", X"10", X"10",
   X"10", X"10", X"D0", X"F0", X"10", X"00", X"00", X"00", X"00", X"00", X"01", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"F0", X"7E", X"0F", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"C0", X"F8", X"3F", X"07", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"20", X"3C", X"1F", X"03", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00" 
   ),
   
   (
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"60", X"10", X"10", X"08", X"08", X"08", X"08", X"18",
   X"10", X"70", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1F", X"3E", X"70", X"E0", X"C0",
   X"C0", X"80", X"C0", X"60", X"30", X"1C", X"0F", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"F0",
   X"38", X"0C", X"06", X"03", X"01", X"03", X"07", X"0F", X"0E", X"3C", X"F8", X"F0", X"C0", X"00", X"00", X"00",
   X"00", X"00", X"07", X"0F", X"1C", X"30", X"20", X"60", X"40", X"40", X"40", X"20", X"20", X"30", X"1C", X"0F",
   X"03", X"00", X"00", X"00"
   ),
   
   (--9
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"C0", X"E0", X"30", X"18", X"08", X"08", X"08", X"08",
   X"10", X"30", X"E0", X"C0", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"FF", X"FF", X"80", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"FF", X"FF", X"F0", X"00", X"00", X"00", X"00", X"00", X"01",
   X"03", X"07", X"0E", X"0C", X"08", X"08", X"08", X"08", X"08", X"C4", X"F4", X"7F", X"1F", X"01", X"00", X"00",
   X"00", X"00", X"00", X"00", X"40", X"40", X"60", X"20", X"30", X"18", X"18", X"0E", X"07", X"03", X"01", X"00",
   X"00", X"00", X"00", X"00" 
   ),

   (--L
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"01", X"03", X"FF", X"FF", X"01",
   X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"FF", X"FF", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"40", X"40", X"60", X"7F", X"7F", X"40", X"40", X"40", X"40", X"40", X"40", X"40", X"60", X"70",
   X"78", X"06", X"00", X"00" 
   ),
   
   (--X
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"02", X"02", X"06", X"1E", X"7E", X"F2", X"82",
   X"00", X"00", X"00", X"80", X"62", X"1E", X"0E", X"02", X"02", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"00", X"81", X"C7", X"3E", X"7C", X"E6", X"81", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
   X"00", X"80", X"C0", X"E0", X"F8", X"86", X"03", X"00", X"00", X"00", X"81", X"87", X"FE", X"F8", X"E0", X"80",
   X"80", X"00", X"00", X"00" 
   ),
	
	(--%
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
	X"00", X"00", X"00", X"00", X"00", X"00", X"F0", X"18", X"08", X"08", X"18", X"F0", X"00", X"00", X"80", X"40",
	X"30", X"08", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"03", X"02", X"C2", X"23", X"19",
	X"04", X"02", X"F9", X"8C", X"04", X"04", X"8C", X"F8", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
	X"01", X"00", X"00", X"00", X"00", X"00", X"00", X"01", X"01", X"01", X"01", X"00", X"00", X"00", X"00", X"00",
	X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
	X"00", X"00", X"00", X"00"
	)

);  
begin
	--SA0:
	--'0':OLED right
	--'1':OLED left
	U0:ssd1306_i2c2wdriver4 port map(OLED_I2CCLK ,OLED_RST ,OLED_SA0 ,OLED_CoDC ,OLED_data ,OLED_reload ,OLED_load ,3 ,OLED_I2Cok ,OLED_I2CS ,OLED_SCL ,OLED_SDA);
	U1:TSL2561 port map (CLK , RST , TSL_act , TSL_done , TSL_data_ready , TSL_data_ch0, TSL_data_ch1 , TSL_data_read ,  TSL_SCL , TSL_SDA);
	U2:SD178BMI_driver port map (CLK ,RST ,SD_ena ,SD_data ,SD_data_read ,SD_stop ,SD_sended ,SD_done ,SD_onoff ,SD_SCL , SD_SDA);
	
	divider:
	process(RST,CLK)
	begin
		if RST='0' then
			Q<=(others => '0');
			Q1<= (others => '0');
			Q2<= (others => '0');
			Q3<= (others => '0');
			clk_4sec<='1';
			clk_1sec<='1';
		elsif CLK'event and CLK='1' then
			Q<=Q+1;
			if Q1=50_000 then
				Q1<= (others => '0');
			else
				Q1<=Q1+1;
			end if;
			if Q2=100_000_000 then
				Q2<= (others => '0');
				clk_4sec<=not clk_4sec;
			else
				Q2<=Q2+1;
			end if;
			if Q3=25_000_000 then
				Q3<= (others => '0');
				clk_1sec<=not clk_1sec;
			else
				Q3<=Q3+1;
			end if;
		end if;
	end process divider;
	OLED_I2CCLK<=Q(3);	--OLED_Driver頻率
    MAIN_CLK<=Q(16);
	scan_clk<=Q(16);		--掃描頻率
	deb_clk<=Q(14);
	blink_clk<=Q(25);
	ms_clk<='1' when Q1>25_000 else '0';
	clk_2sec<='1' when Q2<50_000_000 else '0';
	
	process(startstop,clk_1sec)
	begin
		if (startstop='0' or pined='0') or DIP/="11" then
			if pined='0' then
				rest_sec<=seconds;
			end if;
			stop_play<='0';
		elsif rising_edge(clk_1sec) then
			if rest_sec>0 then
				rest_sec<=rest_sec-1;
				stop_play<='0';
			else
				stop_play<='1';
			end if;
		end if;
	end process;
	seconds<=	(10*conv_integer(DIP_sec(5 downto 3)) + conv_integer(DIP_sec(2 downto 0)));
	
	main:
	process(RST,CLK)
	begin
		if RST='0' then
			scan_en<='0';
			TSL_enable<='0';
			seg7_enable<='0';
			general_en<='0';
			OLED_enable<='0';
			SD_enable<='0';
            SD_play<='0';
			data_switch_done<='0';
			seg_mark<=(0,0,0,31);
			seg1_mark<=(0,0,0,31);
            times2<=381;
		elsif rising_edge(CLK) then
            times2<=times2-1;
			scan_en<='0';
			TSL_enable<='0';
			seg7_enable<='0';
			OLED_enable<='0';
			SD_enable<='0';
			if operate_code="0000" then
				general_en<='0';
			elsif operate_code="0100" or operate_code="0111" then
				general_en<='1';
			end if;
			case DIP is
				when "00"=> --OLED
					OLED_enable<='1';
					scan_en<=startstop;
				when "01"=> --TSL2561 7SEG
					TSL_enable<=startstop;
					seg7_enable<=general_en;
					OLED_enable<=general_en;
					if general_en='1' then
						if init_scan='0' then
							scan_en<='1';
						else
							scan_en<='0';
						end if;
					else
						scan_en<=init_scan;
					end if;
					seg_mark<=(LUX(0),10,11,12);
					if startstop='1' then
						if blink_en='1' and blink_clk='1'  then
							seg1_mark<=(13,LUX(2),LUX(1),LUX(0));
						else
							seg1_mark<=(0,LUX(2),LUX(1),LUX(0));
						end if;
					end if;
				when "10"=> --SD178BMI + OLED
					TSL_enable<=startstop;
					OLED_enable<=startstop;
					SD_enable<='1';
					play_music<=play1469; --WAV1
				when "11"=> --整合
					TSL_enable<=startstop;
					OLED_enable<=startstop;
					seg7_enable<=startstop;
					SD_enable<='1';
					if general_en='1' then
						if init_scan='0' then
							scan_en<='1';
						else
							scan_en<='0';
						end if;
					else
						scan_en<=init_scan;
					end if;
					seg_mark<=(LUX(0),10,11,12);
					if startstop='1' then
						if blink_en='1' and blink_clk='1'  then
							seg1_mark<=(13,LUX(2),LUX(1),LUX(0));
						else
							seg1_mark<=(0,LUX(2),LUX(1),LUX(0));
						end if;
					end if;
					play_music<=play1469;
			end case;
		end if;
	end process main;
	blink_en<=	'1' when LUXS<20 else
					'0';
	
	
	
	seg7_scan:
	process(RST,scan_clk)
	begin
		if RST='0' then
			seg<="0111";
		elsif rising_edge(scan_clk) then
			seg<=seg(0) & seg(3 downto 1);
		end if;
	end process;
	seg1_en<=seg;
	seg2_en<=seg;
	with seg select
	seg1_num<=	seg1_mark(3)	when "0111",
					seg1_mark(2)	when "1011",
					seg1_mark(1)	when "1101",
					seg1_mark(0)			when "1110",
					15			when others;
	with seg select
	seg2_num<=	seg_mark(3)			when "0111",
					seg_mark(2)			when "1011",
					seg_mark(1)			when "1101",
					seg_mark(0)			when "1110",
					15			when others;
	with seg1_num select --L
	seg1_int<=	"11111100"	when 0,
					"01100000"	when 1,
					"11011010"	when 2,
					"11110010"	when 3,
					"01100110"	when 4,
					"10110110"	when 5, --S
					"10111110"	when 6,
					"11100000"	when 7,
					"11111110"	when 8,
					"11110110"	when 9,
					"00011100"	when 10,--L
					"01111100"	when 11,--U
					"01101110"	when 12,--X
					
					"11111101"	when 13,
					"01100001"	when 14,
					"11011011"	when 15,
					"11110011"	when 16,
					"01100111"	when 17,
					"10110111"	when 18, --S
					"10111111"	when 19,
					"11100001"	when 20,
					"11111111"	when 21,
					"11110111"	when 22,
					"00011101"	when 23,--L
					"01111101"	when 24,--U
					"01101111"	when 25,--X
					"00000000"	when others;
	with seg2_num select --R
	seg2_int<=	"11111100"	when 0,
					"01100000"	when 1,
					"11011010"	when 2,
					"11110010"	when 3,
					"01100110"	when 4,
					"10110110"	when 5, --S
					"10111110"	when 6,
					"11100000"	when 7,
					"11111110"	when 8,
					"11110110"	when 9,
					"00011100"	when 10,--L
					"01111100"	when 11,--U
					"01101110"	when 12,--X
					
					"11111101"	when 13,
					"01100001"	when 14,
					"11011011"	when 15,
					"11110011"	when 16,
					"01100111"	when 17,
					"10110111"	when 18, --S
					"10111111"	when 19,
					"11100001"	when 20,
					"11111111"	when 21,
					"11110111"	when 22,
					"00011101"	when 23,--L
					"01111101"	when 24,--U
					"01101111"	when 25,--X
					"00000000"	when others;
	seg1s<=	"00000000" when init_scan='0' else
				seg1_int when seg7_enable='1' else
				"00000000";
	seg2s<=	"00000000" when init_scan='0' else
				seg2_int when seg7_enable='1' else
				"00000000";
	
	
	--SCAN_CODE:"0000"左上 "1111"右下
	--由上而下，由左至右
	KB_scan:--鍵盤電路
	process(deb_clk,RST)
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
		elsif rising_edge(deb_clk) then
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
				FREE<='0';
			else
				VALID<='0';
			end if;
			if PR_ONE="101" then
				FREE<='1';
				PR_ZERO<="000";
			end if;
		end if;
	end process;
	request<=VALID;
	
	process(RST,VALID)
	begin
		if RST='0' then
			--SD178BMI presetted settings
			change_speed<=(X"83",X"00");
			change_volume<=(X"86",X"D2");
			change_channel<=(X"8B",X"07");
			change_MO<=(X"8A","00000" & "000");
			speed<=40;
			volume<=210;
			per_volume<=5;
			channel<="10";
			wav_select<=1;
			pined<='0';
			startstop<='0';
			sets<="00";
			sel_mode<="001";
			SD_LR<="01";
			MO<="000";
		elsif rising_edge(VALID) then
			--依照按鍵選擇功能
			if stop_play='1' then
				startstop<='0';
			end if;
			operate_code<=SCAN_CODE;
			case SCAN_CODE is
				when "1111"=> --減速
					if speed/=0 then
						speed<=speed-10;
					end if;
				when "1110"=> --加速
					if speed/=40 then
						speed<=speed+10;
					end if;
				when "1101"=> --小聲
					if volume/=0 then --mute
						volume<=volume-25; -- 2=>-1dB
						per_volume<=per_volume-10;
					end if;
				when "1100"=> --大聲
					if volume/=250 then
						volume<=volume+25; -- 2=>+1dB
						per_volume<=per_volume+10;
					end if;
				when "1000"=> --更改聲道
					case channel is
						when "00"=>
							change_channel(1)<=X"05"; --L
						when "01"=>
							change_channel(1)<=X"06"; --R
						when "10"=>
							change_channel(1)<=X"07"; --LR
						when "11"=>
							change_channel(1)<=X"08"; --line out LR
					end case;
					channel<=channel+1;
					
					
				when "0100"=>--開始/停止
					startstop<=not startstop;
					sets<="10";
					if sets="00" then
						case DIP_sec(5 downto 4) is
							when "00"=> change_channel(1)<=X"01";
							when "01"=> change_channel(1)<=X"06";
							when "10"=> change_channel(1)<=X"05";
							when "11"=> change_channel(1)<=X"07";
						end case;
					end if;
				when "0010"=>--上
					if wav_select>1 then
						if pined='0' then
							wav_select<=wav_select-1;
						end if;
					end if;
					if per_volume<9 then
						per_volume<=per_volume+1;
					end if;
				when "0011"=>--下
					if wav_select<3 then
						if pined='0' then
							wav_select<=wav_select+1;
						end if;
					end if;
					if per_volume>0 then
						per_volume<=per_volume-1;
					end if;
				when "0111"=>--確認
					pined<='1';
					change_MO(1)<=("00000" & DIP_sec(5 downto 3));
					SD_LR<=DIP_sec(5 downto 4);
					case DIP_sec(5 downto 4) is
						when "00"=> change_channel(1)<=X"01";
						when "01"=> change_channel(1)<=X"06";
						when "10"=> change_channel(1)<=X"05";
						when "11"=> change_channel(1)<=X"07";
					end case;
					
					volume<=25*per_volume;
					startstop<='1';
					sets<="10";
				when "0000"=>--取消
					sets<="00";
					pined<='0';
					startstop<='0';
				when others=>
			end case;
			change_speed(1)<=conv_std_logic_vector(speed,8);
			change_volume(1)<=conv_std_logic_vector(volume,8);
		end if;
	end process;
	
	
	
	
--OLED
x1:block
	signal hor_counter:integer range 0 to 63;
	signal ver_counter:integer range 0 to 255;
	signal blink_cnt:integer range 0 to 7;
	signal blink_GDDRAM:std_logic_vector(7 downto 0);
	begin
	OLED_scanner:
	process(scan_clk)
	begin
		if RST='0' then
			OLED_c_RST<='0';	--重置控制
			OLED_inits<=1;		--initialize
			times<=200;			--停頓時間
			hor_counter<=0;
			ver_counter<=0;
			init_scan<='1';
			scan_mode<="00";
			blink_GDDRAM<="00000000";
			blink_cnt<=0;
		elsif scan_clk'event and scan_clk='1' then
			if OLED_c_ok='1' then	--控制完成
				OLED_inits<=conv_integer(OLED_RUNT(0))+1;	--初始化完成
				times<=times-1;
				if times=0 then	--觸發
					OLED_c_RST<='0';	--RESET 更新畫面
------------------------------------------main behave
					times<=1;
					if scan_en='1' then
						case scan_mode is
							when "00"=> --blink
								if blink_cnt=5 then
									scan_mode<=scan_mode+1;
									blink_cnt<=0;
									ver_counter<=0;
								else
									blink_cnt<=blink_cnt+1;
									blink_GDDRAM<=not blink_GDDRAM;
								end if;
								times<=190;
							when "01"=> --0~63
								if ver_counter=127 then
									scan_mode<=scan_mode+1;
									ver_counter<=127;
								else
									ver_counter<=ver_counter+1;
								end if;
							when "10"=> --64~127
								if ver_counter=0 then
									scan_mode<="00";
									ver_counter<=0;
								else
									ver_counter<=ver_counter-1;
								end if;
							when "11"=> --全亮
								if ver_counter=127 then
									scan_mode<=scan_mode+1;
									ver_counter<=0;
								else
									ver_counter<=ver_counter+1;
								end if;				
						end case;
					elsif general_en='0' then
						scan_mode<="00";
						blink_GDDRAM<="00000000";
						blink_cnt<=0;
						ver_counter<=0;
					end if;
------------------------------------------main behave
				end if;
			else
				OLED_c_RST<='1';		--啟用控制
			end if;
		end if;
	end process OLED_scanner;
	
--	G1:for i in 0 to 63 generate --(上至下)			右至左												範圍限制(右半邊)
--		hor_data(i)<=	'1' when i<hor_counter and 127-GDDRAM_col_pointer<hor_counter and GDDRAM_col_pointer>=64 else
--							'0';
--	end generate G1;
	G1:for i in 0 to 63 generate --(上至下)			右至左												範圍限制(右半邊)
		hor_data(i)<=	'1' when i>=ver_counter and ver_counter<=63 else
							'0';
	end generate G1;
	with GDDRAM_page select
	GDDRAM_hor<=	hor_data(7 downto 0)		when 0,
						hor_data(15 downto 8)	when 1,
						hor_data(23 downto 16)	when 2,
						hor_data(31 downto 24)	when 3,
						hor_data(39 downto 32)	when 4,
						hor_data(47 downto 40)	when 5,
						hor_data(55 downto 48)	when 6,
						hor_data(63 downto 56)	when 7,
						"00000000"	when others;
	GDDRAM_ver<=	"00000000"	when ver_counter = GDDRAM_col_pointer else
						"11111111";
	GDDRAM_ver2<=	"00000000"	when 127-ver_counter = GDDRAM_col_pointer else
						"11111111";
	with scan_mode select --left
	GDDRAM_scan<=	blink_GDDRAM	when "00", 
						GDDRAM_ver	when "01",
						GDDRAM_ver	when "10",
						"11111111"	when "11";
	with scan_mode select --right
	GDDRAM_scan2<=	blink_GDDRAM	when "00",
						GDDRAM_ver2	when "01",
						GDDRAM_ver2	when "10",
						"11111111"	when "11";
	
	GDDRAM_mark<=	not triangle(GDDRAM_col_pointer+128*GDDRAM_page);
					
--	GDDRAM_number<=	num_table(LUX(3),GDDRAM_col_pointer		+20*(GDDRAM_page-3))	when (GDDRAM_col_pointer<=20 and GDDRAM_page<=7 and GDDRAM_page>=3) else
--							num_table(LUX(2),GDDRAM_col_pointer-20	+20*(GDDRAM_page-3))	when (GDDRAM_col_pointer<=40 and GDDRAM_page<=7 and GDDRAM_page>=3) else
--							num_table(LUX(1),GDDRAM_col_pointer-40	+20*(GDDRAM_page-3))	when (GDDRAM_col_pointer<=60 and GDDRAM_page<=7 and GDDRAM_page>=3) else
--							num_table(LUX(0),GDDRAM_col_pointer-60	+20*(GDDRAM_page-3))	when (GDDRAM_col_pointer<=80 and GDDRAM_page<=7 and GDDRAM_page>=3) else
--							char_speed(GDDRAM_col_pointer+128*GDDRAM_page);--128X24
							
	GDDRAM_channels<=	channels(GDDRAM_col_pointer + 64*GDDRAM_page) when GDDRAM_col_pointer<=63 else
	
							circle(GDDRAM_col_pointer-64 +24*GDDRAM_page) when GDDRAM_col_pointer<=87 and GDDRAM_page<=2 and SD_LR="11" else
							cross(GDDRAM_col_pointer-64 +24*GDDRAM_page) when GDDRAM_col_pointer<=87 and GDDRAM_page<=2 else
							circle(GDDRAM_col_pointer-64 +24*(GDDRAM_page-3)) when GDDRAM_col_pointer<=87 and GDDRAM_page<=5 and SD_LR(1)='1' else
							cross(GDDRAM_col_pointer-64 +24*(GDDRAM_page-3)) when GDDRAM_col_pointer<=87 and GDDRAM_page<=5 else
							circle(GDDRAM_col_pointer-64 +24*(GDDRAM_page-6)) when GDDRAM_col_pointer<=87 and SD_LR(0)='1' else
							cross(GDDRAM_col_pointer-64 +24*(GDDRAM_page-6)) when GDDRAM_col_pointer<=87 else
							
							volume_graph(GDDRAM_col_pointer-88 + 40*GDDRAM_page) when GDDRAM_page<=2 else
							num_table(per_volume,GDDRAM_col_pointer-88 + 20*(GDDRAM_page-3)) when GDDRAM_col_pointer<=107 else
							"00000000";
	
	GDDRAM_blink<=	"00000000"	when blink_en='1' and blink_clk='0' else
						"11111111";
	GDDRAM_lux<=	GDDRAM_blink	when 127-LUXS<=GDDRAM_col_pointer else
						"00000000";
	GDDRAM_lux2<=	"00000000"	when LUXS<128 else
						GDDRAM_blink	when 255-LUXS<=GDDRAM_col_pointer else
						"00000000";
	
	with DIP select--R
	GDDRAMo1<=	GDDRAM_scan2	when "00",
					"11111111"	when "01",
					not GDDRAM_channels when "10",
					not GDDRAM_channels when "11",
					"00000000"	when others;
	with DIP select--L
	GDDRAM2o1<=	GDDRAM_scan	when "00",
					"11111111" when "01",
					GDDRAM_mark when "10",
					GDDRAM_mark when "11",
					"00000000"	when others;
	
	GDDRAMo<=	GDDRAM_scan when init_scan='0' else 
					GDDRAMo1	when OLED_enable='1' else
					"00000000";
	GDDRAM2o<=	GDDRAM_scan when init_scan='0' else 
					GDDRAM2o1	when OLED_enable='1' else
					"00000000";
	
	--OLED資料輸出設定
	OLED1_data<=OLED_RUNT(OLED_init) when OLED_CoDC="10" else GDDRAMo;
	OLED2_data<=OLED_RUNT(OLED_init) when OLED_CoDC="10" else GDDRAM2o;
	--送至driver的資料
	OLED_data<=OLED1_data when OLED_SA0='0' else OLED2_data;
	OLED_controller:
	process(CLK)
	begin
		if OLED_c_RST='0' then
			OLED_p_RST<='0';						--重置OLED_p
			OLED_c_ok<='0';						--尚未完成控制
			OLED_SA0<='0';							--從左OLED開始
			dual_OLED_RST<="00";
		elsif CLK'event and CLK='1' then
			if OLED_c_ok='0' then				--尚未完成控制
				if OLED_p_RST='1' then			--已啟動OLED_p
					if OLED_p_ok='1' then		--OLED_p完成動作
						if dual_OLED_RST="11" then
							OLED_c_ok<='1';			--控制完成
						else
							if OLED_SA0='0' then
								dual_OLED_RST(0)<='1';--標記完成
								OLED_p_RST<='0';		--再動作一次
							else
								dual_OLED_RST(1)<='1';--標記完成
							end if;
						end if;
						OLED_SA0<=not OLED_SA0;	--更換OLED
					end if;
				else
					OLED_p_RST<='1';				--啟動OLED_p
				end if;
			end if;
		end if;
	end process OLED_controller;
	
	OLED_p:
	process(OLED_p_RST,CLK)
		variable enable:boolean;
	begin
		if OLED_p_RST='0' then
			OLED_RST<='0';							--重置driver
			OLED_RUNT<=OLED_IT;					--初始化指令表
			OLED_init<=OLED_inits;				--指令起點 若初始化完成則不執行
			GDDRAM_col_pointer<=0;				--行指標歸0
			GDDRAM_page<=0;						--頁指標歸0
			OLED_p_ok<='0';						--動作尚未完成
			enable:=true;
			OLED_CoDC<="10";						--word mode,command
		elsif CLK'event and CLK='1' then
			OLED_load<='0';
			if OLED_RUNT(0)>=OLED_init then	--initialize
				if OLED_RST='0' then
					OLED_RST<='1';					--啟動Driver
				elsif enable=true then
					OLED_init<=OLED_init+1;
					enable:=false;
				elsif OLED_reload='0' then
					OLED_load<='1';
					enable:=true;
				end if;
			elsif OLED_CoDC="10" then			--初始化完成 切換
				OLED_CoDC<="01";					--byte mode,data
				enable:=true;
			elsif GDDRAM_page<=7 then			--refresh image
				if OLED_RST='0' then
					OLED_RST<='1';					--啟動Driver
					enable:=false;
				else
					if OLED_reload='0' then	--都可載入資料
						if enable then
							OLED_load<='1';		--load
							enable:=false;
						else
							GDDRAM_col_pointer<=GDDRAM_col_pointer+1;	--下一行
							if GDDRAM_col_pointer=127 then	--行結尾
								GDDRAM_page<=GDDRAM_page+1;	--換頁
							end if;
							enable:=true;
						end if;
					end if;
				end if;
			else
				OLED_p_ok<=OLED_I2Cok;	--動作完畢
			end if;
		end if;
	end process OLED_p;
end block x1;

--TSL2561
x2:block
	type KTC_T is array (0 to 7) of std_logic_vector(11 downto 0);
	constant KT_T_FN_CL:KTC_T:=(X"040",X"080",X"0c0",X"100",X"138",X"19a",X"29a",X"29a");
	constant BT_T_FN_CL:KTC_T:=(X"1f2",X"214",X"23f",X"270",X"16f",X"0d2",X"018",X"000");
	constant MT_T_FN_CL:KTC_T:=(X"1be",X"2d1",X"37b",X"3fe",X"1fc",X"0fb",X"012",X"000");
	constant CH_SCALE:integer:=10;
	constant LUX_SCALE:integer:=14;
	constant RATIO_SCALE:integer:=9;
	signal CH0:integer range 0 to 65535;	--16bit
	signal CH1:integer range 0 to 65535;	--16bit
	signal chScale0:std_logic_vector(15 downto 0);
	signal chScale1:std_logic_vector(19 downto 0);
	signal chScale:integer range 0 to 1048575;	--20bit
	signal channel0:integer range 0 to 67108863;	--26bit
	signal channel1:std_logic_vector(25 downto 0);
	signal ratio1:integer range 0 to 4095;	--12bit
	signal ratio:std_logic_vector(11 downto 0);
	signal KTC,BTC,MTC:KTC_T;
	signal BM:integer range 0 to 7;
	signal tempb,tempm,temp0,temp:integer range 0 to 520093695;	--32bit
	signal LUXDP:integer range 0 to 7;
	signal read_quested:std_logic;
begin
	TSL_control:
	process(RST,CLK)
	begin
		if RST='0' then
			TSL_act<='0';
			TSL_open<='0';
			TSL_channel<='0';
			TSL_readed<='0';
			read_quested<='0';
		elsif rising_edge(CLK) then
			if TSL_enable='1' then
				if TSL_open<='0' then
					TSL_readed<='0';
					TSL_act<='1';
				elsif DIP="01" and (SD_data_read(2)='1' or played='1') then
					TSL_act<='0';
				else
					if clk_1sec='1' then
						if TSL_readed='0' then
							if TSL_done='1' then
								if read_quested='0' then
									TSL_act<='1';
									read_quested<='1';
								else
									if TSL_channel='1' then
										TSL_readed<='1';
									end if;
									TSL_channel<=not TSL_channel;
									read_quested<='0';
								end if;
							end if;
						else
							TSL_act<='0';
						end if;
					else
						TSL_act<='0';
						TSL_channel<='0';
						TSL_readed<='0';
					end if;
				end if;
			end if;
			
			
			if TSL_done='0' then
				TSL_act<='0';
				TSL_open<='1';
			end if;
		end if;
	end process;
	
--Calculate LX(default settings)
	CH0<=conv_integer(TSL_data_ch0);
	CH1<=conv_integer(TSL_data_ch1);
	--integration 402ms
	chScale0<=X"0400";
	--gain 1X
	chScale1<=chScale0 & "0000";
	chScale<=conv_integer(chScale1);
	--channel = (ch * chScale) >> CH_SCALE
	channel0<=conv_integer(conv_std_logic_vector(CH0 * chScale ,36)(35 downto 10));
	channel1<=conv_std_logic_vector(CH1 * chScale ,36)(35 downto 10);
	--ratio = (channel1 << (RATIO_SCALE+1)) / channel0
	ratio1<=conv_integer(channel1 & "0000000000") / channel0 when channel0/=0 else 0;
	--ratio = (ratio1 + 1) >> 1
	ratio<=conv_std_logic_vector(ratio1+1 ,13)(12 downto 1);
	--type 0(T FN CL)
	KTC<=KT_T_FN_CL;
	BTC<=BT_T_FN_CL;
	MTC<=MT_T_FN_CL;
	BM<=	0 when ratio>=0 and ratio<=KTC(0) else
			1 when ratio<=KTC(1) else
			2 when ratio<=KTC(2) else
			3 when ratio<=KTC(3) else
			4 when ratio<=KTC(4) else
			5 when ratio<=KTC(5) else
			6 when ratio<=KTC(6) else
			7 ;
	tempb<=channel0*conv_integer(BTC(BM));						--channe0*b
	tempm<=conv_integer(channel1)*conv_integer(MTC(BM));	--channe1*m
	temp0<=0 when tempb<tempm else tempb-tempm;
	--temp += (1 << (LUX_SCALE-1))
	temp<=temp0 + 8192;
	--lux = temp >> LUX_SCALE
	LUXS<=conv_integer(CONV_STD_LOGIC_VECTOR(temp,33)(32 downto 14)) when sets/="00" else
			0;
	--LUXS<=conv_integer(TSL_data_ch1);
	LUXDP<=1 when LUXS<10000 else 5;
	--若LUXS<10000 則顯示到小數第一位
	--若LUXS>=10000 則顯示到個位數
LUXS1<=LUXS/10;
--		小數1位						  個位數
LUX(0)<=LUXS mod 10 when LUXDP=1 else LUXS1 mod 10;

LUXS2<=LUXS1/10;
--		個位數						  十位數
LUX(1)<=LUXS1 mod 10 when LUXDP=1 else LUXS2 mod 10;

LUXS3<=LUXS2/10;
--		十位數						  百位數
LUX(2)<=LUXS2 mod 10 when LUXDP=1 else LUXS3 mod 10;

LUXS4<=LUXS3/10;
--		百位數						  千位數
LUX(3)<=LUXS3 mod 10 when LUXDP=1 else LUXS4 mod 10;
end block x2;

--SD178BMI
x3:block
	signal cur_volume:integer range 0 to 255;
	signal cmd_volume:std_logic_vector(7 downto 0);
	signal dot5_temp:std_logic;
	signal ten_s_en:std_logic;
	signal cnt:integer range 0 to 1024;
	signal ten_s_cnt:integer range 0 to 15;
	signal ten_done:std_logic;
	signal reads:std_logic;
begin
	--延遲(30ms)
	delay:
	process(RST,ms_clk)
	begin
		if RST='0' then
			delay_count<=0;
			startup_count<=0;
			SD_open<='0';
			delay_done<='0';
			cnt<=0;
			ten_s_cnt<=0;
			ten_done<='0';
		elsif rising_edge(ms_clk) then
			if SD_onoff='1' then
				if startup_count=30 then
					SD_open<='1';
				else
					startup_count<=startup_count+1;
					SD_open<='0';
				end if;
				if delay_en='1' then
					if delay_count=30 then
						delay_done<='1';
					else
						delay_count<=delay_count+1;
						delay_done<='0';
					end if;
				else
					delay_count<=0;
					delay_done<='1';
				end if;
				if ten_s_en='1' then
					if cnt=1000 then
						if ten_s_cnt=10 then
							ten_done<='1';
						else
							ten_s_cnt<=ten_s_cnt+1;
							cnt<=0;
						end if;
					else
						cnt<=cnt+1;
						ten_done<='0';
					end if;
				else
					ten_s_cnt<=0;
					cnt<=0;
					ten_done<='0';
				end if;
			end if;
		end if;
	end process delay;
	
	process(RST,CLK)
	begin
		if RST='0' then
			SD_ena<='0';
			played<='0';
			data_switch<='0';
			ten_s_en<='0';
			message<="0000";
			delay_en<='0';
			played_times<=0;
			cmd_volume<=X"81";--大聲
			dot5_temp<='0';
			cur_volume<=volume;
			reads<='0';
		elsif rising_edge(CLK) then
			if SD_onoff='0' then		--如果尚未開機的話
				if request='1' then
					SD_ena<='1';
					delay_en<='1';
				else
					SD_ena<='0';
				end if;
			elsif SD_open='1' then	--開機並延遲完畢(30ms)
				if SD_enable='1' and init_scan='1' then
					if (clk_1sec='1') and played='0' and delay_done='1' then --request=1 而且 尚未播放 和 delay已完成(30ms)
						SD_ena<='1';	--讓SD開始動作
						delay_en<='1';	--開始計算延遲(30ms)
						played<='1';	--已經播放
					elsif clk_1sec='0' then --無要求則清空played
						played<='0';
					end if;
				else
					data_switch<='0';
				end if;
			end if;
			if delay_done='1' and played='1' then
				delay_en<='0';
			end if;
			
			--若開始動作則 SD_ena=0
			if SD_done='0' then
				SD_ena<='0';
				if played='1' then
					data_switch<='1';
				end if;
			else
				if data_switch='1' then
				--語音資料變更
					if (stop_play='1' or startstop='0') then--停止的話
						if message>="0011" then
							message<="0000";
						else
							message<=message+1;
							played<='0';
						end if;
					else
						if cur_volume/=volume then 
--							message<="0100";
--							dot5_temp<=not dot5_temp;
--							if cur_volume<volume then
--								cmd_volume<=X"81";--大聲
--								if dot5_temp='1' then
--									cur_volume<=cur_volume+1;
--								end if;
--							elsif cur_volume>volume then
--								cmd_volume<=X"82";--小聲
--								if dot5_temp='1' then
--									cur_volume<=cur_volume-1;
--								end if;
--							end if;
--							played<='0';
							cur_volume<=volume;
							message<="0000";
						else --非停止狀態
							case DIP is
								when "00"=> --不動作
									message<="0000";
								when "01"=> --不動作
									message<="0000";
								when "10"=> --播放音樂
									message<="0110";
								when "11"=> --播放XX秒的音樂
									if reads='1' then
										if SD_data_read(2)='0'  then
											reads<='0';
										end if;
									else
										reads<='1';
										if message="0111" then --start
											message<="1000"; --play voice
										elsif message="1000" then
											message<="0110"; --play music
											ten_s_en<='1'; --計算10秒
										elsif message="0110" then
											if ten_done='1' then
												ten_s_en<='0';
												message<="0000"; --stop
											else
												message<="0110"; --play music
											end if;
										elsif message="0000" then
											if blink_en='1' then
												message<="1011"; --sleep
											else
												message<="1010"; --continue
											end if;
										elsif message="1011" then
											if blink_en='1' then
												message<="0000"; --sleep stop
											else
												message<="0111"; --continue
											end if;
										elsif message="1010" then
											message<="0111";
										else
											message<="0111";
										end if;
									end if;
							end case;
						end if;
					end if;
				--語音資料變更
					data_switch<='0';
				end if;
			end if;
		end if;
	end process;
	--資料
	light(4)<=			X"20"													when LUX(3)=0 else
							conv_std_logic_vector((48+LUX(3)),8) 		when LUX(3)<10 else
							X"30";
	light(5)<=			X"20"													when LUX(2)=0 and LUX(3)=0 else
							conv_std_logic_vector((48+LUX(2)),8) 		when LUX(2)<10 else
							X"30";
	light(6)<=			X"20"													when LUX(1)=0 and LUX(2)=0 and LUX(3)=0 else
							conv_std_logic_vector((48+LUX(1)),8) 		when LUX(1)<10 else
							X"30";
	light(7)<=			X"30"													when LUX(0)=0 else
							conv_std_logic_vector((48+LUX(0)),8) 		when LUX(0)<10 else
							X"30";
	SD_data<=	X"41"						when reads='1' else
					X"80"						when message="0000" else
					change_speed(pointer)when message="0001" else
					change_volume(pointer) when message="0010" else
					change_channel(pointer) when message="0011" else
					cmd_volume	when message="0100" else
					X"41"						when message="0101" else --讀取
					play_music(pointer)			when message="0110" else
					start_voice(pointer)			when message="0111" else
					play_voice(pointer)			when message="1000" else
					light(pointer)					when message="1001" else
					cont_play(pointer)			when message="1010" else
					sleep_voice(pointer)			when message="1011" else
					"00000000"				;
	--資料指標控制
	process(SD_done,SD_sended)
		variable max_count:integer range 0 to 63;
	begin
		if SD_done='1' then
			pointer<=0;
			SD_stop<='0';
		elsif rising_edge(SD_sended) then
			if SD_open='1' then
					  case message is
							when "0000"=> max_count:=0;
							when "0001"=> max_count:=1;
							when "0010"=> max_count:=1;
							when "0011"=> max_count:=1;
							when "0100"=> max_count:=0;
							when "0101"=> max_count:=3; --read
							when "0110"=> max_count:=4;
							when "0111"=> max_count:=15;
							when "1000"=> max_count:=11;
							when "1001"=> max_count:=13;
							when "1010"=> max_count:=11;
							when "1011"=> max_count:=15;
							when others=> max_count:=0;
					  end case;
					  if reads='1' then
						max_count:=3;
					end if;
				if pointer < max_count then
					pointer<=pointer+1;
					SD_stop<='0';
				else
					SD_stop<='1';
				end if;
			end if;
		end if;
	end process;
end block x3;
end beh;