@echo off
setlocal enabledelayedexpansion

:: ===================================================
::           KONFIGURASI - SESUAIKAN BAGIAN INI
:: ===================================================
:: Nama Aplikasi (hanya untuk tampilan)
set "APP_NAME=Download & Update"

:: Nama file executable yang akan diperiksa keberadaannya
rem set "APP_EXE=Download&Update.exe"

:: --- Konfigurasi Repositori GitHub ---
:: Owner dan nama repositori (ini yang membuat skrip fleksibel)
set "REPO_OWNER=Sugandi1994"
set "REPO_NAME=TELEGRAM-DOWNLOADER-SCRIPT-VIOLENT-MONKEY"

:: Nama file zip sementara dan folder ekstrak (biasanya tidak perlu diubah)
set "ZIP_FILE=update.zip"
set "EXTRACT_DIR=temp_update"
set "BACKUP_DIR=_backup"
:: ===================================================

:: --- Membuat URL dan Path secara Dinamis (JANGAN UBAH BAGIAN INI) ---
set "REPO_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/main.zip"
:: Nama folder di dalam file zip (GitHub selalu menggunakan format 'nama-repo-main')
set "REPO_ZIP_CONTENT_DIR=%REPO_NAME%-main"

:: --- Setup UI ---
color 0B
title Installer / Updater for %APP_NAME%
cls
echo ===================================================
echo      Installer / Updater for %APP_NAME%
echo ===================================================
echo.

:: --- Deteksi Mode: Instalasi atau Pembaruan ---
IF NOT EXIST "%APP_EXE%" (
    echo [INFO] Aplikasi '%APP_EXE%' tidak ditemukan.
    echo Memulai proses INSTALASI pertama kali...
    GOTO INSTALL
) ELSE (
    echo [INFO] Aplikasi '%APP_EXE%' ditemukan.
    echo Memulai proses UPDATE...
    GOTO UPDATE
)


:INSTALL
:: ===================================================
::                  MODE INSTALASI
:: ===================================================
echo.
echo ===================================================
echo                MODE INSTALASI
echo ===================================================
echo.

:: --- 1. Pemeriksaan Koneksi Internet ---
echo [1/4] Memeriksa koneksi internet...
ping -n 1 google.com > nul
if %errorLevel% neq 0 (
    echo ERROR: Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.
    echo.
    pause
    exit /b
)
echo OK: Koneksi internet tersedia.
echo.

:: --- 2. Mengunduh File Aplikasi ---
echo [2/4] Mengunduh file aplikasi dari GitHub...
:: Metode Unduhan 1: PowerShell
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%ZIP_FILE%' } catch { exit 1 }"
:: Jika PowerShell gagal, coba Metode 2: curl (lebih kompatibel)
if %errorLevel% neq 0 (
    echo [WARNING] Metode PowerShell gagal, mencoba dengan curl...
    curl -L -k -o "%ZIP_FILE%" "%REPO_URL%"
)
if %errorLevel% neq 0 (
    echo ERROR: Pengunduhan gagal. Periksa URL repositori atau koneksi Anda.
    echo.
    pause
    exit /b
)
echo OK: File berhasil diunduh.
echo.

:: --- 3. Mengekstrak dan Menyalin File ---
echo [3/4] Mengekstrak dan menginstal file...
if exist "%EXTRACT_DIR%" rmdir "%EXTRACT_DIR%" /S /Q
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %errorLevel% neq 0 (
    echo ERROR: Gagal mengekstrak file. File mungkin rusak.
    echo.
    pause
    exit /b
)

:: PERUBAHAN: Path xcopy sekarang dinamis, menyalin ISI dari folder yang diekstrak
xcopy "%EXTRACT_DIR%\%REPO_ZIP_CONTENT_DIR%\*" "." /E /Y /I /Q
if %errorLevel% neq 0 (
    echo ERROR: Gagal menyalin file.
    echo.
    pause
    exit /b
)
echo OK: File berhasil diinstal.
echo.

:: --- 4. Membersihkan dan Selesai ---
echo [4/4] Membersihkan file sementara...
if exist "%ZIP_FILE%" del "%ZIP_FILE%"
if exist "%EXTRACT_DIR%" rmdir "%EXTRACT_DIR%" /S /Q
echo OK: Pembersihan selesai.
echo.
echo ===================================================
echo             INSTALASI BERHASIL!
echo ===================================================
echo Aplikasi %APP_NAME% telah selesai diinstal.
echo.
echo Aplikasi akan dimulai otomatis dalam 5 detik...
timeout /t 5 /nobreak >nul
start "" "%APP_EXE%"
exit /b


