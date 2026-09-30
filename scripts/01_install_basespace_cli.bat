@echo off
:: ============================================================================
:: BaseSpace Sequence Hub CLI - Installation, Authentication and FASTQ Download
::
:: Workflow implemented and executed by:
:: Wanessa dos Santos
::
:: Purpose:
::   1. Configure the Windows terminal for UTF-8
::   2. Access the local working directory
::   3. Verify or download the official Illumina BaseSpace CLI
::   4. Authenticate the BaseSpace account
::   5. Create the local BaseSpace download directory
::   6. Download the original FASTQ files before any requeue/reprocessing
::
:: This script documents the exact workflow used for the sequencing run
:: recovery described in this repository.
:: ============================================================================

:: Configure terminal encoding to UTF-8
chcp 65001 > nul

title BaseSpace CLI Automation - Illumina - Wanessa

echo ===============================================================
echo           BASESPACE CLI DOWNLOAD WORKFLOW
echo ===============================================================
echo.


:: ============================================================================
:: STEP 1 - ACCESS WORKING DIRECTORY
:: ============================================================================

echo [STEP 1] Accessing local working directory...

E:
cd "E:\Users\Wanessa"

echo Current directory:
echo %cd%
echo.


:: ============================================================================
:: STEP 2 - CHECK / INSTALL BASESPACE CLI
:: ============================================================================

echo [STEP 2] Checking BaseSpace Sequence Hub CLI...

if not exist "bs.exe" (

    echo.
    echo bs.exe was not found in the working directory.
    echo Downloading the official Illumina BaseSpace CLI for Windows amd64...
    echo.

    curl -L "https://launch.basespace.illumina.com/CLI/latest/amd64-windows/bs.exe" -o bs.exe

    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to download bs.exe.
        echo Check the internet connection and try again.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo BaseSpace CLI downloaded successfully.

) else (

    echo.
    echo bs.exe already exists in the working directory.
    echo Existing executable will be used.

)

echo.


:: ============================================================================
:: STEP 3 - VERIFY CLI
:: ============================================================================

echo [STEP 3] Verifying BaseSpace CLI...

bs.exe --help

if errorlevel 1 (
    echo.
    echo [ERROR] BaseSpace CLI could not be executed.
    pause
    exit /b 1
)

echo.


:: ============================================================================
:: STEP 4 - BASESPACE AUTHENTICATION
:: ============================================================================

echo [STEP 4] Starting BaseSpace authentication...
echo.
echo If this computer is already authenticated, the existing credentials
echo may be reused.
echo.
echo If an authorization URL is displayed:
echo   1. Copy the URL
echo   2. Open it in a web browser
echo   3. Log in to BaseSpace Sequence Hub
echo   4. Click Authorize
echo.

bs.exe auth

if errorlevel 1 (
    echo.
    echo [ERROR] BaseSpace authentication failed.
    pause
    exit /b 1
)

echo.


:: ============================================================================
:: STEP 5 - VERIFY AUTHENTICATED ACCOUNT
:: ============================================================================

echo [STEP 5] Checking authenticated BaseSpace account...

bs.exe whoami

if errorlevel 1 (
    echo.
    echo [ERROR] Could not verify the authenticated BaseSpace account.
    pause
    exit /b 1
)

echo.


:: ============================================================================
:: STEP 6 - CREATE LOCAL BASESPACE DIRECTORY
:: ============================================================================

echo [STEP 6] Configuring local BaseSpace directory...

if not exist "E:\BaseSpace" (

    mkdir "E:\BaseSpace"

    echo Directory created:
    echo E:\BaseSpace

) else (

    echo Directory already exists:
    echo E:\BaseSpace

)

echo.


:: ============================================================================
:: STEP 7 - DOWNLOAD ORIGINAL FASTQ FILES
:: ============================================================================
::
:: IMPORTANT:
:: These FASTQs correspond to the ORIGINAL demultiplexing.
::
:: They were downloaded BEFORE modifying the Sample Sheet or performing the
:: BCL Convert requeue so that the original data were preserved locally.
::
:: Original BaseSpace Project ID:
:: 519115698
::
:: Approximate total project size:
:: 124 GB
::
:: Only files ending in fastq.gz are requested.
::
:: The BaseSpace CLI downloader is incremental. If the connection is
:: interrupted, the same command can be executed again and already completed
:: downloads will not need to be downloaded again.
:: ============================================================================

echo [STEP 7] Downloading ORIGINAL FASTQ files...
echo.
echo BaseSpace Project ID: 519115698
echo Approximate project size: 124 GB
echo Destination: E:\BaseSpace
echo.
echo This download may take several hours.
echo Do not close this terminal while the transfer is running.
echo.

bs.exe download project -i 519115698 -o "E:\BaseSpace" --extension fastq.gz

if errorlevel 1 (

    echo.
    echo ===============================================================
    echo [WARNING] DOWNLOAD INTERRUPTED OR INCOMPLETE
    echo ===============================================================
    echo.
    echo The BaseSpace CLI supports incremental downloads.
    echo Run this script again to resume/check the transfer.
    echo.

    pause
    exit /b 1

)

echo.


:: ============================================================================
:: STEP 8 - FINAL STATUS
:: ============================================================================

echo ===============================================================
echo                 DOWNLOAD COMPLETED
echo ===============================================================
echo.
echo Original FASTQ files were downloaded from BaseSpace.
echo.
echo Local destination:
echo E:\BaseSpace
echo.
echo Workflow executed by:
echo Wanessa dos Santos
echo.
echo These original files were preserved before the BCL Convert
echo rescue/requeue procedure.
echo ===============================================================

pause
