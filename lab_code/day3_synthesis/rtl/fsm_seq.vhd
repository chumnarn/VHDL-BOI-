-- fsm_seq.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — FSM 3 สถานะ (Moore)
-- จุดประสงค์: แสดงว่า enum type ของ state กลายเป็น register และ case ของ transition
--             กลายเป็น next-state logic
library ieee;
use ieee.std_logic_1164.all;

entity fsm_seq is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    din    : in  std_logic;
    state  : out std_logic_vector(1 downto 0)
  );
end entity fsm_seq;

architecture rtl of fsm_seq is
  type state_t is (IDLE, GOT1, DONE);
  signal cs, ns : state_t;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cs <= IDLE;
      else
        cs <= ns;
      end if;
    end if;
  end process;

  process (cs, din)
  begin
    case cs is
      when IDLE =>
        if din = '1' then
          ns <= GOT1;
        else
          ns <= IDLE;
        end if;
      when GOT1 =>
        if din = '0' then
          ns <= DONE;
        else
          ns <= GOT1;
        end if;
      when DONE =>
        ns <= IDLE;
    end case;
  end process;

  with cs select
    state <= "00" when IDLE,
            "01" when GOT1,
            "10" when DONE;
end architecture rtl;