:UPDATE
:: ===================================================
::                   MODE UPDATE
:: ===================================================
echo.
echo ===================================================
echo                  MODE UPDATE
echo ===================================================
echo.

:: --- 1. Pemeriksaan Hak Akses Administrator ---
echo [1/7] Memeriksa hak akses administrator...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Harap jalankan skrip ini sebagai Administrator.
    echo Klik kanan pada file dan pilih "Run as administrator".
    echo.
    pause
    exit /b
)
echo OK: Hak akses administrator dikonfirmasi.
echo.

:: --- 2. Pemeriksaan Koneksi Internet ---
echo [2/7] Memeriksa koneksi internet...
ping -n 1 google.com > nul
if %errorLevel% neq 0 (
    echo ERROR: Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.
    echo.
    pause
    exit /b
)
echo OK: Koneksi internet tersedia.
echo.

:: --- 3. Pemeriksaan Aplikasi yang Berjalan ---
echo [3/7] Memeriksa apakah aplikasi sedang berjalan...
tasklist /FI "IMAGENAME eq %APP_EXE%" 2>NUL | find /I /N "%APP_EXE%">NUL
if %errorLevel% equ 0 (
    echo WARNING: Aplikasi '%APP_EXE%' sedang berjalan.
    echo Silakan tutup aplikasi tersebut sebelum melanjutkan.
    echo.
    pause
    exit /b
)
echo OK: Aplikasi tidak berjalan.
echo.

:: --- 4. Membuat Backup ---
echo [4/7] Membuat cadangan file lama...
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"
set "CURRENT_BACKUP_DIR=%BACKUP_DIR%\%TIMESTAMP%"

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
mkdir "%CURRENT_BACKUP_DIR%"

echo %BACKUP_DIR%> exclude.txt
echo %ZIP_FILE%>> exclude.txt
echo %EXTRACT_DIR%>> exclude.txt
echo %~nx0>> exclude.txt

xcopy "." "%CURRENT_BACKUP_DIR%" /E /I /Y /Q /EXCLUDE:exclude.txt >nul
del exclude.txt >nul

if %errorLevel% neq 0 (
    echo ERROR: Gagal membuat cadangan file. Proses dibatalkan.
    echo.
    pause
    exit /b
)
echo OK: Cadangan disimpan di folder "%CURRENT_BACKUP_DIR%".
echo.

:: --- 5. Mengunduh File Update ---
echo [5/7] Mengunduh file update dari GitHub...
:: Metode Unduhan 1: PowerShell
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%ZIP_FILE%' } catch { exit 1 }"
:: Jika PowerShell gagal, coba Metode 2: curl
if %errorLevel% neq 0 (
    echo [WARNING] Metode PowerShell gagal, mencoba dengan curl...
    curl -L -k -o "%ZIP_FILE%" "%REPO_URL%"
)
if %errorLevel% neq 0 (
    echo ERROR: Pengunduhan gagal. Periksa URL repositori atau koneksi Anda.
    echo.
    pause
    exit /b
)
echo OK: File berhasil diunduh.
echo.

:: --- 6. Mengekstrak dan Memperbarui File ---
echo [6/7] Mengekstrak dan memperbarui file...
if exist "%EXTRACT_DIR%" rmdir "%EXTRACT_DIR%" /S /Q
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %errorLevel% neq 0 (
    echo ERROR: Gagal mengekstrak file. File mungkin rusak.
    echo.
    pause
    exit /b
)

echo %~nx0> exclude_update.txt
:: PERUBAHAN: Path xcopy sekarang dinamis, menyalin ISI dari folder yang diekstrak
xcopy "%EXTRACT_DIR%\%REPO_ZIP_CONTENT_DIR%\*" "." /E /Y /I /Q /EXCLUDE:exclude_update.txt
if %errorLevel% neq 0 (
    echo ERROR: Gagal menyalin file baru.
    echo.
    del exclude_update.txt >nul
    pause
    exit /b
)
del exclude_update.txt >nul
echo OK: File berhasil diperbarui.
echo.

:: --- 7. Membersihkan dan Selesai ---
echo [7/7] Membersihkan file sementara...
if exist "%ZIP_FILE%" del "%ZIP_FILE%"
if exist "%EXTRACT_DIR%" rmdir "%EXTRACT_DIR%" /S /Q
echo OK: Pembersihan selesai.
echo.
echo ===================================================
echo               UPDATE BERHASIL!
echo ===================================================
echo Aplikasi %APP_NAME% telah diperbarui ke versi terbaru.
echo Cadangan versi lama tersimpan di folder "%BACKUP_DIR%".
echo.
echo Aplikasi akan dimulai otomatis dalam 5 detik...
timeout /t 5 /nobreak >nul
rem start "" "%APP_EXE%"

exit /b
