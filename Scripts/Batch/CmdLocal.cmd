:: DO NOT USE @ECHO OFF/ON IN THIS BATCH FILE,
:: It will alter the echo state of the command shell.
:: ---------------------- Help ----------------------
::=::CMDLOCAL
::=::A tool to dynamically change the state of CMD Extensions and Delayed Expansion at command line context.
::=::Usage:
::=::  CMDLOCAL [ EnableExtensions | DisableExtensions ] [ EnableDelayedExpansion | DisableDelayedExpansion ]
::=::
::=::Use at command line only.
:: ---------------------- Help ----------------------

@setlocal EnableExtensions DisableDelayedExpansion

:: /---------------------- Trampoline ----------------------
@setlocal
@set "#f0=%~f0"
@if "%~d0"=="\\" (
    set "tokens=2-4"
    if "%#f0:~0,4%"=="\\.\" (
        REM \\.\X:\path...
        if "%#f0:~5,1%"==":" set "tokens=3-5"
    )
) else set "tokens=3-5"
@endlocal & for /F "tokens=%tokens% delims=:" %%B in ("%~0") do @(
    if "%%D"=="" (set "branchParams=") else set "branchParams=%%C"
    goto %%B
)
:: ---------------------- Trampoline ----------------------/

:: /---------------------- Bootstrapper ----------------------
@set "@ReturnToCaller=(goto)"
@set "@clearError=(call,)"
@set "@brWorker=%~dp0:brWorker:brParams:\..\%~nx0"
@if "%@brWorker%"=="%@brWorker:*!=%" (
    set "hasBang="
    set "@brWorker.DelayProtected=%@brWorker%"
) else (
    set "hasBang=1"
    set "@brWorker.DelayProtected=%@brWorker:^=^^%"
)
@if defined hasBang set "@brWorker.DelayProtected=%@brWorker.DelayProtected:!=^!%"

:: Protect against malformed arguments by using (call ... %%*)
:: (%%*,): Using ',' to protect against a less known CMD bug (triggers if the last character of %%* is an unescaped caret '^')
:: https://web.archive.org/web/20170814061717/https://stackoverflow.com/questions/23284131/cmd-exe-parsing-bug-leads-to-other-exploits
@(call set Args=%%*,) || (
    echo ERROR: MALFORMED_COMMAND_LINE
    exit /b
)>&2
@(
    set @brWorker.e0.v0="%@brWorker::brParams:=:0#0:%" %Args%
    set @brWorker.e1.v0="%@brWorker::brParams:=:1#0:%" %Args%
    set @brWorker.e0.v1="%@brWorker.DelayProtected::brParams:=:0#1:%" %Args%
    set @brWorker.e1.v1="%@brWorker.DelayProtected::brParams:=:1#1:%" %Args%
)
@(
    %@ReturnToCaller%
    if "^!^"=="^!" (
        REM DelayedExpansion: ON
        if "^!"=="!" (
            REM Command line context
            (set /a 0)>nul && (%@brWorker.e1.v1%) || %@brWorker.e0.v1%
        ) else (
            REM Batch context
            >&9 echo ERROR: INVALID_CALLER
        )
    ) else (
        REM DelayedExpansion: OFF
        setlocal EnableDelayedExpansion
        if not "^!^"=="^!" (
            REM Command line context
            (set /a 0)>nul && (%@brWorker.e1.v0%) || %@brWorker.e0.v0%
        ) else (
            endlocal
            REM Batch context
            >&9 echo ERROR: INVALID_CALLER
        )
    )
)9>&2 2>nul
>&2 @echo ASSERT: UNREACHABLE_CODE
()
:: ---------------------- Bootstrapper ----------------------/


:: /---------------------- Worker ----------------------
:brWorker // Branch
:: It's OK to use 'ECHO OFF' here.
@echo off
set Args=%*
setlocal EnableDelayedExpansion
:: Basic Args Parsing
set "//Help="
set "//State="
if "!Args!"=="," (
    set "//State=1"
) else if "!Args!" NEQ "!Args:*/?=!" (
    set "//Help=1"
) else (
    set "Args=!Args:~0,-1!"
)
if defined //Help call :DisplayHelp & exit /b
if defined //State (
    for /F "tokens=1,2 delims=#" %%A in ("%branchParams%") do set /a "curExt#=%%A, curDex#=%%B"
    set "curExt=Extensions:"
    set "curDex=DelayedExpansion:"
    if !curExt#! EQU 0 (set "curExt=!curExt! OFF") else set "curExt=!curExt! ON"
    if !curDex#! EQU 0 (set "curDex=!curDex! OFF") else set "curDex=!curDex! ON"
    echo Command line state:
    echo !curExt!
    echo !curDex!
    exit /b
)
(
    endlocal & endlocal
    REM This will become the permanent setlocal (a memory leak)
    setlocal %Args% && (
        echo The operation was successfull.
    ) || (setlocal EnableExtensions & exit /b)
)2>&9
:: This one will be discarded
setlocal
echo/
:: Deliberate Syntax Error - DO NOT REMOVE THE NEXT LINE
()
:: ---------------------- Worker ----------------------/

:DisplayHelp  // Function
setlocal DisableDelayedExpansion
for /F "tokens=1* delims=:=" %%G in (
    '@"%SystemRoot%\System32\findstr.exe" /NRC:"^::=::" "%~f0"'
    ) do @echo(%%H
exit /b
