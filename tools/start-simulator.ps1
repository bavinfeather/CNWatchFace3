param(
    [ValidateSet('fenix7s','fenix7spro','fenix7','fenix7pro','fenix7pronowifi','fenix8solar47mm','fenix9prosolar47mm','fr255','fr255m','fr955','fenix7x','fenix7xpro','fenix7xpronowifi','fenix8solar51mm','fenix9prosolar51mm','enduro3','approachs50','approachs7042mm','descentg2','descentmk343mm','epix2pro42mm','fr165','fr165m','fr170','fr170m','fr57042mm','fr70','instinct3amoled45mm','instinctcrossoveramoled','marq2','marq2aviator','venu3s','venu441mm','vivoactive5','vivoactive6','d2airx10','d2mach1','epix2','epix2pro47mm','fenix843mm','fenix943mm','fenix9pro43mm','fenixe','fr265','instinct3amoled50mm','venu2','venu2plus','approachs7047mm','d2mach2','d2mach2pro','descentmk351mm','epix2pro51mm','fenix847mm','fenix8pro47mm','fenix947mm','fenix9pro47mm','fr57047mm','fr965','fr970','venu3','venu445mm','fenix9pro51mm','fr265s')]
    [string]$Device = 'enduro3',
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'

$sdkConfig = Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg'
if (-not (Test-Path -LiteralPath $sdkConfig)) {
    throw "Connect IQ current SDK file was not found: $sdkConfig"
}

$sdk = (Get-Content -LiteralPath $sdkConfig -Raw).Trim().Trim('"')
$simulator = Join-Path $sdk 'bin\simulator.exe'
if (-not (Test-Path -LiteralPath $simulator)) {
    throw "Connect IQ simulator was not found in the current SDK: $simulator"
}

# The VS Code extension names the running app SOL-<DEVICE>, while Monkey C
# emits the settings schema with the project name. Keep both names in sync so
# App Settings Editor always opens the schema from the latest build.
$projectRoot = Split-Path $PSScriptRoot
$simulatorSettings = Join-Path $env:TEMP 'com.garmin.connectiq\GARMIN\Settings'
New-Item -ItemType Directory -Force -Path $simulatorSettings | Out-Null
$targets = @('fenix7s','fenix7spro','fenix7','fenix7pro','fenix7pronowifi','fenix8solar47mm','fenix9prosolar47mm','fr255','fr255m','fr955','fenix7x','fenix7xpro','fenix7xpronowifi','fenix8solar51mm','fenix9prosolar51mm','enduro3','approachs50','approachs7042mm','descentg2','descentmk343mm','epix2pro42mm','fr165','fr165m','fr170','fr170m','fr57042mm','fr70','instinct3amoled45mm','instinctcrossoveramoled','marq2','marq2aviator','venu3s','venu441mm','vivoactive5','vivoactive6','d2airx10','d2mach1','epix2','epix2pro47mm','fenix843mm','fenix943mm','fenix9pro43mm','fenixe','fr265','instinct3amoled50mm','venu2','venu2plus','approachs7047mm','d2mach2','d2mach2pro','descentmk351mm','epix2pro51mm','fenix847mm','fenix8pro47mm','fenix947mm','fenix9pro47mm','fr57047mm','fr965','fr970','venu3','venu445mm','fenix9pro51mm','fr265s')
foreach ($target in $targets) {
    $schema = Join-Path $projectRoot "bin\CNWatchFace3-$target-settings.json"
    if (Test-Path -LiteralPath $schema) {
        $alias = "SOL-$($target.ToUpperInvariant())-settings.json"
        Copy-Item -LiteralPath $schema -Destination (Join-Path $projectRoot "bin\$alias") -Force
        Copy-Item -LiteralPath $schema -Destination (Join-Path $simulatorSettings $alias) -Force
    }
}

$runningSimulator = Get-Process -Name simulator -ErrorAction SilentlyContinue
if ($Restart -and $runningSimulator) {
    $runningSimulator | Stop-Process -Force
    $runningSimulator | Wait-Process -ErrorAction SilentlyContinue
    $runningSimulator = $null
}
if (-not $runningSimulator) {
    Start-Process -FilePath $simulator -WorkingDirectory (Split-Path $simulator) | Out-Null
}

function Test-SimulatorReady {
    foreach ($port in 1234..1238) {
        $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if (-not $listening) {
            continue
        }

        $client = $null
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            $client.ReceiveTimeout = 500
            $client.SendTimeout = 500
            $client.Connect('127.0.0.1', $port)
            $stream = $client.GetStream()
            $buffer = New-Object byte[] 512
            $waitUntil = (Get-Date).AddMilliseconds(500)
            while (-not $stream.DataAvailable -and (Get-Date) -lt $waitUntil) {
                Start-Sleep -Milliseconds 50
            }
            if ($stream.DataAvailable) {
                $read = $stream.Read($buffer, 0, $buffer.Length)
                $greeting = [Text.Encoding]::ASCII.GetString($buffer, 0, $read)
                if ($greeting.Contains('A garmin device')) {
                    return $true
                }
            }
        } catch {
            # The simulator can accept a socket before its greeting is ready.
        } finally {
            if ($client) {
                $client.Dispose()
            }
        }
    }
    return $false
}

# Wait until the simulator's command port has completed its greeting before
# the Monkey C extension tries to send the PRG. The extension uses ports 1234 through 1238.
$deadline = (Get-Date).AddSeconds(30)
do {
    if (Test-SimulatorReady) {
        Write-Output "Connect IQ simulator is ready for $Device."
        exit 0
    }
    Start-Sleep -Milliseconds 500
} while ((Get-Date) -lt $deadline)

throw 'Connect IQ simulator started but did not open ports 1234-1238 within 30 seconds.'
