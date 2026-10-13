param([ValidateSet('fenix7s','fenix7spro','fenix7','fenix7pro','fenix7pronowifi','fenix8solar47mm','fenix9prosolar47mm','fr255','fr255m','fr955','fenix7x','fenix7xpro','fenix7xpronowifi','fenix8solar51mm','fenix9prosolar51mm','enduro3','approachs50','approachs7042mm','descentg2','descentmk343mm','epix2pro42mm','fr165','fr165m','fr170','fr170m','fr57042mm','fr70','instinct3amoled45mm','instinctcrossoveramoled','marq2','marq2aviator','venu3s','venu441mm','vivoactive5','vivoactive6','d2airx10','d2mach1','epix2','epix2pro47mm','fenix843mm','fenix943mm','fenix9pro43mm','fenixe','fr265','instinct3amoled50mm','venu2','venu2plus','approachs7047mm','d2mach2','d2mach2pro','descentmk351mm','epix2pro51mm','fenix847mm','fenix8pro47mm','fenix947mm','fenix9pro47mm','fr57047mm','fr965','fr970','venu3','venu445mm','fenix9pro51mm','fr265s')][string]$Device='enduro3')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$sdk=(Get-Content "$env:APPDATA/Garmin/ConnectIQ/current-sdk.cfg").Trim()
$program=Join-Path $project 'bin/CNWatchFace3.prg'
$settings=Join-Path $project 'bin/CNWatchFace3-settings.json'
$key=Join-Path (Split-Path $project -Parent) 'CNWatchFace/keys/CNWatchFace-release.der'
& "$sdk/bin/monkeyc.bat" -f "$project/monkey.jungle" -d $Device -o $program -y $key
if($LASTEXITCODE -ne 0){throw 'Build failed'}
if(!(Test-Path -LiteralPath $settings)){throw 'Missing generated settings JSON'}
$simSettings=Join-Path $env:TEMP 'com.garmin.connectiq/GARMIN/Settings'
New-Item -ItemType Directory -Path $simSettings -Force | Out-Null
Copy-Item -LiteralPath $settings -Destination (Join-Path $simSettings 'CNWATCHFACE3-settings.json')
& (Join-Path $PSScriptRoot 'start-simulator.ps1') -Device $Device
& "$sdk/bin/monkeydo.bat" $program $Device
