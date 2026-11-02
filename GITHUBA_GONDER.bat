@echo off
REM Projeyi GitHub'a gonderir: eski bos baglanti kaydini kaldirir, tum dosyalari commit eder, push eder.
cd /d "%~dp0"
git rm -r --cached --quiet stay-in-the-spaceship-100-days 2>nul
git add -A
git commit -m "Sync project files from Claude session" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push
echo.
echo Bitti. Yukarida hata yoksa GitHub guncellendi.
pause
