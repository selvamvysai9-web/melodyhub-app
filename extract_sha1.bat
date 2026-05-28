@echo off
REM ============================================
REM  Melody Hub — SHA-1 Fingerprint Extractor
REM ============================================
REM  Run this script to get your SHA-1 key for
REM  Firebase Console → Project Settings → Your apps
REM ============================================

echo.
echo [Melody Hub] SHA-1 Fingerprint Extractor
echo ==========================================
echo.

echo 1) DEBUG keystore (default):
set JAVA_HOME=C:\Android\jdk17
"%JAVA_HOME%\bin\keytool" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>&1 | findstr "SHA1"

echo.
echo 2) RELEASE keystore (if you created one):
REM Uncomment and edit the line below if you have a release keystore:
REM "%JAVA_HOME%\bin\keytool" -list -v -keystore "C:\path\to\your\upload-keystore.jks" -alias your-key-alias -storepass your-store-pass -keypass your-key-pass 2>&1 | findstr "SHA1"

echo.
echo ==========================================
echo  Copy the SHA1 value (without spaces) and
echo  paste it in Firebase Console.
echo ==========================================
pause
