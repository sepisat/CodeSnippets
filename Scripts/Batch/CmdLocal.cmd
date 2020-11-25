:: DO NOT USE @ECHO OFF/ON IN THIS BATCH FILE
:: It will alter the echo state of the command shell 
:: ---------------------- Help ----------------------
::=::CMDLOCAL
::=::A tool to change the state of CMD Extensions or Delayed Expansion at command line
::=::Usage:
::=::  CMDLOCAL [ EnableExtensions | DisableExtensions ] [ EnableDelayedExpansion | DisableDelayedExpansion ]
::=::
::=::Use at command line only.
:: ---------------------- Help ----------------------

:: ---------------------- Bootstrapper ----------------------
@setlocal EnableExtensions DisableDelayedExpansion
@(
    set "#f0=%~f0"
    set "processBranch=1"
)
@if "%~d0"=="\\" (
    set "tokens=2"
    if "%#f0:~0,4%"=="\\.\" (
        if "%#f0:~5,1%"==":" (
            set "tokens=3"
        ) else (
            set "processBranch=0"
        )
    )
) else set "tokens=3"
@(
    endlocal
    if %processBranch% NEQ 0 for /F "tokens=%tokens% delims=:" %%L in ("%~0") do @goto %%L
)

:: ---------------------- Startup Branch ----------------------
@setlocal EnableExtensions DisableDelayedExpansion
@(
    set "@ReturnToCaller=(goto)"
    set  @CmdSetLocal.Work="%~dp0:CmdSetLocal.Work:\..\%~nx0"
    set  @FindStr=@"%SystemRoot%\System32\findstr.exe"
)
:: Protect against malformed arguments by using (call ... %%*)
:: (%%*,): Using ',' to protect against a less known CMD bug (triggers if the last character of %%* is an unescaped caret '^')
:: https://web.archive.org/web/20170814061717/https://stackoverflow.com/questions/23284131/cmd-exe-parsing-bug-leads-to-other-exploits
@(call set Args=%%*,)
@setlocal EnableDelayedExpansion
:: Basic Args Parsing
@set "//Help="
@if "!Args!"=="," (
    set "//Help=1"
) else if "!Args!" NEQ "!Args:*/?=!" (
    set "//Help=1"
) else (
    set "Args=!Args:~0,-1!"
)
@if defined //Help (
    call :DisplayHelp
    exit /b
)

@set @CmdSetLocal.Work=!@CmdSetLocal.Work! !Args!
@(
    %@ReturnToCaller%
    %@CmdSetLocal.Work%
)9>&2 8>&1 1>nul 2>&1

>&2 @echo ASSERT: UNREACHABLE_CODE
()

:CmdSetLocal.Work // Branch
setlocal EnableExtensions
(
    endlocal
    REM This will become the permanent setlocal (Memory leak!)
    2>&9 setlocal %* || (setlocal EnableExtensions & exit /b)
)
:: This one will be discarded
setlocal
>&8 echo/
:: Deliberate Syntax Error - DO NOT REMOVE THE NEXT LINE
()

:DisplayHelp  // Function
@(
    setlocal DisableDelayedExpansion
    for /F "tokens=1* delims=:=" %%G in ('%@FindStr% /NRC:"^::=::" "%~f0"') do @echo(%%H
    exit /b
)
