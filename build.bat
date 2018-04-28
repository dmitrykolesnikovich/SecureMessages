echo on

SET PREV_PATH=%CD%
cd /d %0\..

REM Clear bin folder
rmdir "bin" /S /Q
rmdir "gen" /S /Q
mkdir "bin" || goto EXIT
mkdir "gen" || goto EXIT

REM Set your application name
SET APP_NAME=SecureSms

REM Define aapt
SET ANDROID_AAPT="%ANDROID_HOME%\build-tools\25.0.3\aapt.exe"

REM Define aapt add command
SET ANDROID_AAPT_ADD=%ANDROID_AAPT% add

REM Define android.jar
SET ANDROID_JAR=%ANDROID_HOME%\platforms\android-26\android.jar

REM Define aapt pack and generate resources command
SET ANDROID_AAPT_PACK=%ANDROID_AAPT% package -v -f -I %ANDROID_JAR%

REM Define dx
SET ANDROID_DX="%ANDROID_HOME%\build-tools\25.0.3\dx.bat"  --dex

REM Define Java compiler command
SET JAVAC=javac.exe -source 1.7 -target 1.7 -classpath %ANDROID_JAR%
SET JAVAC_BUILD=%JAVAC% -sourcepath "src;gen" -d "bin"

REM Generate R class and pack resources and assets into resources.ap_ file
call %ANDROID_AAPT_PACK% -M "AndroidManifest.xml" -A "assets" -S "res" -m -J "gen" -F "bin\resources.ap_" || goto EXIT

REM Compile sources. All *.class files will be put into the bin folder
call %JAVAC_BUILD% src\org\secure\sms\*.java || goto EXIT

REM Generate dex files with compiled Java classes
call %ANDROID_DX% --output="%CD%\bin\classes.dex" %CD%\bin || goto EXIT

REM Recources file need to be copied. This is needed for signing.
copy "%CD%\bin\resources.ap_" "%CD%\bin\%APP_NAME%.ap_" || goto EXIT

REM Add generated classes.dex file into application package
call cd bin
call %ANDROID_AAPT_ADD% %APP_NAME%.ap_ classes.dex || goto EXIT
call cd ..

REM Create signed Android application from *.ap_ file. Output and Input files must be different.
call jarsigner -keystore "%CD%\keystore\my-release-key.keystore" -storepass password -keypass password -signedjar "%CD%\bin\%APP_NAME%.apk" "%CD%\bin\%APP_NAME%.ap_" "alias_name" || goto EXIT

REM Delete temp file
del "bin\%APP_NAME%.ap_"

REM Install APK
adb install -r bin\SecureSms.apk

:EXIT
cd "%PREV_PATH%"
ENDLOCAL
exit /b %ERRORLEVEL%
