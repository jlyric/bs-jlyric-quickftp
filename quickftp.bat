:: REM *
:: REM * QuickFTP
:: REM * Incrementally uploads files to a remote FTP completely in CMD.
:: REM *
:: REM * Batch script that checks a local directory against a remote FTP.
:: REM * If files exists locally that do not exist remotely, the files will
:: REM * be pushed to the remote host.  This is a one way synchronization.
:: REM * 
:: REM * LICENSE: This source file is proprietary to the respective copyright
:: REM * holder(s) described below and released without license.  Usage,
:: REM * licensing and distribution rights must be obtained from the copyright
:: REM * holder listed below.
:: REM *
:: REM * @category        public
:: REM * @package         cmd.jlyric.quickftp
:: REM * @author          Justin Lyric <jlyric@me.com>
:: REM * @copyright       2025 Justin Lyric

@echo off
setlocal enabledelayedexpansion

echo -
echo -
echo "                 QuickFTP                 "
echo -
echo -

REM ***************** quickftp configuration values ******************
REM remote ftp details
set ftphost=localhost
set ftpuser=jlyric
set ftppass=p@ss!@

REM configure the local working directory
set localdir=C:\XMLOut

REM configure the remote working directory
set remotedir=/

REM configure which types of files you want to upload
set filter=/e /c:".xml"

REM logging filename which will be saved in the working 
REM directory. add REM to this statement to remove logging.
REM this provides a more robust output in the command window 
REM instead logs being saved to disk.
set ftplog=%localdir%\logs\%ftphost%-%date:~10,4%_%date:~7,2%_%date:~4,2%_%time:~0,2%_%time:~3,2%_%time:~6,2%.log

REM directory where files should be moved after the ftp process has completed.
REM REM out the following statement to stop the files from being moved.
set movedir=%localdir%\uploaded

REM do not edit anything below this line.  you risk screwing up the script.
REM ***********************************************************************

echo "remote ftp:           %ftphost%"
echo "remote user:          %ftpuser%"
echo "remote pass:          *********"
echo "remote working dir:   %remotedir%"
echo -
echo "local dir:            %localdir%"
echo "local filter:         %filter%"
echo -

IF DEFINED ftplog (
  echo "logging is enabled."
) ELSE (
  echo "logging is disabled."
)

echo -
echo "[status]: logging in to %ftphost% and comparing %localdir% with %remotedir%"

REM extract embedded ftp script to create local list of files.
set "ftpcommand=ls"
call:extractscript "[commands]" "-">"%cd%\%~n0.ftp"

REM notepad "%cd%\%~n0.ftp"

REM execute script, generate a list of files from the remote working directory.
REM - connection 1.
set "filelist="
for /F "delims=" %%A In ('"ftp -v -i -s:"%cd%\%~n0.ftp"|findstr %filter%"') do (
    call set "filelist=%%filelist%% "%%A""
    echo "[check-in]: remote file -> %%A"
)

REM compare local files with the remote file listing retrieved.
set sentinel=0
set "ftpcommand=mput"
for %%A in (%filelist%) do set "exist["%%~A"]=Y"
for /F "delims=" %%A in ('"dir /b "%localdir%"|findstr %filter%"') do (
    echo "[check-in]: local file -> %%~A"
    if not defined exist["%%~A"] call set "ftpcommand=%%ftpcommand%% "%%~A""
    if not defined exist["%%~A"] echo "[preparing]: upload queued for -> %%~A"
    if not defined exist["%%~A"] set sentinel=%sentinel%+1

)

REM no new files ergo nothing to upload so go ahead and exit.
if %sentinel% == 0 echo "[status]: no new files to upload...exiting." & GOTO:EOF

REM extract connection details to process pending ftp commands.
call:extractscript "[commands]" "-">"%cd%\%~n0.ftp"
REM  notepad "%cd%\%~n0.ftp"

REM instantiate
IF DEFINED ftplog (
 GOTO:withlog
) ELSE (
 GOTO:withoutlog
)

:withlog
ftp -i -s:"%cd%\%~n0.ftp" >> %ftplog%
IF ERRORLEVEL 1 (
  echo "error..."
)
IF DEFINED movedir (
  for %%A in (%filelist%) do set "exist["%%~A"]=Y"
  for /F "delims=" %%A in ('"dir /b "%localdir%"|findstr %filter%"') do (
    if not defined exist["%%~A"] move %localdir%\%%~A %movedir%\%%~A
    if  not defined exist["%%~A"] echo "[moving]: %localdir%\%%~A -> %movedir%\%%~A"
  )
)
del "%cd%\%~n0.ftp"
echo "[complete]: incremental uploads completed successfully.  a log for this transaction has been created dubbed %ftplog%.
GOTO:EOF

:withoutlog
ftp -i -s:"%cd%\%~n0.ftp"
IF DEFINED movedir (
  for %%A in (%filelist%) do set "exist["%%~A"]=Y"
  for /F "delims=" %%A in ('"dir /b "%localdir%"|findstr %filter%"') do (
    if not defined exist["%%~A"] move %localdir%\%%~A %movedir%\%%~A
    if  not defined exist["%%~A"] echo "[moving]: %localdir%\%%~A -> %movedir%\%%~A"
  )
)

del "%cd%\%~n0.ftp"
GOTO:EOF

:extractscript
set "bmk=%~1"
set "emk=%~2"
set "src=%~3"
set "bExtr="
set "bSubs="
if "%src%"=="" set src=%~f0&
for /f "tokens=1,* delims=]" %%A in ('find /n /v "" "%src%"') do (
    if /i "%%B"=="%emk%" set "bExtr="&set "bSubs="
    if defined bExtr if defined bSubs (call echo.%%B) ELSE (echo.%%B)
    if /i "%%B"=="%bmk%"   set "bExtr=Y"
    if /i "%%B"=="%bmk%:S" set "bExtr=Y"&set "bSubs=Y"
)
EXIT /b


[commands]:S
open %ftphost%
%ftpuser%
%ftppass%
cd %remotedir%
lcd %localdir%
binary
hash
%ftpcommand%
disconnect
bye
