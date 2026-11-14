# บทที่ 08: การคำนวณและ pipeline

> บทนี้ครอบคลุมการคำนวณที่ต้องระวังเรื่อง overflow และการเพิ่ม throughput
> ของ datapath ด้วยการทำ pipeline ซึ่งเป็นเทคนิคพื้นฐานที่สุดในงาน ASIC

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, `ghdl --synth`
**ตัวอย่างอ้างอิง:** `ex01_alu_comb/`, `ex05_pipeline_valid_ready/`, `ex09_mem_sync/`

---

## สารบัญบท

- [1. การคำนวณบน unsigned และ signed](#1-การคำนวณบน-unsigned-และ-signed)
- [2. overflow และวิธีตรวจจับ](#2-overflow-และวิธีตรวจจับ)
- [3. การขยายและตัดความยาว](#3-การขยายและตัดความยาว)
- [4. การเปรียบเทียบและเงื่อนไข](#4-การเปรียบเทียบและเงื่อนไข)
- [5. การหารและการเศษ](#5-การหารและการเศษ)
- [6. การเลื่อนและการหมุนบิต](#6-การเลื่อนและการหมุนบิต)
- [7. ตารางค้นหาและการแปลงค่า](#7-ตารางค้นหาและการแปลงค่า)
- [8. แนวคิดของ pipeline](#8-แนวคิดของ-pipeline)
- [9. การทำ pipeline ที่ถูกต้อง](#9-การทำ-pipeline-ที่ถูกต้อง)
- [10. pipeline กับข้อจำกัดของเวลา](#10-pipeline-กับข้อจำกัดของเวลา)

---

## 1. การคำนวณบน unsigned และ signed

### 1.1 ตารางเปรียบเทียบ

| หัวข้อ | `unsigned` | `signed` |
|---|---|---|
| ช่วงค่าของ N บิต | 0 ถึง 2^N − 1 | −2^(N−1) ถึง 2^(N−1) − 1 |
| บิต MSB | ไม่มีความหมายพิเศษ | เป็นเครื่องหมาย |
| การเปรียบเทียบ | เรียงตามค่าตัวเลข | เรียงตามค่าตัวเลขมีเครื่องหมาย |
| การขยาย (`resize`) | เติมบิต 0 ทางซ้าย | คงค่าเครื่องหมาย |

### 1.2 ตัวอย่าง

```vhdl
signal u8 : unsigned(7 downto 0) := x"FF";    -- 255
signal s8 : signed(7 downto 0)   := x"FF";    -- -1

u8 + 1   -- 255 + 1 = 256 แต่เกิดขอบเขต → 0 (ไม่มี error)
s8 + 1   -- -1 + 1 = 0
```

> **ข้อควรระวัง**: การบวกที่เกินขอบเขตของ `numeric_std` **ไม่มี error**
> ผลลัพธ์จะหมุนกลับ (wrap around) อย่างเงียบ ๆ
> ต้องขยายความยาวเองเสมอถ้าต้องการจับ carry หรือ overflow

### 1.3 การแปลงระหว่าง signed และ unsigned

```vhdl
-- unsigned → signed (ที่มีความยาวเท่ากัน)
signed(u)

-- signed → unsigned
unsigned(s)

-- ค่าบวกเสมอ
unsigned(signed(u))
```

> การแปลง `signed` ที่มีค่าติดลบเป็น `unsigned` จะได้ค่าที่มีความหมายเปลี่ยนไป
> ใช้ได้เฉพาะกรณีที่รู้ว่าค่าไม่เป็นลบ

## 2. overflow และวิธีตรวจจับ

### 2.1 overflow ของการบวก

overflow เกิดเมื่อผลลัพธ์อยู่นอกช่วงที่แทนได้

วิธีตรวจที่แม่นยำที่สุด — ขยายความยาวแล้วเทียบ

```vhdl
-- a, b เป็น signed N บิต
variable sum_ext_v : signed(N downto 0);
variable a_ext_v  : signed(N downto 0);
variable b_ext_v  : signed(N downto 0);

a_ext_v := a(N-1) & a;      -- ขยายโดยคงเครื่องหมาย
b_ext_v := b(N-1) & b;
sum_ext_v := a_ext_v + b_ext_v;

overflow <= sum_ext_v(N) /= sum_ext_v(N-1);   -- สองบิตเครื่องหมายไม่ตรงกัน
result  <= std_logic_vector(sum_ext_v(N-1 downto 0));
```

วิธีนี้ใช้ได้ทั้งกับบวกและลบ โดยถือว่า overflow ของการลบ
คือ overflow ของการบวกกับเครื่องหมายที่กลับกัน

### 2.2 วิธีตรวจจากบิตเครื่องหมาย (เร็วกว่า ใช้ได้เมื่อรู้ว่าไม่มี carry ที่ซับซ้อน)

สำหรับการบวกของเลขมีเครื่องหมาย:

```vhdl
overflow <= a(N-1) xor b(N-1) xor result(N-1);
```

ความหมาย: overflow เกิดเมื่อเครื่องหมายของผลลัพธ์ต่างจากเครื่องหมายของอินพุตทั้งสอง

### 2.3 carry

```vhdl
-- unsigned N บิต
variable sum_v : unsigned(N downto 0);
sum_v := ('0' & a) + ('0' & b);
carry <= sum_v(N);
result <= std_logic_vector(sum_v(N-1 downto 0));
```

### 2.4 ตารางสรุป

| ต้องการ | วิธี |
|---|---|
| carry ของการบวก unsigned | ขยาย 1 บิต แล้วดูบิตที่เพิ่ม |
| overflow ของการบวก signed | ขยาย 1 บิตแล้วเทียบเครื่องหมาย หรือใช้ XOR ของ 3 บิตเครื่องหมาย |
| borrow ของการลบ | `a < b` แล้ว `borrow = '1'` |
| overflow ของการลบ | ใช้วิธีเดียวกับการบวก โดยถือว่าค่าติดลบทำให้เครื่องหมายกลับกัน |

## 3. การขยายและตัดความยาว

```vhdl
-- ขยาย
resize(u, 16)      -- ผลลัพธ์ยาว 16 บิต
resize(s, 16)      -- ผลลัพธ์ยาว 16 บิต และคงเครื่องหมาย
```

| กรณี | `unsigned` | `signed` |
|---|---|---|
| ขยาย (ความยาวเพิ่ม) | เติม '0' ทางซ้าย | เติมบิตเครื่องหมายซ้ำ |
| ตัด (ความยาวลด) | ตัดบิตทิ้ง | ตัดบิตทิ้ง |

> **ความต่างที่ทำให้บั๊ก**: การขยาย `signed` ที่มีค่าติดลบจะเติม '1'
> ถ้าเขียน `resize(unsigned(s), 16)` จะเติม '0' ซึ่งเปลี่ยนค่าจาก -1 เป็น 32767

ตัวอย่างการใช้งาน

```vhdl
-- ขยาย signed ให้มีความยาวเท่ากันก่อนบวก
sum_v := resize(a, N+1) + resize(b, N+1);
```

## 4. การเปรียบเทียบและเงื่อนไข

```vhdl
-- เทียบกับค่าคงที่
if cnt = to_unsigned(0, cnt'length) then
if cnt > to_unsigned(100, cnt'length) then

-- เทียบกับค่าจากสัญญาณ (ต้องมีชนิดเดียวกัน)
if a > b then

-- เทียบแบบ unsigned กับ signed
if unsigned(a) > unsigned(b) then
```

### 4.1 การตรวจว่าค่าเป็นศูนย์

```vhdl
-- เร็ว
if cnt = (others => '0') then

-- ชัดเจนแต่ช้ากว่า
if to_integer(cnt) = 0 then
```

### 4.2 การตรวจว่าค่าเป็นหนึ่ง

```vhdl
if cnt = to_unsigned(1, cnt'length) then
```

## 5. การหารและการเศษ

```vhdl
quotient := a / b;      -- หารแบบ integer (ตัดทศนิยมทิ้ง)
remainder := a mod b;    -- เศษ
```

ข้อควรระวัง

- ตัวหารเป็นศูนย์จะทำให้เกิด error ระดับ runtime (ใน GHDL จะหยุดการจำลอง)
  ต้องป้องกันด้วย `if b /= 0 then` เมื่อตัวหารมาจากภายนอก
- การหารและโมดูลโดยจำนวนไม่คงที่ (เช่น หารด้วยรีจิสเตอร์)
  สังเคราะห์ได้แต่จะกินพื้นที่และเวลามาก ถ้าเป็นไปได้ควรเปลี่ยนเป็น
  การหารด้วยค่าคงที่ ซึ่งเครื่องมือจะ optimize เป็น shift และ multiply

## 6. การเลื่อนและการหมุนบิต

| ตัวดำเนินการ | ความหมาย | ใช้กับ |
|---|---|---|
| `u sll 1` | เลื่อนซ้ายเชิงตรรกะ เติม 0 ทางขวา | unsigned |
| `u srl 1` | เลื่อนขวาเชิงตรรกะ เติม 0 ทางซ้าย | unsigned |
| `u sla 1` | เลื่อนซ้ายเชิงเลขคณิต | signed |
| `u sra 1` | เลื่อนขวาเชิงเลขคณิต | signed |
| `u rol 1` | หมุนซ้าย บิตที่หลุดกลับเข้ามา | ทั้งสองแบบ |
| `u ror 1` | หมุนขวา | ทั้งสองแบบ |

ตัวอย่างการเลื่อนแบบตัวแปร (shift by variable)

```vhdl
if shamt = 0 then
  result := a;
elsif shamt >= WIDTH then
  result := (others => '0');
else
  result := a sll shamt;
end if;
```

> การเลื่อนด้วยจำนวนบิตที่มากกว่าความยาวข้อมูล จะให้ผลลัพธ์เป็นศูนย์
> แต่ถ้าจำนวนเป็นลบจะเกิด error — ให้ตรวจก่อนเสมอ

## 7. ตารางค้นหาและการแปลงค่า

### 7.1 ตารางค้นหาแบบ case

```vhdl
comb_p : process (sel, a)
begin
  case sel is
    when "00"   => y_o <= a;
    when "01"   => y_o <= not a;
    when "10"   => y_o <= a and "1010";
    when others => y_o <= (others => '0');
  end case;
end process comb_p;
```

เครื่องมือสังเคราะห์จะอนุมานเป็น multiplexer โดยอัตโนมัติ
ถ้าต้องการให้แน่ใจ ให้ใช้ `rom_style` attribute (ดูบทที่ 10)

### 7.2 การแปลง BCD เป็นเจ็ดส่วน

```vhdl
function bcd_to_7seg (bcd : std_logic_vector(3 downto 0)) return std_logic_vector is
begin
  case bcd is
    when "0000" => return "1111110";
    when "0001" => return "0110000";
    -- ...
    when others => return "0000000";
  end case;
end function bcd_to_7seg;
```

### 7.3 การแปลงเลขฐานสองเป็น BCD (double dabble)

การแปลงที่ถูกต้องต้องทำแบบ "double dabble" ไม่ใช่แค่คูณ
เพราะต้องจัดการกับการ carry ระหว่างทบ

## 8. แนวคิดของ pipeline

### 8.1 ปัญหา

วงจรคำนวณหนึ่งรอบนาฬิกาใช้เวลานาน ทำให้ความถี่สูงสุดถูกจำกัด

### 8.2 แนวทางแก้

แบ่งวงจรเป็นหลายชั้น โดยแต่ละชั้นทำงานได้ภายในเวลาเดียวกัน
และใส่ register ระหว่างชั้น

```text
  ข้อมูลเข้า ──► [ชั้น 1: ตัวคูณ] ──► [ชั้น 2: ตัวบวก] ──► [ชั้น 3: จัดรูปแบบ] ──► ข้อมูลออก
                     │                      │                        │
                   register               register                 register
```

ผลลัพธ์

- ความถี่สูงสุดเพิ่มขึ้นเท่ากับจำนวนชั้น
- latency เพิ่มขึ้น (ข้อมูลต้องรอผ่านทุกชั้น)
- ต้องจัดการเรื่อง back-pressure และ bubble ให้ถูกต้อง

### 8.3 ตัวอย่างเชิงปริมาณ

วงจรคำนวณ 8×8 multiplier + adder มี delay รวม 12 ns
ที่นาฬิกา 100 MHz (รอบ 10 ns) ทำไม่ได้

แบ่งเป็น 3 ชั้นชั้นละ 4 ns ก็ยังไม่พอ ต้องแบ่ง 4 ชั้นชั้นละ 3 ns
จึงจะรันที่ 100 MHz ได้ โดย latency เพิ่มขึ้น 3 รอบนาฬิกา

## 9. การทำ pipeline ที่ถูกต้อง

### 9.1 กฎที่ 1: ทุกชั้นต้องมี register

ชั้นที่ไม่มี register จะทำให้เส้นทางข้อมูลยังยาวเท่าเดิม
และยังมีความเสี่ยงที่ข้อมูลจะหลุดรอบ

### 9.2 กฎที่ 2: ชั้นถัดไปต้อง "พร้อมรับ" ก่อนชั้นปัจจุบันส่ง

นี่คือหัวใจของ back-pressure ที่ทำให้ข้อมูลหายหรือซ้ำ

```vhdl
-- ready ของชั้นถัดไป
ready_next <= not valid_pipe(i+1) or ready_out_of_next_stage;

-- เลื่อนข้อมูลเมื่อชั้นปัจจุบันมีข้อมูล และชั้นถัดไปพร้อมรับ
if valid_pipe(i) = '1' and ready_next = '1' then
  valid_pipe(i) <= valid_in;
  data_pipe(i)  <= data_in;
end if;
```

### 9.3 กฎที่ 3: bubble ต้องเดินท่อยังด้วย

เมื่อ `in_valid` เป็น 0 ต้องส่ง "ช่องว่าง" ลงไปในท่อ ไม่ใช่ปล่อยให้ข้อมูลเก่าค้าง

### 9.4 กฎที่ 4: reset ต้องล้างทุกชั้น

ถ้าล้างเฉพาะชั้นแรก ข้อมูลเก่าจะยังอยู่ในท่อและหลุดออกมาทางปลายทางหลัง reset

### 9.5 ตัวอย่างเต็ม

ตัวอย่างที่ผ่านการตรวจสอบอยู่ที่
`code/reference/vhdl/examples/ex05_pipeline_valid_ready/src/pipeline_valid_ready.vhd`

โครงสร้างของโมดูล

```vhdl
architecture rtl of pipeline_valid_ready is
  signal valid_pipe : std_logic_vector(STAGES-1 downto 0);
  signal data_pipe  : std_logic_vector(STAGES*DATA_WIDTH-1 downto 0);
  signal ready_pipe : std_logic_vector(STAGES downto 0);
begin
  -- ready ของแต่ละชั้นคำนวณย้อนจากปลายทาง
  ready_pipe(STAGES) <= out_ready;
  for i in STAGES-1 downto 0 loop
    ready_pipe(i) <= (not valid_pipe(i)) or ready_pipe(i+1);
  end loop;

  in_ready <= ready_pipe(0);

  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        valid_pipe <= (others => '0');
      else
        for i in 0 to STAGES-1 loop
          if i = 0 then
            if ready_pipe(0) = '1' then
              valid_pipe(0) <= in_valid;
              if in_valid = '1' then
                data_pipe(DATA_WIDTH-1 downto 0) <= in_data;
              end if;
            end if;
          else
            if ready_pipe(i) = '1' then
              valid_pipe(i) <= valid_pipe(i-1);
              data_pipe((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) <= data_pipe(i*DATA_WIDTH-1 downto (i-1)*DATA_WIDTH);
            end if;
          end if;
        end loop;
      end if;
    end if;
  end process seq_p;

  out_valid <= valid_pipe(STAGES-1);
  out_data  <= data_pipe(STAGES*DATA_WIDTH-1 downto (STAGES-1)*DATA_WIDTH);
end architecture rtl;
```

> **ข้อควรระวัง**: `for` loop ภายใน clocked process จะถูก unroll โดยเครื่องมือสังเคราะห์
> จึงสังเคราะห์ได้ แต่ต้องระวังเรื่อง index ของ slice ให้ถูกต้องทุกกรณี
> ถ้า `STAGES` มีค่ามาก ๆ โค้ดจะบววม ให้พิจารณาใช้ `generate` แทน

## 10. pipeline กับข้อจำกัดของเวลา

### 10.1 เวลาเผื่อ (slack)

แต่ละชั้นต้องมีเวลาเผื่อพอสำหรับ
- delay ของตรรกะที่สังเคราะห์ได้
- delay ของสายสัญญาณและ register
- uncertainty (ความไม่แน่นอนของนาฬิกาและ path)

### 10.2 ข้อจำกัดที่ต้องคำนึงถึง

- **register ที่ปิด timing ไม่ได้** เช่น การหารด้วยตัวแปร
- **สัญญาณควบคุมที่ไม่ได้ซิงก์** เช่น `en` ที่มาจาก clock อื่น
- **fan-out สูง** ซึ่งทำให้ buffer เพิ่มและ delay เพิ่ม
- **path ที่ยาวผิดปกติ** เช่น เส้นทาง carry ของ adder ยาวกว่าที่คาด

### 10.3 เทคนิคที่ใช้บ่อย

| เทคนิค | ผล |
|---|---|
| สร้าง carry-select adder | ลด delay ของเส้นทาง carry |
| แยก carry ออกเป็นสัญญาณเฉพาะ | ตัดเส้นทาง carry ออกจาก critical path |
| ใช้ dedicated adder/DSP cell ของ PDK | ได้ผลลัพธ์เร็วและประหยัดพื้นที่ |
| register duplication | เพิ่ม clock domain ที่ต้องวิเคราะห์ แต่ลด delay |

---

## แบบฝึกหัดท้ายบท

1. เขียนฟังก์ชัน `add_with_carry(a, b : unsigned) return ...` ที่คืนผลบวกและ carry
   พร้อม testbench ที่ตรวจทุกชุดค่าขอบเขต
2. เขียนตัวตรวจ overflow ของการบวก signed ด้วยวิธีขยายความยาว
   แล้วเทียบกับวิธี XOR ของสามบิตเครื่องหมาย ทดสอบด้วยค่าที่ทำให้เกิด overflow จริง
3. ทดลอง `resize(signed(x), 16)` กับ `resize(unsigned(signed(x)), 16)`
   แล้วอธิบายความต่างเมื่อ `x` เป็นค่าติดลบ
4. เพิ่มชั้นให้ `ex05_pipeline_valid_ready` จาก 3 เป็น 5 ชั้น
   แล้วตรวจว่าผลการจำลองยังถูกต้อง
5. อธิบายว่าเหตุใดการทำ pipeline ต้องใส่ register ทุกชั้น และถ้าไม่ใส่จะเกิดอะไรขึ้น

## คำถามท้ายบท

1. ทำไม `numeric_std` จึงไม่รายงาน overflow ของการบวก และต้องจัดการอย่างไร
2. ความต่างระหว่าง `resize` ของ `signed` กับ `unsigned` คืออะไร และมีผลต่อค่าติดลบอย่างไร
3. การขยายความยาวก่อนบวกหรือหักมีผลต่อ carry และ overflow อย่างไร
4. กฎสี่ข้อของการทำ pipeline คืออะไร และข้อใดที่ทำให้ข้อมูลหายหรือซ้ำ
5. การหารด้วยตัวแปรสังเคราะห์ได้หรือไม่ และมีข้อเสียอะไรเทียบกับการหารด้วยค่าคงที่

---

**อ่านต่อ:** [บทที่ 09 — โครงสร้างโค้ดของโปรเจกต์](09-code-organization.md)
