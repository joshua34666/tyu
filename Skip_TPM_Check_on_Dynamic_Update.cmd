@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script

$_Paste_in_Powershell = { $:code;  
  $N = 'Skip TPM Check on Dynamic Update'; $toggle = $null -eq $env:skip_tpm_enabled; $off = $false
  $M = sp HKLM:\SYSTEM\Setup\MoSetup 'AllowUpgradesWithUnsupportedTPMOrCPU' 1 -type dword -force -ea 0
  $M = sc.exe config Winmgmt start= demand; sp HKLM:\SOFTWARE\Microsoft\Wbem 'Enable Costly Providers' 0 -type dword -force -ea 0
  $B = gwmi -Class __FilterToConsumerBinding -Namespace 'root\subscription' -Filter "Filter = ""__eventfilter.name='$N'""" -ea 0
  $C = gwmi -Class CommandLineEventConsumer -Namespace 'root\subscription' -Filter "Name='$N'" -ea 0
  $F = gwmi -Class __EventFilter -NameSpace 'root\subscription' -Filter "Name='$N'" -ea 0
  if ($B -or $C -or $F) { $B | rwmi; $C | rwmi; $F | rwmi; $off = $true }
  if ($toggle -and $off) { write-host -fore 0xf -back 0xd "`n $N [REMOVED] run again to install "; timeout /t 5; return }
  $P = "$([environment]::SystemDirectory)\cmd.exe"; $T = "$P /q $N (c) AveYo, 2021 /d /rerase appraiserres.dll /f /s /q"
  $D = "$($P[0]):\`$WINDOWS.~BT"; $Q = "SELECT SessionID from Win32_ProcessStartTrace WHERE ProcessName='vdsldr.exe'"
  $F = swmi -Class __EventFilter -NameSpace 'root\subscription' -args @{
    Name = $N; EventNameSpace = 'root\cimv2'; QueryLanguage = 'WQL'; Query = $Q} -PutType 2 -ea 0
  $C = swmi -Class CommandLineEventConsumer -Namespace 'root\subscription' -args @{
    Name = $N; WorkingDirectory = $D; ExecutablePath = $P; CommandLineTemplate = $T; Priority = 128} -PutType 2 -ea 0
  $B = swmi -Class __FilterToConsumerBinding -Namespace 'root\subscription' -args @{Filter=$F;Consumer=$C} -PutType 2 -ea 0
  if ($toggle) { write-host -fore 0xf -back 0x2 "`n $N [INSTALLED] run again to remove "; timeout /t 5 } ; $:code;
} ; start -verb runas powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}"
$_Press_Enter

