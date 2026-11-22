# วิธีติดตั้ง WSL 2 และ Ubuntu บน Windows 11

เราสามารถติดตั้งจาก **PowerShell ที่เปิดด้วยสิทธิ์ Administrator** ด้วยคำสั่ง `wsl --install` จากนั้นรีสตาร์ต เปิด Ubuntu เพื่อสร้างผู้ใช้ Linux แล้วตรวจด้วย `wsl -l -v` ว่าคอลัมน์ **VERSION** ของ Ubuntu เป็น **2**  [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

คู่มือนี้ใช้ Windows 11 เป็นหลัก คำสั่งติดตั้งแบบเดียวกันใช้ได้บน Windows 10 เวอร์ชัน 2004 ขึ้นไปที่มี Build 19041 ขึ้นไปด้วย [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

## 1. ตรวจ Windows และ Virtualization

1. กด **Win + R** พิมพ์ `winver` แล้วกด Enter เพื่อดูเวอร์ชันและ Build ของ Windows
2. กด **Ctrl + Shift + Esc** เปิด **Task Manager**
3. ไปที่ **Performance → CPU** แล้วดูรายการ **Virtualization**
4. ถ้าขึ้น **Enabled** ให้ไปขั้นตอนถัดไป ถ้าขึ้น **Disabled** ให้เข้า BIOS/UEFI แล้วเปิด **Intel Virtualization Technology (VT-x)** หรือ **AMD SVM Mode / AMD-V** ตามรุ่นเครื่อง บันทึกค่า รีสตาร์ต แล้วกลับมาตรวจอีกครั้ง [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

WSL 2 ใช้ Linux kernel ภายใน virtual machine ที่ Windows จัดการ จึงต้องเปิด Virtualization ในเฟิร์มแวร์และเปิดฟีเจอร์ **Virtual Machine Platform** ใน Windows คำสั่งติดตั้งปกติจะจัดการฟีเจอร์ Windows ที่จำเป็นให้ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

## 2. เปิด PowerShell แบบ Administrator และติดตั้ง

คลิกขวาที่ **Start → Terminal (Admin)** แล้วกด **Yes** ที่หน้าต่าง UAC เลือกแท็บ PowerShell จากนั้นใช้คำสั่งตามกรณีด้านล่าง [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

### กรณี A — ติดตั้ง Ubuntu รุ่นเริ่มต้น

```powershell
wsl --install
```

รอจนคำสั่งเสร็จ แล้ว **รีสตาร์ต Windows** คำสั่งนี้จะติดตั้ง WSL และ Ubuntu รุ่นเริ่มต้น โดยดิสโทรที่ติดตั้งผ่านขั้นตอนนี้ใช้ WSL 2 เป็นค่าเริ่มต้น [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

### กรณี B — เลือก Ubuntu ให้ตรงกับคู่มืออบรม

สำหรับ Lab ที่กำหนด Ubuntu 22.04 LTS ให้ดูชื่อดิสโทรที่ Windows แสดงก่อน แล้วใช้ชื่อนั้นกับ `-d` ตัวอย่างต่อไปนี้ใช้ชื่อ `Ubuntu-22.04` หากปรากฏในรายการ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

```powershell
wsl --list --online
wsl --install -d Ubuntu-22.04
```

รีสตาร์ตหาก Windows ขอให้รีสตาร์ต วิธีระบุ `-d` ใช้ได้เช่นกันเมื่อเครื่องมี WSL อยู่แล้วและพิมพ์ `wsl --install` แล้วพบหน้าคู่มือคำสั่ง [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

## 3. เปิด Ubuntu ครั้งแรกและสร้างผู้ใช้ Linux

เปิด **Ubuntu** จาก Start Menu หรือเรียกจาก PowerShell ด้วยชื่อดิสโทรที่ติดตั้ง ตัวอย่างสำหรับ Ubuntu 22.04 [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

```powershell
wsl -d Ubuntu-22.04
```

ครั้งแรก Ubuntu จะเตรียมไฟล์ระบบและให้สร้าง **UNIX username** กับ **password** ตั้งชื่อผู้ใช้ เช่น `chumnarn` และพิมพ์รหัสผ่านสองครั้ง ขณะพิมพ์รหัสผ่าน หน้าจอจะไม่แสดงตัวอักษรหรือ `*` เมื่อเห็นพรอมต์ลักษณะ `chumnarn@เครื่อง:~$` ก็พร้อมใช้คำสั่ง Linux และใช้รหัสผ่านที่ตั้งไว้กับ `sudo` ได้ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)

## 4. ยืนยันว่า Ubuntu ใช้ WSL 2

กลับไปที่ **PowerShell** แล้วรัน [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com)

```powershell
wsl -l -v
```

ตัวอย่างผลลัพธ์

```text
  NAME            STATE           VERSION
* Ubuntu-22.04    Running         2
```

ดู **VERSION ของดิสโทร** เป็นหลัก ค่า `2` ยืนยันว่าดิสโทรนั้นใช้ WSL 2 ส่วน `Running` หรือ `Stopped` บอกว่าดิสโทรกำลังทำงานอยู่หรือหยุดอยู่ และ `*` ระบุดิสโทรเริ่มต้นของคำสั่ง `wsl` [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com)

ถ้า Ubuntu ที่มีอยู่เดิมแสดง `VERSION 1` ให้ปิดงานที่กำลังรันในดิสโทร สำรองไฟล์สำคัญ แล้วสั่งแปลงด้วยชื่อจริงจากคอลัมน์ `NAME` คำสั่ง `--set-default-version 2` กำหนดค่าให้กับดิสโทรที่จะติดตั้งภายหลัง ส่วน `--set-version` ใช้แปลงดิสโทรที่ติดตั้งแล้ว [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com)

```powershell
wsl --set-version Ubuntu-22.04 2
wsl --set-default-version 2
wsl -l -v
```

## 5. อัปเดต WSL และเตรียม Ubuntu สำหรับงาน Lab

อัปเดตตัว WSL จาก **PowerShell** แล้วตรวจเวอร์ชันของซอฟต์แวร์ WSL ด้วย `wsl --version` [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com)

```powershell
wsl --update
wsl --version
```

จากนั้นเปิด **Ubuntu** และรันคำสั่ง Bash ต่อไปนี้ `apt update` จะอัปเดตรายการแพ็กเกจ ส่วน `apt upgrade` จะอัปเดตแพ็กเกจที่ติดตั้งอยู่

```bash
sudo apt update
sudo apt upgrade
sudo apt install git curl build-essential

cat /etc/os-release
uname -r
git --version
```

สำหรับ LibreLane, Verilator หรือ Lab ที่สร้างไฟล์จำนวนมาก ให้เก็บ repository และโฟลเดอร์ผลการรันไว้ในระบบไฟล์ Linux เช่น `~/eda` เพื่อให้เครื่องมือ Linux เข้าถึงไฟล์ได้เร็วขึ้น เปิดโฟลเดอร์นั้นใน Windows File Explorer ได้ด้วย `explorer.exe .` [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/filesystems?utm_source=chatgpt.com)

```bash
mkdir -p ~/eda
cd ~/eda
explorer.exe .
```

## 6. แก้ปัญหาที่พบบ่อย

| อาการ | วิธีตรวจและแก้ |
|---|---|
| `wsl --install` แสดงหน้าคู่มือคำสั่ง | รัน `wsl --list --online` แล้วติดตั้งด้วย `wsl --install -d Ubuntu` หรือใช้ชื่อรุ่นที่ปรากฏในรายการ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com) |
| การดาวน์โหลดค้างที่ `0.0%` | ลอง `wsl --install --web-download -d Ubuntu` จาก PowerShell แบบ Administrator โดยเปลี่ยนชื่อดิสโทรให้ตรงกับรุ่นที่ต้องการ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com) |
| พบ `0x80370102` หรือ `HCS_E_HYPERV_NOT_INSTALLED` | ตรวจว่า **Virtualization** เป็น **Enabled** และเปิด **Virtual Machine Platform** แล้วรีสตาร์ต หาก Windows ที่ใช้เป็น VM ให้ตรวจว่า hypervisor เปิด nested virtualization ให้ VM นั้น [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting?utm_source=chatgpt.com) |
| พบ `WSL_E_DISTRO_NOT_FOUND` | รัน `wsl -l -v` แล้วคัดลอกชื่อจากคอลัมน์ `NAME` ไปใช้กับ `wsl -d` หรือในสคริปต์ติดตั้ง ตัวอย่างเช่น ถ้ารายการแสดง `Ubuntu` ให้ใช้ `wsl -d Ubuntu` คำว่า `(Default)` เป็นตัวบอกสถานะของดิสโทรเริ่มต้น [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com) |
| เปิดสคริปต์จาก USB แล้วพบ `Failed to translate 'I:\'` | เปลี่ยน working directory ของ PowerShell กลับไปที่ไดรฟ์ระบบด้วย `Set-Location $env:SystemDrive\` แล้วลอง `wsl ~` หากต้องเข้าถึงไฟล์บน USB จาก Ubuntu ให้ตรวจแยกว่ามองเห็น `/mnt/i` หรือไม่ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com) |

หากต้องเปิด **Virtual Machine Platform** ด้วยตนเอง ให้รันคำสั่งนี้ใน PowerShell แบบ Administrator แล้วรีสตาร์ต Windows ก่อนทดสอบอีกครั้ง [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting?utm_source=chatgpt.com)

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

**เกณฑ์ว่าติดตั้งสำเร็จ** คือ `wsl -l -v` แสดง Ubuntu ที่ต้องการพร้อม `VERSION 2` และเมื่อเปิดดิสโทรแล้ว `cat /etc/os-release` แสดง Ubuntu รุ่นที่ตั้งใจติดตั้งครับ [Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com)
