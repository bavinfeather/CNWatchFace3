$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$source = Get-Content (Join-Path $project 'source/SolView.mc') -Raw -Encoding UTF8
$required = [regex]::Matches($source, '[\u4e00-\u9fff]') | ForEach-Object Value | Sort-Object -Unique
$fonts = @(Get-ChildItem (Join-Path $project 'resources-*\fonts\Cjk*.fnt')) + @(Get-ChildItem (Join-Path $project 'resources-instinct3-*\fonts\InstinctCjkData.fnt'))
if ($fonts.Count -ne 18) { throw 'Expected 18 Chinese font atlases.' }
foreach ($font in $fonts) {
    $content = Get-Content $font.FullName -Raw
    foreach ($character in $required) {
        if ($content -notmatch ('char id=' + [int][char]$character + '\s')) {
            throw "Missing character $character in $($font.FullName)"
        }
    }
    foreach ($code in 32..126) {
        if ($content -notmatch ('char id=' + $code + '\s')) {
            throw "Missing ASCII symbol $code in $($font.FullName)"
        }
    }
    $ids = @([regex]::Matches($content, 'char id=(\d+)') | ForEach-Object { $_.Groups[1].Value })
    if (@($ids | Sort-Object -Unique).Count -ne $ids.Count) { throw "Duplicate glyphs: $($font.Name)" }
}
[xml]$settings = Get-Content (Join-Path $project 'resources/settings/settings.xml')
[xml]$properties = Get-Content (Join-Path $project 'resources/settings/properties.xml')
foreach ($i in 1..4) {
    $row = $settings.settings.setting | Where-Object propertyKey -eq "@Properties.Field$i"
    $values = @($row.settingConfig.listEntry | ForEach-Object { [int]$_.value })
    if (($values -join ',') -ne ((0..55) -join ',')) { throw "Incomplete Field$i options" }
}
$keys = @('Background','Sky','SkyThird','Sun','Dots','Ridge','Foreground','TimeColor','SecondsColor','DateColor','LabelColor','ValueColor','CustomColor','ArcColor','ProgressValueColor','EventColor')
$sharedPalette = $null
foreach ($key in $keys) {
    $row = $settings.settings.setting | Where-Object propertyKey -eq "@Properties.$key"
    $property = $properties.properties.property | Where-Object id -eq $key
    $values = @($row.settingConfig.listEntry | ForEach-Object { [int]$_.value })
    if ($values.Count -ne 25 -or $values -notcontains [int]$property.InnerText -or @($values | Sort-Object -Unique).Count -ne $values.Count) {
        throw "Invalid palette size, default or duplicate colors: $key"
    }
    if ($null -eq $sharedPalette) { $sharedPalette = $values -join ',' }
    if (($values -join ',') -ne $sharedPalette) { throw "Inconsistent palette: $key" }
}
foreach ($key in @('SkyColorCount','SkyBoundary1','SkyBoundary2')) {
    $row = $settings.settings.setting | Where-Object propertyKey -eq "@Properties.$key"
    $property = $properties.properties.property | Where-Object id -eq $key
    $values = @($row.settingConfig.listEntry | ForEach-Object { [int]$_.value })
    if ($values -notcontains [int]$property.InnerText) { throw "Sky default missing from choices: $key" }
    if ($key -eq 'SkyColorCount' -and ($values -join ',') -ne '1,2,3') { throw 'Invalid sky color count choices' }
    if ($key -ne 'SkyColorCount' -and @($values | Where-Object { $_ -lt 0 -or $_ -gt 95 }).Count) { throw "Invalid sky boundary: $key" }
}
[xml]$amoledSettings = Get-Content (Join-Path $project 'resources-amoled/settings/settings.xml')
foreach ($key in $keys) {
    $row = $amoledSettings.settings.setting | Where-Object propertyKey -eq "@Properties.$key"
    $values = @($row.settingConfig.listEntry | ForEach-Object { [int]$_.value })
    $baseValues = @($sharedPalette.Split(',') | ForEach-Object { [int]$_ })
    if ($values.Count -ne 41 -or ($values[0..12] -join ',') -ne ($baseValues[0..12] -join ',') -or ($values[29..40] -join ',') -ne ($baseValues[13..24] -join ',') -or @($values | Sort-Object -Unique).Count -ne 41) {
        throw "Invalid AMOLED palette or changed base colors: $key"
    }
}
Write-Output "PASS: $($required.Count) Chinese characters + 95 ASCII characters, 18 atlases, 4 field lists, 16 color settings (MIP 25 / AMOLED 41), nuanced colors first, native colors last."
