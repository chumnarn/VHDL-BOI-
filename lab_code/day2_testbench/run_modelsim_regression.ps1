# ==========================================================================
# run_modelsim_regression.ps1
# รัน regression ของ lab_code/day2_testbench บน ModelSim/Questa (Windows)
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\run_modelsim_regression.ps1
#
# ข้อสำคัญ: ModelSim/Questa คืน exit code 0 แม้จะมี severity failure
#           (ต่างจาก GHDL ที่คืน 1) จึงต้องตรวจข้อความใน log แทน
# ==========================================================================
param(
    [string]$MsimBin = 'C:\Siemens\modelsim_dlx64_2026.1\win64pe'
)
$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$logDir = Join-Path $root 'reports\modelsim'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$report = Join-Path $logDir 'regression_summary.txt'

# ---------------------------------------------------------------- compile
Write-Output "===== COMPILE (vcom -2008) ====="
$srcs = @('counter_pkg.vhd', 'tb_support_pkg.vhd', 'uart_sb_pkg.vhd',
          'rtl\seq_det_moore.vhd', 'rtl\counter8.vhd', 'rtl\uart_tx.vhd') +
        (Get-ChildItem -Filter 'ex*.vhd' | Sort-Object Name | ForEach-Object { $_.Name })

foreach ($s in $srcs) {
    $out = & "$MsimBin\vcom.exe" -2008 -work work $s 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Output "COMPILE FAILED: $s"
        $out | Select-Object -Last 10
        exit 1
    }
}
Write-Output "compiled $($srcs.Count) files"

# ---------------------------------------------------------------- run
$units = @(
    'ex01_delta_cycle', 'ex02_signal_vs_variable', 'ex03_wait_statements',
    'ex04_clock_bug', 'ex04_clock_fixed', 'ex05_procedure_checker',
    'ex06_random_stimulus', 'ex07_uart_scoreboard', 'ex08_file_io',
    'ex10_external_name', 'ex12_event_log'
)

$lines = @()
$lines += "Regression summary  (ModelSim/Questa)"
$lines += "generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ("-" * 60)
$fail = 0

foreach ($u in $units) {
    $log = Join-Path $logDir "$u.log"
    & "$MsimBin\vsim.exe" -c "work.$u" -do "run -all; quit -f" *> $log
    $txt = Get-Content $log -Raw

    $hasErrLine = ($txt -match '\*\* (Failure|Error):')
    $errCount  = 0
    if ($txt -match 'Errors:\s*(\d+)') { $errCount = [int]$Matches[1] }

    $status = if ($hasErrLine -or $errCount -gt 0) { 'FAIL' } else { 'PASS' }
    if ($status -eq 'FAIL') { $fail++ }

    $lines += ("{0,-28} {1,-5}  errors={2}" -f $u, $status, $errCount)
    Write-Output ("{0,-28} {1,-5}  errors={2}" -f $u, $status, $errCount)
}

# ex09 : ทดสอบ 4 ระดับ severity
# ความคาดหวัง: severity ที่พิมพ์ออกมาต้องตรงกับระดับที่สั่ง
# (LEVEL=3 ต้องเป็น failure = กลไกทำงานถูกต้อง ไม่ใช่เคสที่ล้ม)
$expectSev = @('note', 'warning', 'error', 'failure')
foreach ($lvl in 0, 1, 2, 3) {
    $log = Join-Path $logDir "ex09_level$lvl.log"
    & "$MsimBin\vsim.exe" -c "-gLEVEL=$lvl" work.ex09_assertion_severity -do "run -all; quit -f" *> $log
    $rc = $LASTEXITCODE
    $txt = Get-Content $log -Raw
    $sev = 'none'
    if     ($txt -match '\*\* Failure:') { $sev = 'failure' }
    elseif ($txt -match '\*\* Error:')   { $sev = 'error' }
    elseif ($txt -match '\*\* Warning:') { $sev = 'warning' }
    elseif ($txt -match '\*\* Note:')    { $sev = 'note' }
    $status = if ($sev -eq $expectSev[$lvl]) { 'PASS' } else { 'FAIL' }
    if ($status -eq 'FAIL') { $fail++ }
    $lines += ("{0,-28} {1,-5}  severity={2} (expected {3})  vsim_exit={4}" -f `
               "ex09 LEVEL=$lvl", $status, $sev, $expectSev[$lvl], $rc)
    Write-Output ("{0,-28} {1,-5}  severity={2} (expected {3})  vsim_exit={4}" -f `
                  "ex09 LEVEL=$lvl", $status, $sev, $expectSev[$lvl], $rc)
}

# ex11 : ทั้ง 2 configuration
foreach ($cfg in 'cfg_using_rtl', 'cfg_using_alt') {
    $log = Join-Path $logDir "$cfg.log"
    & "$MsimBin\vsim.exe" -c "work.$cfg" -do "run -all; quit -f" *> $log
    $txt = Get-Content $log -Raw
    $hasErrLine = ($txt -match '\*\* (Failure|Error):')
    $status = if ($hasErrLine) { 'FAIL' } else { 'PASS' }
    if ($status -eq 'FAIL') { $fail++ }
    $lines += ("{0,-28} {1,-5}" -f $cfg, $status)
    Write-Output ("{0,-28} {1,-5}" -f $cfg, $status)
}

$lines += ("-" * 60)
$lines += "TOTAL FAIL: $fail"
$lines | Set-Content -Path $report -Encoding UTF8

Write-Output ""
Write-Output "report : $report"
Write-Output "TOTAL FAIL: $fail"
if ($fail -gt 0) { exit 1 } else { exit 0 }
