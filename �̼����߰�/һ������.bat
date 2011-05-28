@ECHO OFF
CLS
color 0a

GOTO MENU
:MENU
ECHO.
ECHO.本批处理可将system.img进行解包打包操作。 原作者: http://401389373.qzone.qq.com/
echo. 
echo. 由Wendal修改,专供台电平板固件 http://wendal.net
echo. 
echo. 注意：
echo. 1、本工具包必须放在NTFS分区里才能正常使用；
echo. 2、操作前请先将system.img boot.img放在本工具包目录下；
ECHO. 3、system.img解包后的文件位于工具包system目录下；
ECHO. 3、boot.img解包后的文件位于工具包boot目录下；
ECHO. 
ECHO. ------------固件修改功能列表----------------
ECHO.
ECHO. 1 system.img解包(无论是否已经加密)
ECHO.
ECHO. 2 system.img打包并加密
ECHO.
ECHO. 3 boot.img解包
ECHO.
ECHO. 4 boot.img打包
ECHO.
ECHO. 5 system.img打包
ECHO.
ECHO. 6 固件开启Root(永久root权限)
ECHO.
ECHO. 7 退 出
ECHO.
ECHO. --------------------------------------------
echo. 请选择功能序号并回车确认：
set /p ID=
if "%id%"=="1" goto cmd1

if "%id%"=="2" goto cmd2

if "%id%"=="3" goto cmd3

if "%id%"=="4" goto cmd4

if "%id%"=="5" goto cmd5

if "%id%"=="6" goto cmd6

IF "%id%"=="7" exit
PAUSE

:cmd1
echo. --------------------------------------------
echo.
echo. system.img解包说明：
echo. 1、以前遗留的同名文件将被覆盖；
echo. 2、请注意查看解包信息，确定解包是否正常。
echo. 3、执行解包操作后，会将system.img解压到工
echo. 具包内的system文件夹中，方便修改。
echo.
echo.确认好后，
pause
echo. -----------------------------------------  
rkDecrypt system.img
echo -----------------------------------------  
pfn -p1 system.img
echo. -----------------------------------------
echo.
echo 正在解包中，请稍后...  
rmdir /s /q system 2>nul
cramfsck_nocrc -x system system.img
echo. -----------------------------------------  
echo. 解包完成!
pause
goto MENU

:cmd2
echo.
echo.
echo. system打包说明：
echo. 1、打包成功后,会在工具包目录生成名为system_new.img的固件；
echo. 2、以前遗留的同名固件文件将被覆盖；
echo. 3、请注意查看打包信息，确定打包是否正常。
echo.
echo.确认好后，
pause
echo. ----------------------------------------- 
echo.正在打包中，请稍后...
mkcramfs -q system system_new.img
echo.打包完成!
echo. -----------------------------------------  
pfn -p2 system_new.img
echo.加密完成!
pause
GOTO MENU

:cmd3
echo. --------------------------------------------
echo.
echo. boot.img解包说明：
echo. 1、以前遗留的同名文件将被覆盖；
echo. 2、请注意查看解包信息，确定解包是否正常。
echo. 3、执行解包操作后，会将boot.img解压到工
echo. 具包内的boot文件夹中，方便修改。
echo.
echo.确认好后，
pause
echo. -----------------------------------------  
echo 正在解包中，请稍后... 
rmdir /s /q boot 2>nul
cramfsck_nocrc -x boot boot.img
echo. -----------------------------------------
echo. 解包完成!
pause
goto MENU

:cmd4
echo.
echo.
echo. boot打包说明：
echo. 1、打包成功后,会在工具包目录生成名为boot_new.img的固件；
echo. 2、以前遗留的同名固件文件将被覆盖；
echo. 3、请注意查看打包信息，确定打包是否正常。
echo.
echo.确认好后，
pause
mkcramfs -q boot boot_New.tmp
echo -----------------------------------------  
rkcrc boot_New.tmp boot_New.img
del /F /Q boot_New.tmp
echo.打包完成!
pause
GOTO MENU

:cmd5
echo.
echo.
echo. system打包说明：
echo. 1、打包成功后,会在工具包目录生成名为system_new.img的固件；
echo. 2、以前遗留的同名固件文件将被覆盖；
echo. 3、请注意查看打包信息，确定打包是否正常。
echo.
echo.确认好后，
pause
echo. ----------------------------------------- 
echo.正在打包中，请稍后...
mkcramfs -q system system_new.img
echo.打包完成!
echo. -----------------------------------------  
pause
GOTO MENU

:cmd6
echo.
echo. --------------------------------------------
echo. 固件Root说明：
echo. 1、本操作需确保已经通过上面的解包功能将固件解包了；
echo.
echo.确认好后，
pause
echo. -----------------------------------------  
copy /B su system\bin\su >nul
copy /B Superuser.apk system\app\ >nul
chmod -R 0777 system/*
chmod 6755 system/bin/su
chmod 6755 system/app/Superuser.apk
echo. ----------------------------------------- 
echo.Root成功!
pause
GOTO MENU



