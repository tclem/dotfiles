#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesRoot = Split-Path -Parent $PSScriptRoot
$TestRoot = Join-Path ([IO.Path]::GetTempPath()) "sync-copilot-extensions-$([Guid]::NewGuid().ToString('N'))"
$FixtureRepository = Join-Path $TestRoot "repository"
$Manifest = Join-Path $TestRoot "external-extensions"
$FakeBin = Join-Path $TestRoot "bin"
$CopilotHome = Join-Path $TestRoot "copilot"
$CacheRoot = Join-Path $TestRoot "cache"
$ProjectsRoot = Join-Path $TestRoot "projects"

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: git $($args -join ' ')"
    }
}

function Assert-InstalledTree([string]$Expected, [string]$Installed) {
    $expectedEntries = @(Get-ChildItem -LiteralPath $Expected -Force | Sort-Object Name)
    $installedEntries = @(Get-ChildItem -LiteralPath $Installed -Force | Sort-Object Name)
    if (($expectedEntries.Name -join "`n") -ne ($installedEntries.Name -join "`n")) {
        throw "Installed top-level entries differ from git archive"
    }

    foreach ($expectedFile in Get-ChildItem -LiteralPath $Expected -File -Recurse -Force) {
        $relative = [IO.Path]::GetRelativePath($Expected, $expectedFile.FullName)
        $installedFile = Join-Path $Installed $relative
        if (-not (Test-Path -LiteralPath $installedFile -PathType Leaf)) {
            throw "Installed file is missing: $relative"
        }
        if ((Get-FileHash $expectedFile.FullName).Hash -ne (Get-FileHash $installedFile).Hash) {
            throw "Installed file differs from git archive: $relative"
        }
    }
}

New-Item -ItemType Directory -Path (
    Join-Path $FixtureRepository "extensions\sample\lib"
), $FakeBin, $CopilotHome, $CacheRoot, $ProjectsRoot -Force | Out-Null

try {
    Set-Content -LiteralPath (
        Join-Path $FixtureRepository "extensions\sample\extension.mjs"
    ) -Value 'export const fixture = "pinned";' -Encoding utf8
    Set-Content -LiteralPath (
        Join-Path $FixtureRepository "extensions\sample\lib\value.txt"
    ) -Value "nested fixture" -Encoding utf8
    Invoke-Git -C $FixtureRepository init --quiet --initial-branch=main
    Invoke-Git -C $FixtureRepository config user.name Fixture
    Invoke-Git -C $FixtureRepository config user.email fixture@example.com
    Invoke-Git -C $FixtureRepository config core.autocrlf false
    Invoke-Git -C $FixtureRepository add .
    $linkTarget = Join-Path $TestRoot "link-target"
    [IO.File]::WriteAllText($linkTarget, "lib/value.txt")
    $linkBlob = (& git -C $FixtureRepository hash-object -w $linkTarget).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create fixture symlink blob"
    }
    Invoke-Git -C $FixtureRepository update-index `
        --add --cacheinfo "120000,$linkBlob,extensions/sample/link.txt"
    Invoke-Git -C $FixtureRepository commit --quiet -m "Add fixture extension"
    $commit = (& git -C $FixtureRepository rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Could not resolve fixture commit"
    }

    @'
@echo off
if "%1"=="repo" if "%2"=="clone" (
  git clone --quiet "%FIXTURE_REPOSITORY%" "%4"
  exit /b %ERRORLEVEL%
)
exit /b 1
'@ | Set-Content -LiteralPath (Join-Path $FakeBin "gh.cmd") -Encoding ascii

    Set-Content -LiteralPath $Manifest `
        -Value "fixture/repo@$commit  extensions/sample  sample" `
        -Encoding utf8
    $previousPath = $env:PATH
    $previousFixtureRepository = $env:FIXTURE_REPOSITORY
    $env:PATH = "$FakeBin;$previousPath"
    $env:FIXTURE_REPOSITORY = $FixtureRepository
    try {
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null

        $clone = Join-Path $CacheRoot "fixture\repo"
        $installed = Join-Path $CopilotHome "extensions\sample"
        Set-Content -LiteralPath (
            Join-Path $clone "extensions\sample\extension.mjs"
        ) -Value "dirty tracked checkout" -Encoding utf8
        Set-Content -LiteralPath (
            Join-Path $clone "extensions\sample\drift.txt"
        ) -Value "dirty untracked checkout" -Encoding utf8

        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null

        $expected = Join-Path $TestRoot "expected"
        $archive = Join-Path $TestRoot "expected.tar"
        New-Item -ItemType Directory -Path $expected | Out-Null
        Invoke-Git -c core.autocrlf=false -c core.eol=lf -C $FixtureRepository `
            archive --format=tar "--output=$archive" "${commit}:extensions/sample"
        & tar -xf $archive -C $expected
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract expected fixture archive"
        }
        Assert-InstalledTree $expected $installed
        if (Test-Path -LiteralPath (Join-Path $installed "drift.txt")) {
            throw "Installed extension contains untracked checkout drift"
        }

        $materialized = Join-Path $CacheRoot ".materialized\fixture\repo\sample"
        $materializedLink = Get-Item -LiteralPath (
            Join-Path $materialized "link.txt"
        ) -Force
        if ($materializedLink.LinkType -ne "SymbolicLink") {
            throw "Materialized extension did not preserve the archived symlink"
        }
        Move-Item -LiteralPath $materialized -Destination (
            Join-Path (Split-Path -Parent $materialized) ".sample.backup"
        )
        Set-Content -LiteralPath $Manifest `
            -Value "fixture/repo@$commit  extensions/missing  sample" `
            -Encoding utf8
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null
        Assert-InstalledTree $expected $installed
    } finally {
        $env:PATH = $previousPath
        $env:FIXTURE_REPOSITORY = $previousFixtureRepository
    }

    Write-Output "PowerShell external extension cache tests passed"
} finally {
    Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
