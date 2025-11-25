@echo off
echo ========================================
echo   Android Emulator ile OCR Test
echo ========================================
echo.
echo Mac olmadan iOS testi icin Android emulator kullanabilirsiniz.
echo Android ve iOS'ta ayni OCR kutuphanesi kullaniliyor!
echo.
echo Adimlar:
echo 1. Android emulator baslatilacak
echo 2. Uygulama calistirilacak
echo 3. Galeri ile test edebilirsiniz
echo.
pause

echo.
echo Emulator listesi goruntuleniyor...
flutter emulators

echo.
echo Hangi emulator'u baslatmak istersiniz?
echo (Ornek: Pixel_7 veya Medium_Phone_API_36.0)
set /p emulator_name="Emulator adi: "

echo.
echo Emulator baslatiliyor: %emulator_name%
flutter emulators --launch %emulator_name%

echo.
echo Emulator acilana kadar bekleyin (30-60 saniye)...
echo Emulator acildiktan sonra Enter'a basin...
pause

echo.
echo Bagli cihazlar kontrol ediliyor...
flutter devices

echo.
echo Uygulama calistiriliyor...
echo (Cikmak icin 'q' tusuna basin)
flutter run

pause

