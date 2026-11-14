# บทที่ 07: สัญญาส่งข้อมูลและข้าม clock domain

> บทนี้ครอบคลุมสองเรื่องที่ทำให้วงจรทำงานผิดในระบบจริงบ่อยที่สุด
> คือการเชื่อมโมดูลเข้าด้วยกัน และการส่งสัญญาณข้าม clock domain

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0
**ตัวอย่างอ้างอิง:** `ex05_pipeline_valid_ready/`, `ex06_async_fifo/`, `ex07_cdc_sync/`, `ex12_cdc_handshake/`

---

## สารบัญบท

- [1. สัญญาของอินเทอร์เฟซ](#1-สัญญาของอินเทอร์เฟซ)
- [2. โปรโตคอล handshake ที่ใช้บ่อย](#2-โปรโตคอล-handshake-ที่ใช้บ่อย)
- [3. valid/ready กับ back-pressure](#3-validready-กับ-back-pressure)
- [4. เหตุใดการข้าม clock domain จึงอันตราย](#4-เหตุใดการข้าม-clock-domain-จึงอันตราย)
- [5. 2-flop synchronizer](#5-2-flop-synchronizer)
- [6. การซิงก์สัญญาณแต่ละชนิด](#6-การซิงก์สัญญาณแต่ละชนิด)
- [7. Gray code](#7-gray-code)
- [8. Asynchronous FIFO](#8-asynchronous-fifo)
- [9. การซิงก์ reset ข้าม domain](#9-การซิงก์-reset-ข้าม-domain)
- [10. ข้อผิดพลาดที่พบบ่อย](#10-ข้อผิดพลาดที่พบบ่อย)
- [11. การตรวจสอบ CDC](#11-การตรวจสอบ-cdc)

---

## 1. สัญญาของอินเทอร์เฟซ

เมื่อออกแบบโมดูลที่ต่อกับโมดูลอื่น ให้ระบุ 4 ข้อให้ชัดเจนเป็นลายลักษณ์อักษร

| ข้อ | ตัวอย่าง |
|---|---|
| **ทิศทางและความหมาย** | `valid` = "ข้อมูลนี้ใช้ได้", `ready` = "ผมรับได้" |
| **เวลา** | สัญญาณที่ valid เปลี่ยนจาก 0 เป็น 1 ต้องคงอยู่จนกว่า ready จะเป็น 1 |
| **เงื่อนไขการเลื่อนข้อมูล** | ข้อมูลเลื่อนเมื่อ `valid and ready` เป็น 1 ทั้งคู่ในรอบนาฬิกาเดียวกัน |
| **พฤติกรรมเมื่อผิดเงื่อนไข** | ถ้า `valid` เป็น 1 แต่ `ready` เป็น 0 ผู้ส่งต้องคงข้อมูลและ valid ไว้ |

การเขียนสัญญาให้ชัดเจนเป็นสิ่งที่ช่วยได้มากกว่าการอธิบายด้วยวาจา
เพราะเอกสารที่ไม่ชัดเจนจะทำให้แต่ละฝ่ายตีความต่างกันในที่สุด

## 2. โปรโตคอล handshake ที่ใช้บ่อย

### 2.1 ตารางเปรียบเทียบ

| โปรโตคอล | จำนวนสัญญาณ | เหมาะกับ | ข้อดี | ข้อเสีย |
|---|---|---|---|---|
| `valid` / `ready` | 2 (+ข้อมูล) | streaming ข้อมูลต่อเนื่อง | ทำงานได้เต็มอัตรา | ผู้รับต้องเตรียม buffer รับข้อมูลไว้ล่วงหน้า |
| `req` / `ack` (4-phase) | 2 (+ข้อมูล) | ส่งข้อมูลเป็นชิ้น ๆ ที่ต้องการการรับรอง | ปลอดภัยข้าม domain ได้ | ใช้ 4 รอบนาฬิกาต่อข้อมูลหนึ่งชิ้น |
| `req` / `ack` (2-phase) | 2 (+ข้อมูล) | ส่งข้อมูลเป็นชิ้น ๆ ความเร็วสูง | ใช้ 2 รอบนาฬิกา | ต้องระวังการรับซ้ำ |
| `pulse` | 1 | ส่งสัญญาณเหตุการณ์ | เรียบง่าย | ต้องมีวิธีป้องกันพัลส์หายเมื่อ domain ไม่พร้อมกัน |

## 3. valid/ready กับ back-pressure

### 3.1 กฎสามข้อ

1. `valid` และ `ready` เป็นอิสระต่อกัน ผู้ส่งและผู้รับตัดสินใจแยกกัน
2. ข้อมูลเลื่อนเมื่อ `valid and ready` เป็น 1 **ในรอบนาฬิกาเดียวกัน**
3. ถ้า `valid` เป็น 1 และ `ready` เป็น 0 ผู้ส่งต้อง**คงค่า `valid` และข้อมูลไว้**
   จนกว่า `ready` จะเป็น 1

### 3.2 เอาต์พุตของ pipeline

```vhdl
architecture rtl of pipeline_valid_ready is
  signal valid_pipe : std_logic_vector(STAGES-1 downto 0);
  signal data_pipe  : std_logic_vector(STAGES*DATA_WIDTH-1 downto 0);
begin
  -- in_ready เป็น 1 เมื่อ stage แรกว่าง
  in_ready <= not valid_pipe(0);

  -- เลื่อนข้อมูลเมื่อ stage ปัจจุบันมีข้อมูลและ stage ถัดไปรับได้
  ...
end architecture rtl;
```

กฎการเลื่อนข้อมูลในแต่ละ stage

```vhdl
-- stage ถัดไปรับได้ = (stage ถัดไปว่าง) or (stage ปัจจุบันถูกระบายออก)
-- stage ปัจจุบันถูกระบายออก = valid(ปัจจุบัน) and ready(ถัดไป)
```

รายละเอียดของการคำนวณนี้อยู่ในตัวอย่าง
`code/reference/vhdl/examples/ex05_pipeline_valid_ready/src/pipeline_valid_ready.vhd`

### 3.3 ปัญหาที่พบบ่อย

| ปัญหา | อาการ | วิธีแก้ |
|---|---|---|
| ผู้ส่งเปลี่ยนข้อมูลทันทีเมื่อ `valid` เป็น 1 | ข้อมูลหายเมื่อ `ready` เป็น 0 | ล็อกข้อมูลไว้จนกว่า `valid and ready` |
| ใช้ `valid` เป็นเงื่อนไขในการเลื่อนข้อมูลเท่านั้น | ข้อมูลซ้ำเมื่อ `ready` ค้าง 0 | เลื่อนเมื่อ `valid and ready` เท่านั้น |
| `ready` ขึ้นกับ `valid` ในทางเดียว | เกิด deadlock เมื่อทั้งสองฝั่งรอกัน | ตรวจว่าไม่มี circular dependency |

## 4. เหตุใดการข้าม clock domain จึงอันตราย

เมื่อสัญญาณเปลี่ยนจาก 0 เป็น 1 ช่วงที่ไม่ตรงกับขอบนาฬิกาของอีกฝั่ง
วงจร flip-flop อาจเข้าสู่สถาะ **metastability** — สถานะที่เอาต์พุตไม่แน่นอน
เป็น 0 หรือ 1 อย่างใดอย่างหนึ่งในช่วงเวลาที่ไม่กำหนด

ประมาณการ MTBF (Mean Time Between Failures) ลดลงแบบเอกซ์โพเนนเชียล
เมื่อเวลาที่สัญญาณไม่นิ่งใกล้ขอบนาฬิกายาวขึ้น

**ข้อสรุป: ห้ามส่งสัญญาณจาก domain หนึ่งไปยังอีก domain หนึ่งโดยตรงเด็ดขาด**
ต้องผ่านกลไกซิงก์เสมอ

## 5. 2-flop synchronizer

```vhdl
architecture rtl of sync_ff2 is
  signal sync_meta_i : std_logic;
  signal sync_out_i  : std_logic;
begin
  -- flip-flop ตัวแรก: เป็นจุดที่ metastability มีโอกาสเกิด
  -- flip-flop ตัวที่สอง: ให้เวลาสถานะที่ไม่นิ่งกลับมานิ่ง
  sync_meta_i <= async_in;
  sync_out_i  <= sync_meta_i;

  sync_out <= sync_out_i;
end architecture rtl;
```

### 5.1 เหตุผลที่ต้องมี 2 ฟลิปฟลอป

- ฟลิปฟลอปตัวแรกมีโอกาสเข้าสู่ metastability
- เมื่อ metastability สลายตัว (ภายในระยะเวลาสั้น ๆ) ฟลิปฟลอปตัวที่สอง
  จะจับค่าที่นิ่งแล้วไปใช้
- ฟลิปฟลอปตัวที่สองจึงต้องมี **เวลาครึ่งรอบนาฬิกาที่เผื่อไว้เพิ่ม**
  เพื่อให้ metastability สลายตัวทัน

### 5.2 attribute ที่ควรใส่

```vhdl
  attribute async_reg : string;
  attribute async_reg of sync_meta_i : signal is "TRUE";
  attribute async_reg of sync_out_i  : signal is "TRUE";
```

เครื่องมือสังเคราะห์หลายตัวใช้ attribute นี้เพื่อ
1. วางฟลิปฟลอปทั้งสองตัวให้อยู่ใกล้กัน (ลด delay และความเสี่ยงที่จะถูกวางคนละชั้น)
2. ป้องกันไม่ให้เครื่องมือย้ายหรือรวมฟลิปฟลอปทั้งสองเข้าด้วยกัน

### 5.3 ข้อจำกัด

**2-flop synchronizer ใช้ได้เฉพาะกับสัญญาณระดับ (level) ที่คงอยู่นานพอ**
ถ้าสัญญาณเป็นพัลส์ที่สั้นกว่าครึ่งรอบนาฬิกาของปลายทาง
ฟลิปฟลอปตัวแรกอาจจับไม่ทัน พัลส์จะหายไป
ต้องใช้กลไกอื่นตามหัวข้อ 6

## 6. การซิงก์สัญญาณแต่ละชนิด

### 6.1 สัญญาณระดับ (level)

```vhdl
sync_meta_i <= async_in;
sync_out_i  <= sync_meta_i;
```

เหมาะกับ: สถานะที่คงอยู่จนกว่าจะเปลี่ยน เช่น `busy`, `empty`, `full`

### 6.2 สัญญาณพัลส์ (pulse) — กลไก toggle

```vhdl
architecture rtl of sync_pulse is
  signal toggle_src_i : std_logic := '0';
  signal toggle_dst_i : std_logic;
  signal toggle_dst_m : std_logic;
  signal pulse_dst_i  : std_logic := '0';
begin
  -- ฝั่งต้นทาง: สลับค่า toggle เมื่อมีพัลส์
  seq_src_p : process (src_clk)
  begin
    if rising_edge(src_clk) then
      if src_rst_n = '0' then
        toggle_src_i <= '0';
      elsif pulse_in = '1' then
        toggle_src_i <= not toggle_src_i;
      end if;
    end if;
  end process seq_src_p;

  -- ฝั่งปลายทาง: ซิงก์ toggle แล้วตรวจการเปลี่ยนแปลง
  toggle_dst_m <= toggle_src_i;
  toggle_dst_i <= toggle_dst_m;

  seq_dst_p : process (dst_clk)
    variable toggle_prev_v : std_logic := '0';
  begin
    if rising_edge(dst_clk) then
      if dst_rst_n = '0' then
        pulse_dst_i <= '0';
        toggle_prev_v := '0';
      else
        pulse_dst_i <= '0';
        if toggle_dst_i /= toggle_prev_v then
          pulse_dst_i <= '1';       -- ตรวจพบการเปลี่ยนแปลง → มีพัลส์มา
        end if;
        toggle_prev_v := toggle_dst_i;
      end if;
    end if;
  end process seq_dst_p;

  pulse_out <= pulse_dst_i;
end architecture rtl;
```

**ข้อจำกัดที่ต้องรู้**: กลไกนี้รับรองพัลส์ได้ไม่เกินหนึ่งพัลส์ในช่วงเวลาที่ปลายทางรอ
ถ้าต้นทางยิงพัลส์ถี่กว่านั้น พัลส์จะหาย ต้องใช้ handshake แบบ 4-phase แทน

### 6.3 ส่งข้อมูล (data) — handshake 4-phase

เมื่อต้องส่งข้อมูลหลายบิตข้าม domain ต้องไม่ใช้ 2-flop synchronizer กับบิตข้อมูลแต่ละบิต
เพราะ (1) แต่ละบิตอาจถูกซิงก์ไม่พร้อมกัน ทำให้ค่าที่ได้เป็นข้อมูลที่ไม่เคยถูกส่ง
และ (2) ใช้ทรัพยากรมาก

ทางเลือกที่ปลอดภัยคือ **ล็อกข้อมูลแล้วใช้ handshake ยืนยันการรับ**

```vhdl
-- ฝั่งต้นทาง
seq_src_p : process (src_clk)
begin
  if rising_edge(src_clk) then
    if src_rst_n = '0' then
      req_i  <= '0';
      data_i <= (others => '0');
    elsif src_valid = '1' and req_i = '0' and ack_sync_i = '0' then
      -- ยก req พร้อมล็อกข้อมูล
      -- ต้องรอให้ ack กลับเป็น 0 ก่อน คือ handshake ของคำก่อนหน้าต้องจบครบสี่รอบ
      req_i  <= '1';
      data_i <= src_data;
    elsif req_i = '1' and ack_sync_i = '1' then
      req_i <= '0';                  -- ปลด req เมื่อได้รับ ack
    end if;
  end if;
end process seq_src_p;

-- ฝั่งปลายทาง: ซิงก์ req ด้วย 2-flop แล้วตอบ ack
ack_sync_m <= req_sync_i;
ack_sync_i <= ack_sync_m;
```

กฎ: **ข้อมูลต้องถูกล็อกก่อนยก req** และ **ต้องรอ ack กลับมาก่อนปลด req**
เท่านั้นข้อมูลจึงมีเวลามากพอที่จะซิงก์ได้อย่างปลอดภัย

> **ข้อควรระวังที่พบจริงในการเขียนโค้ด:** `ack` เป็นสัญญาณ **ระดับ** ไม่ใช่พัลส์
> ถ้าเงื่อนไขรับข้อมูลใหม่ตรวจแค่ `req_i = '0'` โดยไม่รอ `ack_sync_i = '0'`
> ฝั่งผู้ส่งจะเริ่มส่งคำใหม่ได้ทันทีที่ `ack` ยังเป็น 1 อยู่
> handshake จะไม่ครบทั้งสี่รอบ และข้อมูลจะถูกส่งรัวหรือหาย
> ตัวอย่างที่ถูกต้องและผ่านการจำลองแล้วอยู่ที่
> `code/reference/vhdl/examples/ex12_cdc_handshake/src/cdc_handshake.vhd`

### 6.3.1 ลำดับสี่รอบของ handshake

| รอบ | ฝั่งผู้ส่ง | ฝั่งผู้รับ | สถานะข้อมูล |
|---|---|---|---|
| 1 | ล็อกข้อมูล แล้วยก `req` เป็น 1 | รอ `req` ที่ซิงก์เข้ามาเป็น 1 | ข้อมูลถูกล็อกและนิ่ง |
| 2 | รอ `ack` ที่ซิงก์เข้ามาเป็น 1 | อ่านข้อมูล ตั้ง `ack` เป็น 1 | ข้อมูลถูกส่งถึงปลายทางแล้ว |
| 3 | ปลด `req` กลับเป็น 0 | รอ `req` ที่ซิงก์เข้ามาเป็น 0 | ข้อมูลยังนิ่งอยู่ |
| 4 | รอ `ack` ที่ซิงก์เข้ามาเป็น 0 | ปลด `ack` กลับเป็น 0 | พร้อมรับคำถัดไป |

เงื่อนไขที่ฝั่งผู้ส่งใช้รับข้อมูลใหม่ต้องเป็น `req = '0'` **และ** `ack = '0'` เสมอ
จึงจะรับประกันว่ารอบที่ 4 ของคำก่อนหน้าเสร็จสมบูรณ์ก่อนเริ่มคำใหม่

### 6.4 ตารางเลือกกลไก

| สิ่งที่ส่ง | กลไกที่เหมาะสม | เหตุผล |
|---|---|---|
| สัญญาณระดับ (busy, empty) | 2-flop synchronizer | คงอยู่นานพอ |
| พัลส์เหตุการณ์ | toggle + 2-flop | รับพัลส์ได้แม้สั้น |
| ข้อมูลหลายบิต | handshake 4-phase | ป้องกันข้อมูลถูกซิงก์ไม่พร้อมกัน |
| สตรีมข้อมูลปริมาณมาก | asynchronous FIFO + Gray code | รองรับ throughput สูงสุด |
| ตัวนับ/พอร์ตที่เพิ่มทีละ 1 | Gray code + 2-flop | ไม่มีบิตใดเปลี่ยนมากกว่า 1 บิตในเวลาเดียว |

## 7. Gray code

### 7.1 คุณสมบัติ

Gray code คือการเข้ารหัสตัวเลขโดยที่ **เมื่อค่าเปลี่ยนทีละ 1 จะมีบิตที่เปลี่ยนเพียง 1 บิต**
ทำให้เมื่อส่งข้าม clock domain จะไม่มีบิตใดที่ "ตามหลัง" บิตอื่น
จึงไม่เกิดค่าที่ไม่มีอยู่จริง (glitch) ในช่วงที่ซิงก์

ตารางแปลง 4 บิต

| Decimal | Binary | Gray |
|---|---|---|
| 0 | 0000 | 0000 |
| 1 | 0001 | 0001 |
| 2 | 0010 | 0011 |
| 3 | 0011 | 0010 |
| 4 | 0100 | 0110 |
| 5 | 0101 | 0111 |
| 6 | 0110 | 0101 |
| 7 | 0111 | 0100 |

สูตร: `gray = binary xor (binary >> 1)`

### 7.2 ฟังก์ชันแปลงใน VHDL

```vhdl
package gray_pkg is
  function binary_to_gray (b : unsigned) return unsigned;
  function gray_to_binary (g : unsigned) return unsigned;
end package gray_pkg;

package body gray_pkg is
  function binary_to_gray (b : unsigned) return unsigned is
  begin
    return b xor (b srl 1);
  end function binary_to_gray;

  function gray_to_binary (g : unsigned) return unsigned is
    variable b_v : unsigned(g'range);
  begin
    b_v := g;
    for i in g'range loop
      if i = g'left then
        null;                        -- บิต MSB เท่ากับ Gray MSB
      else
        b_v(i) := b_v(i) xor b_v(i+1);
      end if;
    end loop;
    return b_v;
  end function gray_to_binary;
end package body gray_pkg;
```

> ข้อควรระวัง: การวน loop ใน function ที่ใช้กับ signal ให้ผลลัพธ์ที่สังเคราะห์ได้
> เพราะเป็นการคำนวณแบบ combinational แต่ต้องระวังว่าเครื่องมือจะ unroll loop
> ให้เป็น logic จริง สำหรับ pointer ขนาดใหญ่ควรใช้สูตรแบบ bitwise ที่สังเคราะห์ได้โดยตรง

## 8. Asynchronous FIFO

### 8.1 แนวคิด

ใช้เมื่อต้องส่งข้อมูลจาก domain หนึ่งไปอีก domain หนึ่งโดยไม่ทำให้ throughput ลดลงมาก
ข้อมูลถูกเก็บใน memory ที่เขียนจากฝั่งต้นทางและอ่านจากฝั่งปลายทาง

### 8.2 โครงสร้าง

```text
  write domain                          read domain
  ┌──────────────────┐                  ┌──────────────────┐
  │ wr_ptr (binary)  │                  │ rd_ptr (binary)  │
  │      │           │                  │      │           │
  │      ▼           │   2-flop sync    │      ▼           │
  │ wr_ptr_gray ─────┼─────►──────┐     │ rd_ptr_gray ─────┼─────►──────┐
  │                  │            │     │                  │            │
  │ full  ◄──────────┼────────────┘     │ empty ◄──────────┼────────────┘
  │                  │                  │                  │
  │            ┌─────┴──────┐           │            ┌─────┴──────┐     │
  │            │    memory  │◄──────────┼────────────│    memory  │     │
  │            └────────────┘           │            └────────────┘     │
  └──────────────────┘                  └──────────────────┘
```

### 8.3 การคำนวณ full และ empty

ให้ `PTR_WIDTH = ADDR_WIDTH + 1` (เพิ่ม 1 บิตเพื่อแยก "เต็ม" กับ "ว่าง")

```vhdl
-- ฝั่งเขียน: full เมื่อ pointer ถัดไปของ write เท่ากับ read ที่ซิงก์แล้ว
-- โดยเทียบ bit ถัดไป (MSB) ซึ่งบอกว่าต่างกันกี่รอบ
full_i <= '1' when wr_ptr_gray_next =
                   (rd_ptr_gray_sync or (1 => '1')) else '0';
```

- `full` เมื่อ pointer ถัดไปของฝั่งเขียน ตรงกับ pointer ฝั่งอ่านที่ซิงก์แล้ว
  **โดยที่ MSB ถูกกลับ (inverted)** — เพราะ pointer มีบิตพิเศษที่บอกว่า "รอบละครึ่ง"
- `empty` เมื่อ pointer ของฝั่งอ่านเท่ากับ pointer ฝั่งเขียนที่ซิงก์แล้ว

### 8.4 ข้อควรระวัง

- **pointer ต้องเป็น Gray code** ตอนส่งข้าม domain
- **register ชื่อ `*_next`** ต้องเป็นผลของ logic รุ่นถัดไป ไม่ใช่ค่าปัจจุบัน
  เพราะ full/empty ต้องคำนวณจาก pointer ที่จะเป็นค่าหลังรอบนาฬิกานี้
- memory ต้องเป็นแบบ **write-first หรือ read-first** ที่ประกาศไว้ชัดเจน
  เพราะการอ่านและการเขียน address เดียวกันอาจเกิดพร้อมกัน

ตัวอย่างที่ผ่านการตรวจสอบอยู่ที่ `code/reference/vhdl/examples/ex06_async_fifo/`

## 9. การซิงก์ reset ข้าม domain

reset ที่สร้างจาก domain หนึ่งแล้วใช้อีก domain หนึ่งเป็นสัญญาณ asynchronous
ต้องซิงก์เช่นเดียวกับสัญญาณอื่น และต้องใช้ logic แบบ asynchronous assert
เพื่อให้ทั้งสอง domain ออกจาก reset พร้อมกัน

```vhdl
-- สร้าง reset ที่ซิงก์แล้วสำหรับ domain ปลายทาง
reset_sync_m <= rst_src_i;
reset_sync_i <= reset_sync_m;
```

> **ข้อควรระวัง**: ถ้าใช้ reset ที่ซิงก์แล้วกับ clock ของ domain ปลายทาง
> จะมีรอบที่ reset ยังไม่ถูกยืนยัน ทำให้ register บางตัวออกจาก reset ช้ากว่าตัวอื่น
> ในโปรเจกต์จริงให้ใช้วิธี assert แบบ asynchronous ใน RTL หรือใช้
> reset synchronizer IC ของ PDK

## 10. ข้อผิดพลาดที่พบบ่อย

| ข้อผิดพลาด | ผลที่ตามมา |
|---|---|
| ส่งสัญญาณจาก domain หนึ่งไปอีก domain หนึ่งโดยตรง | metastability ทำให้วงจรทำงานผิดแบบไม่มีรูปแบบ |
| ใช้ 2-flop synchronizer กับข้อมูลหลายบิต | ได้ข้อมูลที่ไม่เคยถูกส่ง หรือข้อมูลผสมระหว่างสองค่า |
| ใช้ 2-flop synchronizer กับพัลส์สั้น | พัลส์หายไปเงียบ ๆ |
| ปลด req ทันทีที่ยก โดยไม่รอ ack | ข้อมูลถูกเขียนทับก่อนที่ปลายทางจะอ่าน |
| ใช้ binary counter ส่ง pointer ข้าม domain | เกิดค่าที่ไม่มีอยู่จริง ทำให้ full/empty ผิด |
| คำนวณ full จาก pointer ปัจจุบันแทน pointer รุ่นถัดไป | FIFO จะเขียนทับข้อมูลเมื่อเต็ม |
| ใช้เงื่อนไข ready ที่ขึ้นกับ valid ในทางเดียว | deadlock |
| ไม่ตรวจ X ใน testbench ของ CDC | บั๊กที่เกิดจากสัญญาณซิงก์จะไม่ถูกจับ |

## 11. การตรวจสอบ CDC

### 11.1 ต้องมีนาฬิกาสองตัวที่ไม่มีความสัมพันธ์กัน

```vhdl
clk_a <= not clk_a after 5 ns when not done else '0';    -- 100 MHz
clk_b <= not clk_b after 7 ns when not done else '0';    -- ~71 MHz
```

การใช้ความถี่ต่างกันเล็กน้อยทำให้เฟสของทั้งสอง domain เลื่อนไปเรื่อย ๆ
ทำให้พบปัญหาการชนกันของ edge ในกรณีที่โอกาสเกิดจริงน้อย

### 11.2 ตรวจความถูกต้องของข้อมูล

ใน testbench ให้มี golden model ที่เก็บข้อมูลที่ส่งออกไว้ แล้วเทียบกับข้อมูลที่ได้รับ
ต้องเทียบ **ลำดับ** ไม่ใช่แค่จำนวน

### 11.3 ตรวจว่าไม่มีการอ่านเกิน

```vhdl
-- ต้องไม่เกิดเมื่อ FIFO เต็ม
assert not (wr_en = '1' and full = '1') report "write to full FIFO" severity failure;
```

### 11.4 ตรวจสถานะของ pointer

ถ้ามีสัญญาณ debug ของ pointer ให้เปรียบเทียบว่า pointer ที่ซิงก์แล้ว
ไม่มีค่าที่ "ผิด" (เช่น ห่างจาก pointer จริงมากกว่าความจุ)

---

## แบบฝึกหัดท้ายบท

1. เขียน `sync_ff2` และ testbench ที่ส่งสัญญาณระดับข้าม domain
   แล้วพิสูจน์ว่าเอาต์พุตตรงกับอินพุตหลังจากผ่าน 2 รอบนาฬิกาปลายทาง
2. เขียนฟังก์ชัน `binary_to_gray` และ `gray_to_binary` พร้อม testbench
   ที่ตรวจว่าแปลงกลับได้ค่าเดิมสำหรับทุกค่า 0..15
3. เขียน `sync_pulse` แล้วทดสอบว่าเมื่อส่งพัลส์ 2 ครั้งติดกันโดยห่างกันน้อย
   พัลส์ที่สองจะหายหรือไม่ อธิบายผล
4. เพิ่ม `force_safe` เข้าใน `ex04_fsm_enum` แล้วทดสอบ path กู้สถานะ
5. อธิบายว่าทำไมการส่ง pointer ของ FIFO ข้าม domain ต้องใช้ Gray code
   และจะเกิดอะไรขึ้นถ้าใช้ binary counter

## คำถามท้ายบท

1. metastability เกิดขึ้นเมื่อใด และเหตุใดการใช้ 2-flop synchronizer จึงต้องมี
   ฟลิปฟลอปอย่างน้อยสองตัว
2. ข้อจำกัดของ 2-flop synchronizer คืออะไร และกรณีใดต้องใช้กลไกอื่น
3. ใน handshake 4-phase ข้อมูลต้องถูกล็อกเมื่อใด และเหตุใด req จึงต้องรอ ack
4. Gray code มีคุณสมบัติอะไรที่ทำให้เหมาะกับการส่ง pointer ข้าม clock domain
5. ใน asynchronous FIFO ทำไมต้องมี pointer ที่เพิ่มบิตพิเศษ และบิตนั้นถูกใช้อย่างไร
   ในการคำนวณ full

---

**อ่านต่อ:** [บทที่ 08 — การคำนวณและ pipeline](08-arithmetic-and-pipeline.md)
