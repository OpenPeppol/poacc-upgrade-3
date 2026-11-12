@echo off
setlocal

:: Get the directory of the script
set "PROJECT=%~dp0"
set "PROJECT=%PROJECT:~0,-1%"  :: Remove trailing backslash if any

:: Delete target folder if found
if exist "%PROJECT%\target" (
    docker run --rm -i -v "%PROJECT%:/src" alpine:3.11 rm -rf /src/target
)

:: Structure
docker run --rm -i -v "%PROJECT%:/src" -v "%PROJECT%\target:/target" difi/vefa-structure:0.6.1

:: Testing validation rules
docker run --rm -i -v "%PROJECT%:/src" phelger/vefa-validator:2.4.3 build -x -t -n eu.peppol.poacc.upgrade.v3 -a rules -target target/validator-test /src

:: Schematron
for %%s in ("%PROJECT%\rules\sch\*.sch") do (
    docker run --rm -i -v "%PROJECT%:/src" -v "%PROJECT%\target\schematron:/target" klakegg/schematron prepare /src/rules/sch/%%~nxs /target/%%~nxs
)

set "zipname=PEPPOLBIS-Upgrade-Schematron.zip"
set zip="%PROJECT%\target\site\files\PEPPOLBIS-Upgrade-Schematron.zip"
if exist %zip% (
    echo remove %zip%
    del %zip%
)

powershell -command "Compress-Archive -Path '%PROJECT%\target\schematron\*' -DestinationPath '%zip%' -Force"

::docker run --rm -i -v "%PROJECT%\target\site\files:/src" alpine:3.11 rm -rf /src/PEPPOLBIS-Upgrade-Schematron.zip
::docker run --rm -i -v "%PROJECT%\target\schematron:/src" -v "%PROJECT%\target\site\files:/target" -w /src kramos/alpine-zip -r /target/PEPPOLBIS-Upgrade-Schematron.zip .

:: Example files
set "zipname=PEPPOLBIS-Examples.zip"
set "zip=%PROJECT%\target\site\files\%zipname%"
if exist %zip% (
    echo remove %zip%
    del %zip%
)

powershell -command "Compress-Archive -Path '%PROJECT%/rules/examples/*' -DestinationPath '%zip%' -Force"
::docker run --rm -i -v "%PROJECT%\target\site\files:/src" alpine:3.11 rm -rf /src/PEPPOLBIS-Examples.zip
::docker run --rm -i -v "%PROJECT%\rules\examples:/src" -v "%PROJECT%\target\site\files:/target" -w /src kramos/alpine-zip -r /target/PEPPOLBIS-Examples.zip .

:: Guides
docker run --rm -i -v "%PROJECT%:/documents" -v "%PROJECT%\target:/target" difi/asciidoctor

:: Fix ownership (Windows doesn't use the same concept of user/group ownership, so this part is usually not necessary)
:: You can skip this part or just leave it for Unix-like environments using Docker.

endlocal

