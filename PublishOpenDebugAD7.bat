@echo off
setlocal

rem Working dirctory to return to
set "__InitialCWD=%CD%"

rem Location of the script
set "__ScriptDirectory=%~dp0"

rem RuntimeID to publish
set "__RuntimeID=win-x64"

rem Configuration of build
set "__Configuration=Debug"

rem OutputFolder
set "__OutputFolder="

:parse_args
if "%~1"=="" goto after_parse_args
if /i "%~1"=="-c" (
    set "__Configuration=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-r" (
    set "__RuntimeID=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-o" (
    set "__OutputFolder=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-h" (
    goto print_help
)
shift
goto parse_args

:after_parse_args

echo Info: Using Configuration '%__Configuration%'
echo Info: Using Runtime ID '%__RuntimeID%'

set "__DotnetPublishArgs=-c %__Configuration% -r %__RuntimeID% --self-contained"

if not "%__OutputFolder%"=="" (
    set "__DotnetPublishArgs=%__DotnetPublishArgs% -o "%__OutputFolder%""
) else (
    set "__OutputFolder=%__ScriptDirectory%bin\%__Configuration%\vscode\%__RuntimeID%\publish"
)

echo ##[command] dotnet build "%__ScriptDirectory%src\MIDebugEngine.sln" -c %__Configuration%
dotnet build "%__ScriptDirectory%src\MIDebugEngine.sln" -c %__Configuration%
if %errorlevel% neq 0 (
    echo Error: dotnet build failed
    exit /b 1
)

echo ##[command] dotnet publish "%__ScriptDirectory%src\OpenDebugAD7\OpenDebugAD7.csproj" %__DotnetPublishArgs%
dotnet publish "%__ScriptDirectory%src\OpenDebugAD7\OpenDebugAD7.csproj" %__DotnetPublishArgs%
if %errorlevel% neq 0 (
    echo Error: dotnet publish failed
    exit /b 1
)

rem Delete pdb files from publish output
del /S /Q "%__OutputFolder%\*.pdb"

echo ##[command] dotnet publish "%__ScriptDirectory%src\WindowsDebugLauncher\WindowsDebugLauncher.csproj" %__DotnetPublishArgs%
dotnet publish "%__ScriptDirectory%src\WindowsDebugLauncher\WindowsDebugLauncher.csproj" %__DotnetPublishArgs%
if %errorlevel% neq 0 (
    echo Error: dotnet publish WindowsDebugLauncher failed
    exit /b 1
)

rem Delete pdb files again if WindowsDebugLauncher created any
del /S /Q "%__OutputFolder%\*.pdb"

echo ##[command] copy "%__ScriptDirectory%bin\%__Configuration%\Microsoft.MIDebugEngine.dll" "%__OutputFolder%\"
copy /Y "%__ScriptDirectory%bin\%__Configuration%\Microsoft.MIDebugEngine.dll" "%__OutputFolder%\"
if %errorlevel% neq 0 (
    echo Error: copy Microsoft.MIDebugEngine.dll failed
    exit /b 1
)

echo ##[command] copy "%__ScriptDirectory%bin\%__Configuration%\Microsoft.MICore.dll" "%__OutputFolder%\"
copy /Y "%__ScriptDirectory%bin\%__Configuration%\Microsoft.MICore.dll" "%__OutputFolder%\"
if %errorlevel% neq 0 (
    echo Error: copy Microsoft.MICore.dll failed
    exit /b 1
)

exit /b 0

:print_help
echo PublishOpenDebugAD7.bat [-h] [-c C] [-r R] [-o O]
echo.
echo This script publishes OpenDebugAD7
echo -h    Prints usage information.
echo -c C  The configuration to publish OpenDebugAD7. Defaults to Debug.
echo -r R  The RuntimeID to publish OpenDebugAD7. Defaults to win-x64.
echo -o O  Folder to output the publish. Defaults to the `dotnet publish` folder.
exit /b 1
