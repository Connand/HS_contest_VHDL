--TSL2561
--powerup:00000011
--address:GND(0101001) Float(0111001) VDD(1001001)
--
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SD178BMI_driver is
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
end SD178BMI_driver;

architecture control of SD178BMI_driver is
type states is	(idle, start, send_address, sending_data, check_ack, send_data, re_start, read_data, send_ack, stop);
signal state,prev_act:states;
type commands is array(0 to 3) of std_logic_vector(7 downto 0);
constant operations:commands:=(
X"80",	--select control register
X"03",	--power on command
X"AC",	--read light intensity	channel 0
X"AE"		--read light intensity	channel 1
);
--start stop condition
signal count:integer range 0 to 1;
signal count_en:std_logic;
--divider
signal Q:std_logic_vector(26 downto 0);
--200K and 100K
signal I2CCLK:std_logic;
signal SCLs:std_logic;
--internal SCL SDA
signal SCL_int,SDA_int:std_logic;
--data to write and read
signal data:std_logic_vector(7 downto 0);
signal data_read:std_logic_vector(7 downto 0);
--data_count to write or read
signal data_enable:std_logic;
signal data_count:integer range 0 to 8;
signal transaction_done:std_logic;
--acknowledge
signal ack_error:std_logic;
signal ack_done:std_logic;
--start or stop
signal shoud_stop:std_logic;
signal re_start_done:std_logic;
signal start_done:std_logic;
--command code done
signal cmd_done:std_logic;
signal data_ready:std_logic;
--TSL2561 datas
--狀態 0關機 1開機
signal device_onoff:std_logic;
--1read 0write
signal read_or_write:std_logic;
signal read_count:integer range 0 to 4;
begin
	divider:--200K
	process(RST,CLK)
	begin
		if RST='0' then
			Q<= (others => '0');
		elsif CLK'event and CLK='1' then
			if Q=250 then
				Q<= (others => '0');
			else
				Q<=Q+1;
			end if;
		end if;
	end process;
	I2CCLK<='1' when Q>125 else '0';
		
	SCL_CLK:--100K
	process(RST,I2CCLK)
	begin
		if RST='0' then
			SCLs<='0';
		elsif rising_edge(I2CCLK) then
			SCLs<=not SCLs;
		end if;
	end process;
	
	
	
	counter_controls:
	process(RST,I2CCLK)
	begin
		if RST='0' then
			data_count<=8;
			transaction_done<='0';
			start_done<='0';
			count<=0;
			act_done<='0';
		elsif falling_edge(I2CCLK) then
			if state=idle then
				act_done<='1';
			else
				act_done<='0';
			end if;
			if count_en='1' then
				if SCLs='1' then
					if count=1 then
						start_done<='1';
					end if;
				else
					count<=1;
					start_done<='0';
				end if;
			else
				count<=0;
				start_done<='0';
			end if;
			if data_enable='1' then
				if SCLs='0' then
					if data_count=0 then
						transaction_done<='1';
						data_count<=8;
					else
						transaction_done<='0';
						data_count<=data_count-1;
					end if;
				end if;
			else
				transaction_done<='0';
				data_count<=8;
			end if;
		end if;
	end process;
	
	SD_onoff<=device_onoff;
	I2C_FSM:
	process(RST,CLK)
	begin
		if RST='0' then
			data<="00000000";
			data_read<="11111111";
			state<=idle;
			SCL_int<='1';
			SDA_int<='1';
			device_onoff<='0';
			data_enable<='0';
			ack_error<='0';
			ack_done<='0';
			cmd_done<='0';
			read_or_write<='0';
			count_en<='0';
			shoud_stop<='0';
			data_ready<='0';
         data_sended<='0';
			read_count<=0;
		elsif rising_edge(CLK) then
			case state is
				when idle=>
					SCL_int<='1';
					SDA_int<='1';
					read_or_write<='0';
					ack_error<='0';
					data_ready<='0';
					data_enable<='0';
					data_sended<='0';
					if ena='1' then
						state<=start;
					end if;
					
				when start=>
					count_en<='1';
					case count is
						when 0=>
							SCL_int<='1';
							SDA_int<='1';
						when 1=>
							SDA_int<='0';
						when others=>
					end case;
					if start_done='1' then
						count_en<='0';
						state<=send_address;
					end if;
					
				when send_address=>
					data<="0100000" & read_or_write;
					if data_in=X"41" then
						read_or_write<='1'; --讀取
						read_count<=0;
					end if;
					if SCLs='1' then
						state<=sending_data;
					end if;
					
				when sending_data=>
					SCL_int<=SCLs;
					if SCLs='0' then
						data_enable<='1';
						SDA_int<=data(data_count);
					elsif transaction_done='1' then
						data_enable<='0';
						state<=check_ack;
					end if;
					
				when check_ack=>
					SCL_int<=SCLs;
					SDA_int<='1';
					if device_onoff='1' then
                    if trans_done = '0' then
                        data_sended<='0';
                    else
                        shoud_stop<='1';
                    end if;
					else
						shoud_stop<='1';
					end if;
					if SCLs='1' then
						if SDA='0' then
							ack_error<=ack_error or '0';
						else
							ack_error<='1';
							shoud_stop<='1';
						end if;
						ack_done<='1';
					elsif ack_done<='1' then
						ack_done<='0';
						if shoud_stop='0' then
							if read_or_write='0' then
								state<=send_data;
                     elsif read_or_write='1' then
								if re_start_done='0' then
									re_start_done<='1';
									state<=re_start;
								else
									state<=read_data;
								end if;
							end if;
						else	
							state<=stop;
						end if;
					end if;
					
				when send_data=>
					SCL_int<=SCLs;
					if data_ready='0' then
						if device_onoff='1' then
							--data ready
							data<=data_in;
							data_sended<='1';
							--change shoud_stop
							data_ready<='1';
						end if;
					else
						data_ready<='0';
						state<=sending_data;
					end if;
				when re_start=>
					SCL_int<=SCLs;
					count_en<='1';
					SDA_int<='1';
					if start_done='1' then
						count_en<='0';
						SDA_int<='0';
						state<=send_address;
					end if;
					
				when read_data=>
					SDA_int<='1';
					SCL_int<=SCLs;
					if SCLs='0' then
						data_enable<='1';
					elsif data_enable='1' then
						data_read(data_count)<=SDA;
					end if;
					if transaction_done='1' then
						data_enable<='0';
                  --change shoud_stop
						if read_count=4 then
							shoud_stop<='1';
						else
							shoud_stop<='0';
						end if;
						state<=send_ack;
					end if;
					
				when send_ack=>
					if shoud_stop='0' then
						SDA_int<='0';
					else
						SDA_int<='1';
					end if;
					SCL_int<=SCLs;
                    --save data
						if read_count=4 then
							data_out<=data_read;
						else
							data_out<="11111111";
						end if;
					if SCLs='1' then
						ack_done<='1';
					elsif ack_done='1' then
						ack_done<='0';
                        --pointer change
						read_count<=read_count+1;
						if shoud_stop='0' then
							state<=read_data;
						else
							state<=stop;
						end if;
					end if;
					
				when stop=>
					if SCLs='0' then
						count_en<='1';
					end if;
					SCL_int<=SCLs;
					case count is
						when 0=>
							SDA_int<='1';
						when 1=>
							SDA_int<='0';
					end case;
					if start_done='1' then
						count_en<='0';
						shoud_stop<='0';
						re_start_done<='0';
						SDA_int<='1';
						if data_in=X"89" then
							device_onoff<='0';
						else
							device_onoff<='1';
						end if;
						state<=idle;
					end if;
			end case;
		end if;
	end process;
	SDA<='Z' when SDA_int='1' else '0';
	SCL<='Z' when SCL_int='1' else '0';
	
	
	
	
end control;