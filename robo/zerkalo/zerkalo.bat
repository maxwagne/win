@echo off
set locale

echo ______________________________________________________________________________________________________________________

echo   8888888888',8888' 8 8888888888   8 888888888o.   8 8888     ,88'          .8.          8 8888         ,o888888o.
echo         ,8',8888'  8 8888         8 8888    `88.  8 8888    ,88'          .888.         8 8888      . 8888     `88.
echo        ,8',8888'   8 8888         8 8888     `88  8 8888   ,88'          :88888.        8 8888     ,8 8888       `8b
echo       ,8',8888'    8 8888         8 8888     ,88  8 8888  ,88'          . `88888.       8 8888     88 8888        `8b
echo      ,8',8888'     8 888888888888 8 8888.   ,88'  8 8888 ,88'          .8. `88888.      8 8888     88 8888         88
echo     ,8',8888'      8 8888         8 888888888P'   8 8888 88'          .8`8. `88888.     8 8888     88 8888         88
echo   ,8',8888'        8 8888         8 8888 `8b.     8 8888 `Y8.       .8'   `8. `88888.   8 8888     `8 8888       ,8P
echo  ,8',8888'         8 8888         8 8888   `8b.   8 8888   `Y8.    .888888888. `88888.  8 8888      ` 8888     ,88'
echo ,8',8888888888888  8 888888888888 8 8888     `88. 8 8888     `Y8. .8'       `8. `88888. 8 888888888888 `8888888P'
echo ______________________________________________________________________________________________________________________
echo			   ####                     ######                          
echo			  ## ##                       ##                            
echo			  ## ##    #####   #####      ##     ####   ##   ## ##   ## 
echo			  ## ##   ##  ##  ##  ##      ##        ##  ##   ## ##  ### 
echo			  ## ##   ##  ##   #####      ##     #####  ####### ## # ## 
echo			 #######  ##  ##  ##  ##      ##    ##  ##  ##   ## ###  ## 
echo			 ##   ## ##   ## ##   ##      ##     ###### ##   ## ##   ## 
echo ______________________________________________________________________________________________________________________

pause


REM Extrahieren des Laufwerksbuchstabens, auf dem sich die Batch-Datei befindet
for %%P in ("%~dp0") do set "drive=%%~dP"

REM Pfad zur Textdatei für die gespeicherten Konfigurationsdaten
set "configFile=%~dp0config.txt"

REM Laden der gespeicherten Konfigurationsdaten aus der Textdatei
if exist "%configFile%" (
    for /f "usebackq tokens=1,* delims=: " %%A in ("%configFile%") do (
        if "%%A"=="Source" set "savedSource=%%B"
        if "%%A"=="DestinationSubfolder" set "savedDestinationSubfolder=%%B"
    )
) else (
    set "savedSource="
    set "savedDestinationSubfolder="
)

REM Eingabeaufforderung für den Quellordner
set /p "source=Quellordner [%savedSource%]: "
if "%source%"=="" set "source=%savedSource%"

REM Eingabeaufforderung für den Unterordner des Zielordners mit gespeichertem Wert als Vorschlag
set "destinationSubfolder=%savedDestinationSubfolder%"
set /p "inputDestinationSubfolder=Unterordner des Zielordners [%destinationSubfolder%]: "
echo.

REM Leerzeile für bessere Trennung
echo.

if not "%inputDestinationSubfolder%"=="" set "destinationSubfolder=%inputDestinationSubfolder%"

REM Erstellen des vollen Zielordnerpfads
set "destination=%drive%\%destinationSubfolder%"

REM Setzen des Zielordners
set "destination=%drive%\%destinationSubfolder%"

REM Prüfen, ob der ausgewählte Zielordner der gleiche wie der Quellordner ist
if "%destination%"=="%source%" (
    echo ACHTUNG: Der ausgewaehlte Zielordner ist der gleiche wie der Quellordner!
    echo Der Vorgang wird abgebrochen.
    pause
    exit /b
)

REM Anzeigen der Quell- und Zielpfade zur Bestätigung
echo Quellordner: %source%
echo Zielordner: %destination%
echo.
echo Druecken Sie eine beliebige Taste, um den Vorgang fortzusetzen...
pause > nul

REM Ausführen des Robocopy-MIR-Befehls
robocopy "%source%" "%destination%" /MIR /ZB /COPYALL /R:2 /W:5

REM Speichern der Konfigurationsdaten in der Textdatei
(
    echo Source: %source%
    echo DestinationSubfolder: %destinationSubfolder%
) > "%configFile%"

pause
endlocal