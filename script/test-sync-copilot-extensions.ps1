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

    $expectedTree = @(Get-ChildItem -LiteralPath $Expected -Recurse -Force)
    foreach ($expectedFile in $expectedTree | Where-Object {
        -not $_.PSIsContainer -and [string]::IsNullOrEmpty($_.LinkType)
    }) {
        $relative = [IO.Path]::GetRelativePath($Expected, $expectedFile.FullName)
        $installedFile = Join-Path $Installed $relative
        if (-not (Test-Path -LiteralPath $installedFile -PathType Leaf)) {
            throw "Installed file is missing: $relative"
        }
        if ((Get-FileHash $expectedFile.FullName).Hash -ne (Get-FileHash $installedFile).Hash) {
            throw "Installed file differs from git archive: $relative"
        }
    }

    foreach ($expectedLink in $expectedTree | Where-Object {
        -not [string]::IsNullOrEmpty($_.LinkType)
    }) {
        $relative = [IO.Path]::GetRelativePath($Expected, $expectedLink.FullName)
        $installedLink = Get-Item -LiteralPath (Join-Path $Installed $relative) -Force
        $expectedTarget = $expectedLink.ResolveLinkTarget($true)
        $installedTarget = $installedLink.ResolveLinkTarget($true)
        $expectedDirectory = $expectedTarget -is [IO.DirectoryInfo]
        $installedDirectory = $installedTarget -is [IO.DirectoryInfo]
        if ($null -eq $expectedTarget -or $null -eq $installedTarget -or
            $expectedDirectory -ne $installedDirectory) {
            throw "Installed link target differs from git archive: $relative"
        }
        if (-not $expectedDirectory -and
            (Get-FileHash $expectedTarget.FullName).Hash -ne
                (Get-FileHash $installedTarget.FullName).Hash) {
            throw "Installed linked file differs from git archive: $relative"
        }
    }
}

function ConvertTo-BashPath([string]$Path) {
    if (-not $IsWindows) {
        return $Path
    }
    $escaped = $Path.Replace("'", "'\''")
    $converted = & bash -c "cygpath -u '$escaped'"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not convert path for Bash: $Path"
    }
    return $converted.Trim()
}

function Start-SyncProcess(
    [ValidateSet("bash", "powershell")]
    [string]$Kind,
    [string]$Name,
    [string]$SharedCopilotHome,
    [string]$SharedCacheRoot,
    [string]$SharedProjectsRoot,
    [double]$HoldSeconds = 0,
    [int]$TimeoutSeconds = 30,
    [double]$CloneDelaySeconds = 0,
    [string]$LockRootBarrier = "",
    [bool]$UseDefaultCache = $false
) {
    $stdout = Join-Path $TestRoot "$Name.stdout"
    $stderr = Join-Path $TestRoot "$Name.stderr"
    if ($Kind -eq "powershell") {
        $info = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
        $arguments = [Collections.Generic.List[string]]::new()
        foreach ($argument in @(
            "-NoLogo", "-NoProfile", "-File",
            (Join-Path $DotfilesRoot "script\sync-copilot.ps1"),
            "install",
            "-DotfilesRoot", $DotfilesRoot,
            "-CopilotHome", $SharedCopilotHome,
            "-ProjectsRoot", $SharedProjectsRoot,
            "-ExternalExtensionsFile", $Manifest
        )) {
            $arguments.Add($argument)
        }
        if (-not $UseDefaultCache) {
            $arguments.Add("-ExternalCacheRoot")
            $arguments.Add($SharedCacheRoot)
        }
        foreach ($argument in $arguments) {
            [void]$info.ArgumentList.Add($argument)
        }
        $info.Environment["PATH"] = "$FakeBin$([IO.Path]::PathSeparator)$previousPath"
        $info.Environment["FIXTURE_REPOSITORY"] = $FixtureRepository
    } else {
        $info = [Diagnostics.ProcessStartInfo]::new((Get-Command bash).Source)
        $bashRoot = ConvertTo-BashPath $DotfilesRoot
        if ((Split-Path -Leaf $SharedCopilotHome) -ne ".copilot") {
            throw "Shared Bash Copilot home must end in .copilot: $SharedCopilotHome"
        }
        $bashHome = ConvertTo-BashPath (Split-Path -Parent $SharedCopilotHome)
        $bashData = ConvertTo-BashPath (Split-Path -Parent $SharedCacheRoot)
        $bashProjects = ConvertTo-BashPath $SharedProjectsRoot
        $bashManifest = ConvertTo-BashPath $Manifest
        $bashFakeBin = ConvertTo-BashPath $FakeBin
        $bashFixture = ConvertTo-BashPath $FixtureRepository
        [void]$info.ArgumentList.Add("-c")
        $cacheEnvironment = if ($UseDefaultCache) { "" } else { "XDG_DATA_HOME='$bashData' " }
        [void]$info.ArgumentList.Add(
            "cd '$bashRoot' && PATH='$bashFakeBin':`"`$PATH`" " +
            "HOME='$bashHome' $cacheEnvironment" +
            "PROJECTS='$bashProjects' " +
            "EXTERNAL_EXTENSIONS_FILE='$bashManifest' FIXTURE_REPOSITORY='$bashFixture' " +
            "MSYS=winsymlinks:nativestrict bash script/sync-copilot install"
        )
    }

    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.Environment["COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS"] = $TimeoutSeconds.ToString()
    $info.Environment["COPILOT_EXTERNAL_EXTENSIONS_TEST_HOLD_LOCK_SECONDS"] = $HoldSeconds.ToString(
        [Globalization.CultureInfo]::InvariantCulture
    )
    $info.Environment["SYNC_TEST_CLONE_DELAY_SECONDS"] = $CloneDelaySeconds.ToString(
        [Globalization.CultureInfo]::InvariantCulture
    )
    if ($LockRootBarrier) {
        $info.Environment["COPILOT_EXTERNAL_EXTENSIONS_TEST_LOCK_ROOT_BARRIER"] = if ($Kind -eq "bash") {
            ConvertTo-BashPath $LockRootBarrier
        } else {
            $LockRootBarrier
        }
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    return @{
        Process = $process
        Stdout = $stdoutTask
        Stderr = $stderrTask
    }
}

function Wait-SyncProcess([hashtable]$Started, [int]$TimeoutSeconds = 30) {
    $process = $Started.Process
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id
        throw "Sync process timed out"
    }
    return @{
        ExitCode = $process.ExitCode
        Output = $Started.Stdout.GetAwaiter().GetResult()
        Error = $Started.Stderr.GetAwaiter().GetResult()
    }
}

function Release-LockBarrier([string]$Barrier, [int]$ExpectedProcesses) {
    $parent = Split-Path -Parent $Barrier
    $prefix = "$(Split-Path -Leaf $Barrier)."
    for ($attempt = 0; $attempt -lt 200; $attempt++) {
        $ready = @(
            Get-ChildItem -LiteralPath $parent -File -Force |
                Where-Object { $_.Name.StartsWith($prefix) -and $_.Name -ne "$($prefix)release" }
        )
        if ($ready.Count -eq $ExpectedProcesses) {
            [IO.File]::WriteAllText("$Barrier.release", "release")
            return
        }
        Start-Sleep -Milliseconds 50
    }
    throw "External extension lock barrier did not collect $ExpectedProcesses processes"
}

function Wait-ForLockTicket([string]$LockRoot) {
    for ($attempt = 0; $attempt -lt 200; $attempt++) {
        $ticket = Get-ChildItem -LiteralPath $LockRoot -Directory -Filter "ticket-*" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $ticket) {
            return $ticket
        }
        Start-Sleep -Milliseconds 50
    }
    throw "External extension lock ticket did not appear"
}

function New-ArchiveSafetyFixtureCommit([Collections.IDictionary]$Links) {
    Invoke-Git -C $FixtureRepository read-tree $commit
    foreach ($name in @(
        "absolute",
        "dotdot",
        "multihop",
        "dangling",
        "cycle",
        "self-nested",
        "self-directory",
        "directory"
    )) {
        $contentFile = Join-Path $TestRoot "extension-$name.mjs"
        [IO.File]::WriteAllText($contentFile, "export const fixture = `"$name`";`n")
        $blob = (& git -C $FixtureRepository hash-object -w $contentFile).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw "Could not create $name fixture extension blob"
        }
        Invoke-Git -C $FixtureRepository update-index `
            --add --cacheinfo "100644,$blob,extensions/$name/extension.mjs"
    }
    $validEntrypoint = Join-Path $TestRoot "valid-extension.mjs"
    [IO.File]::WriteAllText(
        $validEntrypoint,
        "import `"./module.mjs`";`nexport const fixture = `"valid`";`n"
    )
    $blob = (& git -C $FixtureRepository hash-object -w $validEntrypoint).Trim()
    Invoke-Git -C $FixtureRepository update-index `
        --add --cacheinfo "100644,$blob,extensions/valid/extension.mjs"
    $validDependency = Join-Path $TestRoot "valid-module.mjs"
    [IO.File]::WriteAllText($validDependency, "export const dependency = `"internal`";`n")
    $blob = (& git -C $FixtureRepository hash-object -w $validDependency).Trim()
    Invoke-Git -C $FixtureRepository update-index `
        --add --cacheinfo "100644,$blob,extensions/valid/lib/module.mjs"
    foreach ($path in $Links.Keys) {
        $targetFile = Join-Path $TestRoot "link-$([Guid]::NewGuid().ToString('N'))"
        [IO.File]::WriteAllText($targetFile, $Links[$path])
        $blob = (& git -C $FixtureRepository hash-object -w $targetFile).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw "Could not create fixture link blob"
        }
        Invoke-Git -C $FixtureRepository update-index `
            --add --cacheinfo "120000,$blob,$path"
    }
    $tree = (& git -C $FixtureRepository write-tree).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Could not write archive safety fixture tree"
    }
    $fixtureCommit = (& git -C $FixtureRepository commit-tree $tree -p $commit -m "Add archive safety fixtures").Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create archive safety fixture commit"
    }
    Invoke-Git -C $FixtureRepository update-ref refs/heads/archive-safety $fixtureCommit
    return $fixtureCommit
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
    $archiveSafetyCommit = New-ArchiveSafetyFixtureCommit ([ordered]@{
        "extensions/absolute/absolute.txt" = "/outside"
        "extensions/dotdot/escape.txt" = "../outside"
        "extensions/multihop/hop-a" = "lib/hop-b"
        "extensions/multihop/lib/hop-b" = "../../outside"
        "extensions/dangling/dangling.txt" = "missing.txt"
        "extensions/cycle/cycle-a" = "cycle-b"
        "extensions/cycle/cycle-b" = "cycle-a"
        "extensions/self-entrypoint/extension.mjs" = "extension.mjs"
        "extensions/self-nested/nested.mjs" = "nested.mjs"
        "extensions/self-directory/assets" = "assets"
        "extensions/entrypoint/extension.mjs" = "../outside.mjs"
        "extensions/directory/assets" = "../outside-dir"
        "extensions/valid/module.mjs" = "lib/module.mjs"
    })

    @'
@echo off
if "%1"=="repo" if "%2"=="clone" (
  if not "%SYNC_TEST_CLONE_DELAY_SECONDS%"=="" pwsh -NoLogo -NoProfile -Command "Start-Sleep -Seconds $env:SYNC_TEST_CLONE_DELAY_SECONDS"
  git clone --quiet "%FIXTURE_REPOSITORY%" "%4"
  exit /b %ERRORLEVEL%
)
exit /b 1
'@ | Set-Content -LiteralPath (Join-Path $FakeBin "gh.cmd") -Encoding ascii
    @'
#!/bin/bash
if [[ "$1" == "repo" && "$2" == "clone" ]]; then
  sleep "${SYNC_TEST_CLONE_DELAY_SECONDS:-0}"
  git clone --quiet "$FIXTURE_REPOSITORY" "$4"
  exit
fi
exit 1
'@ | Set-Content -LiteralPath (Join-Path $FakeBin "gh") -Encoding utf8
    if (-not $IsWindows) {
        & chmod +x (Join-Path $FakeBin "gh")
    } else {
        & bash -c "chmod +x '$(ConvertTo-BashPath (Join-Path $FakeBin "gh"))'"
    }

    Set-Content -LiteralPath $Manifest `
        -Value "fixture/repo@$commit  extensions/sample  sample" `
        -Encoding utf8
    $previousPath = $env:PATH
    $previousFixtureRepository = $env:FIXTURE_REPOSITORY
    $env:PATH = "$FakeBin$([IO.Path]::PathSeparator)$previousPath"
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
        $rejectedEntries = @(
            "absolute",
            "dotdot",
            "multihop",
            "dangling",
            "cycle",
            "self-entrypoint",
            "self-nested",
            "self-directory",
            "entrypoint",
            "directory"
        )
        $manifestLines = [Collections.Generic.List[string]]::new()
        $manifestLines.Add("fixture/repo@$commit  extensions/sample  sample")
        $manifestLines.Add("fixture/repo@$archiveSafetyCommit  extensions/valid  valid-links")
        foreach ($name in $rejectedEntries) {
            $manifestLines.Add("fixture/repo@$archiveSafetyCommit  extensions/$name  rejected-$name")
        }
        Set-Content -LiteralPath $Manifest -Value @($manifestLines) -Encoding utf8
        $rejectedLog = Join-Path $TestRoot "rejected-links.log"
        try {
            & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                -DotfilesRoot $DotfilesRoot `
                -CopilotHome $CopilotHome `
                -ProjectsRoot $ProjectsRoot `
                -ExternalCacheRoot $CacheRoot `
                -ExternalExtensionsFile $Manifest *> $rejectedLog
        } catch {
        }
        Assert-InstalledTree $expected $installed
        Assert-InstalledTree $expected $materialized
        $validExpected = Join-Path $TestRoot "valid-expected"
        $validArchive = Join-Path $TestRoot "valid-expected.tar"
        New-Item -ItemType Directory -Path $validExpected | Out-Null
        Invoke-Git -c core.autocrlf=false -c core.eol=lf -C $FixtureRepository `
            archive --format=tar "--output=$validArchive" "${archiveSafetyCommit}:extensions/valid"
        & tar -xf $validArchive -C $validExpected
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract valid internal-link fixture archive"
        }
        Assert-InstalledTree $validExpected (Join-Path $CopilotHome "extensions\valid-links")
        $rejectedOutput = Get-Content -LiteralPath $rejectedLog -Raw
        foreach ($name in $rejectedEntries) {
            if (Test-Path -LiteralPath (Join-Path $CopilotHome "extensions\rejected-$name")) {
                throw "Unsafe $name fixture was published"
            }
            if ($rejectedOutput -notmatch [regex]::Escape("extensions/$name")) {
                throw "Unsafe $name fixture was not exercised"
            }
        }
        Set-Content -LiteralPath $Manifest `
            -Value "fixture/repo@$commit  extensions/sample  sample" `
            -Encoding utf8
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null
        Assert-InstalledTree $expected $installed

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

        Set-Content -LiteralPath $Manifest `
            -Value "fixture/repo@$commit  extensions/sample  sample" `
            -Encoding utf8
        $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_AFTER_SWAP = "1"
        try {
            $failed = $false
            try {
                & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                    -DotfilesRoot $DotfilesRoot `
                    -CopilotHome $CopilotHome `
                    -ProjectsRoot $ProjectsRoot `
                    -ExternalCacheRoot $CacheRoot `
                    -ExternalExtensionsFile $Manifest *> $null
            } catch {
                $failed = $true
            }
            if (-not $failed) {
                throw "Injected PowerShell swap failure unexpectedly succeeded"
            }
        } finally {
            Remove-Item Env:\COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_AFTER_SWAP -ErrorAction SilentlyContinue
        }
        Assert-InstalledTree $expected $installed
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null
        Assert-InstalledTree $expected $installed

        Set-Content -LiteralPath (
            Join-Path $materialized "extension.mjs"
        ) -Value "dirty materialized tree" -Encoding utf8
        $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_BACKUP_CLEANUP = "1"
        try {
            $failed = $false
            try {
                & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                    -DotfilesRoot $DotfilesRoot `
                    -CopilotHome $CopilotHome `
                    -ProjectsRoot $ProjectsRoot `
                    -ExternalCacheRoot $CacheRoot `
                    -ExternalExtensionsFile $Manifest *> $null
            } catch {
                $failed = $true
            }
            if (-not $failed) {
                throw "Injected PowerShell backup cleanup failure unexpectedly succeeded"
            }
        } finally {
            Remove-Item Env:\COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_BACKUP_CLEANUP -ErrorAction SilentlyContinue
        }
        Assert-InstalledTree $expected $installed
        $backup = Join-Path (Split-Path -Parent $materialized) ".sample.backup"
        if (-not (Test-Path -LiteralPath $backup -PathType Container)) {
            throw "Committed replacement did not retain the cleanup backup"
        }
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $CopilotHome `
            -ProjectsRoot $ProjectsRoot `
            -ExternalCacheRoot $CacheRoot `
            -ExternalExtensionsFile $Manifest *> $null
        if (Test-Path -LiteralPath $backup) {
            throw "Backup cleanup remnant survived the next sync"
        }

        $lockRoot = Join-Path $CopilotHome ".locks\external-extensions"
        foreach ($stage in @("after-choosing-owner", "after-ticket-directory", "after-ticket-owner")) {
            $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_LOCK_STAGE = $stage
            try {
                $failed = $false
                try {
                    & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                        -DotfilesRoot $DotfilesRoot `
                        -CopilotHome $CopilotHome `
                        -ProjectsRoot $ProjectsRoot `
                        -ExternalCacheRoot $CacheRoot `
                        -ExternalExtensionsFile $Manifest *> $null
                } catch {
                    $failed = $true
                }
                if (-not $failed) {
                    throw "Injected PowerShell lock acquisition failure unexpectedly succeeded: $stage"
                }
            } finally {
                Remove-Item Env:\COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_LOCK_STAGE -ErrorAction SilentlyContinue
            }
            if (@(Get-ChildItem -LiteralPath $lockRoot -Directory -Force).Count -ne 0) {
                throw "PowerShell lock acquisition failure left a candidate: $stage"
            }
        }

        $concurrentHome = Join-Path $TestRoot "concurrent-home\.copilot"
        $concurrentData = Join-Path $TestRoot "concurrent-data"
        $concurrentCache = Join-Path $concurrentData "copilot-external-extensions"
        $concurrentProjects = Join-Path $TestRoot "concurrent-projects"
        $preseedCache = Join-Path $TestRoot "preseed-cache"
        New-Item -ItemType Directory -Path (
            $concurrentHome, $concurrentData, $concurrentProjects, $preseedCache
        ) -Force | Out-Null
        Set-Content -LiteralPath $Manifest -Value "" -Encoding utf8
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $concurrentHome `
            -ProjectsRoot $concurrentProjects `
            -ExternalCacheRoot $preseedCache `
            -ExternalExtensionsFile $Manifest *> $null
        Set-Content -LiteralPath $Manifest `
            -Value "fixture/repo@$commit  extensions/sample  sample" `
            -Encoding utf8

        $freshBarrier = Join-Path $TestRoot "powershell-fresh-lock"
        $one = Start-SyncProcess powershell "powershell-fresh-1" `
            $concurrentHome $concurrentCache $concurrentProjects 0 30 1 $freshBarrier
        $two = Start-SyncProcess powershell "powershell-fresh-2" `
            $concurrentHome $concurrentCache $concurrentProjects 0 30 1 $freshBarrier
        Release-LockBarrier $freshBarrier 2
        foreach ($result in @((Wait-SyncProcess $one), (Wait-SyncProcess $two))) {
            if ($result.ExitCode -ne 0) {
                throw "Concurrent PowerShell sync failed: $($result.Error)"
            }
        }
        $concurrentInstalled = Join-Path $concurrentHome "extensions\sample"
        Assert-InstalledTree $expected $concurrentInstalled

        $concurrentClone = Join-Path $concurrentCache "fixture\repo"
        Set-Content -LiteralPath (
            Join-Path $concurrentClone "extensions\sample\extension.mjs"
        ) -Value "dirty tracked checkout" -Encoding utf8
        Set-Content -LiteralPath (
            Join-Path $concurrentClone "extensions\sample\drift.txt"
        ) -Value "dirty untracked checkout" -Encoding utf8
        $one = Start-SyncProcess powershell "powershell-dirty-1" `
            $concurrentHome $concurrentCache $concurrentProjects 2
        [void](Wait-ForLockTicket (Join-Path $concurrentHome ".locks\external-extensions"))
        $two = Start-SyncProcess powershell "powershell-dirty-2" `
            $concurrentHome $concurrentCache $concurrentProjects
        foreach ($result in @((Wait-SyncProcess $one), (Wait-SyncProcess $two))) {
            if ($result.ExitCode -ne 0) {
                throw "Dirty concurrent PowerShell sync failed: $($result.Error)"
            }
        }
        Assert-InstalledTree $expected $concurrentInstalled

        Set-Content -LiteralPath (
            Join-Path $concurrentClone "extensions\sample\extension.mjs"
        ) -Value "dirty tracked checkout" -Encoding utf8
        Set-Content -LiteralPath (
            Join-Path $concurrentClone "extensions\sample\drift.txt"
        ) -Value "dirty untracked checkout" -Encoding utf8
        $bash = Start-SyncProcess bash "mixed-bash" `
            $concurrentHome $concurrentCache $concurrentProjects 5
        [void](Wait-ForLockTicket (Join-Path $concurrentHome ".locks\external-extensions"))
        $powershell = Start-SyncProcess powershell "mixed-powershell" `
            $concurrentHome $concurrentCache $concurrentProjects
        foreach ($result in @((Wait-SyncProcess $bash), (Wait-SyncProcess $powershell))) {
            if ($result.ExitCode -ne 0) {
                throw "Mixed concurrent sync failed: $($result.Error)"
            }
        }
        Assert-InstalledTree $expected $concurrentInstalled
        if (Test-Path -LiteralPath (Join-Path $concurrentInstalled "drift.txt")) {
            throw "Mixed concurrent install contains checkout drift"
        }

        $mixedHome = Join-Path $TestRoot "mixed-fresh-home\.copilot"
        $mixedData = Join-Path $TestRoot "mixed-fresh-data"
        $mixedCache = Join-Path $mixedData "copilot-external-extensions"
        $mixedProjects = Join-Path $TestRoot "mixed-fresh-projects"
        $mixedPreseedCache = Join-Path $TestRoot "mixed-preseed-cache"
        New-Item -ItemType Directory -Path (
            $mixedHome, $mixedData, $mixedProjects, $mixedPreseedCache
        ) -Force | Out-Null
        Set-Content -LiteralPath $Manifest -Value "" -Encoding utf8
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $mixedHome `
            -ProjectsRoot $mixedProjects `
            -ExternalCacheRoot $mixedPreseedCache `
            -ExternalExtensionsFile $Manifest *> $null
        Set-Content -LiteralPath $Manifest `
            -Value "fixture/repo@$commit  extensions/sample  sample" `
            -Encoding utf8
        $mixedFreshBarrier = Join-Path $TestRoot "mixed-fresh-lock"
        $bash = Start-SyncProcess bash "mixed-fresh-bash" `
            $mixedHome $mixedCache $mixedProjects 0 30 1 $mixedFreshBarrier
        $powershell = Start-SyncProcess powershell "mixed-fresh-powershell" `
            $mixedHome $mixedCache $mixedProjects 0 30 1 $mixedFreshBarrier
        Release-LockBarrier $mixedFreshBarrier 2
        foreach ($result in @((Wait-SyncProcess $bash), (Wait-SyncProcess $powershell))) {
            if ($result.ExitCode -ne 0) {
                throw "Fresh mixed concurrent sync failed: $($result.Error)"
            }
        }
        Assert-InstalledTree $expected (Join-Path $mixedHome "extensions\sample")

        $defaultHome = Join-Path $TestRoot "default-home\.copilot"
        $defaultProjects = Join-Path $TestRoot "default-projects"
        $defaultBashCache = Join-Path $TestRoot "default-home\.local\share\copilot-external-extensions"
        $defaultPowerShellCache = Join-Path $defaultProjects ".copilot-external-extensions"
        New-Item -ItemType Directory -Path $defaultHome, $defaultProjects -Force | Out-Null
        $defaultBarrier = Join-Path $TestRoot "mixed-default-lock"
        $bash = Start-SyncProcess bash "mixed-default-bash" `
            $defaultHome $defaultBashCache $defaultProjects 2 30 1 $defaultBarrier $true
        $powershell = Start-SyncProcess powershell "mixed-default-powershell" `
            $defaultHome $defaultPowerShellCache $defaultProjects 0 30 1 $defaultBarrier $true
        Release-LockBarrier $defaultBarrier 2
        foreach ($result in @((Wait-SyncProcess $bash), (Wait-SyncProcess $powershell))) {
            if ($result.ExitCode -ne 0) {
                throw "Default-path mixed concurrent sync failed: $($result.Error)"
            }
        }
        $defaultInstalled = Join-Path $defaultHome "extensions\sample"
        Assert-InstalledTree $expected $defaultInstalled
        if (-not (Test-Path -LiteralPath $defaultBashCache -PathType Container) -or
            -not (Test-Path -LiteralPath $defaultPowerShellCache -PathType Container) -or
            (Test-Path -LiteralPath (Join-Path $defaultInstalled ".copilot"))) {
            throw "Default-path mixed sync did not keep separate caches and one exact install"
        }

        if (-not $IsWindows) {
            $caseRoot = Join-Path $TestRoot "case-sensitive"
            $upperCache = Join-Path $caseRoot "Cache"
            $lowerCache = Join-Path $caseRoot "cache"
            $upperOwner = Join-Path $upperCache "fixture"
            $caseHome = Join-Path $caseRoot "home\.copilot"
            New-Item -ItemType Directory -Path $upperOwner, $lowerCache, $caseHome -Force | Out-Null
            Invoke-Git clone --quiet $FixtureRepository (Join-Path $upperOwner "repo")
            New-Item -ItemType SymbolicLink `
                -Path (Join-Path $lowerCache "fixture") `
                -Target $upperOwner | Out-Null
            $rejectedCaseEscape = $false
            try {
                & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                    -DotfilesRoot $DotfilesRoot `
                    -CopilotHome $caseHome `
                    -ProjectsRoot (Join-Path $caseRoot "projects") `
                    -ExternalCacheRoot $lowerCache `
                    -ExternalExtensionsFile $Manifest *> $null
            } catch {
                $rejectedCaseEscape = $_.Exception.Message -match "cache path escapes"
            }
            if (-not $rejectedCaseEscape) {
                throw "PowerShell accepted a case-distinct sibling cache on a case-sensitive platform"
            }
        } else {
            $caseRoot = Join-Path $TestRoot "case-insensitive"
            $caseCache = Join-Path $caseRoot "cache"
            $caseOwnerTarget = Join-Path $caseRoot "CACHE\fixture-real"
            $caseHome = Join-Path $caseRoot "home\.copilot"
            New-Item -ItemType Directory -Path $caseOwnerTarget, $caseHome -Force | Out-Null
            Invoke-Git clone --quiet $FixtureRepository (Join-Path $caseOwnerTarget "repo")
            New-Item -ItemType SymbolicLink `
                -Path (Join-Path $caseCache "fixture") `
                -Target $caseOwnerTarget | Out-Null
            & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                -DotfilesRoot $DotfilesRoot `
                -CopilotHome $caseHome `
                -ProjectsRoot (Join-Path $caseRoot "projects") `
                -ExternalCacheRoot $caseCache `
                -ExternalExtensionsFile $Manifest *> $null
            Assert-InstalledTree $expected (Join-Path $caseHome "extensions\sample")
        }

        $lockRoot = Join-Path $concurrentHome ".locks\external-extensions"
        $stalePlatform = if ($IsWindows) { "windows" } else { "unix" }
        $staleToken = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        $stale = Join-Path $lockRoot (
            "ticket-0000000001--$stalePlatform--2147483000--1--$staleToken"
        )
        New-Item -ItemType Directory -Path $stale | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $stale "owner"),
            "version=1`nplatform=$stalePlatform`npid=2147483000`nprocess_started=1`ntoken=$staleToken`n",
            [Text.UTF8Encoding]::new($false)
        )
        $staleBarrier = Join-Path $TestRoot "powershell-stale-lock"
        $one = Start-SyncProcess powershell "powershell-stale-1" `
            $concurrentHome $concurrentCache $concurrentProjects 0 30 0 $staleBarrier
        $two = Start-SyncProcess powershell "powershell-stale-2" `
            $concurrentHome $concurrentCache $concurrentProjects 0 30 0 $staleBarrier
        Release-LockBarrier $staleBarrier 2
        foreach ($result in @((Wait-SyncProcess $one), (Wait-SyncProcess $two))) {
            if ($result.ExitCode -ne 0) {
                throw "Concurrent stale-lock recovery failed: $($result.Error)"
            }
        }
        if (Test-Path -LiteralPath $stale) {
            throw "PowerShell did not remove a stale external extension lock"
        }

        $partialToken = "dddddddddddddddddddddddddddddddd"
        $partial = Join-Path $lockRoot (
            "choosing--$stalePlatform--2147483000--1--$partialToken"
        )
        New-Item -ItemType Directory -Path $partial | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $partial "owner"),
            "version=1`n",
            [Text.UTF8Encoding]::new($false)
        )
        & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
            -DotfilesRoot $DotfilesRoot `
            -CopilotHome $concurrentHome `
            -ProjectsRoot $concurrentProjects `
            -ExternalCacheRoot $concurrentCache `
            -ExternalExtensionsFile $Manifest *> $null
        if (Test-Path -LiteralPath $partial) {
            throw "PowerShell did not remove a dead partial lock owner"
        }

        $unknownToken = "cccccccccccccccccccccccccccccccc"
        $unknown = Join-Path $lockRoot (
            "ticket-0000000001--$stalePlatform--2147483000--1--$unknownToken"
        )
        New-Item -ItemType Directory -Path $unknown | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $unknown "owner"),
            "version=1`nplatform=$stalePlatform`npid=2147483000`nprocess_started=1`ntoken=$unknownToken`n",
            [Text.UTF8Encoding]::new($false)
        )
        $previousOwnerStatus = $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_OWNER_STATUS
        $previousLockTimeout = $env:COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS
        $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_OWNER_STATUS = "unknown"
        $env:COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS = "1"
        try {
            $timedOut = $false
            try {
                & (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install `
                    -DotfilesRoot $DotfilesRoot `
                    -CopilotHome $concurrentHome `
                    -ProjectsRoot $concurrentProjects `
                    -ExternalCacheRoot $concurrentCache `
                    -ExternalExtensionsFile $Manifest *> $null
            } catch {
                $timedOut = $_.Exception.Message -match "sync lock timed out"
            }
            if (-not $timedOut -or -not (Test-Path -LiteralPath $unknown)) {
                throw "PowerShell reclaimed an owner whose liveness probe was unknown"
            }
        } finally {
            $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_OWNER_STATUS = $previousOwnerStatus
            $env:COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS = $previousLockTimeout
        }
        Remove-Item -LiteralPath (Join-Path $unknown "owner")
        Remove-Item -LiteralPath $unknown

        $holder = Start-SyncProcess powershell "powershell-holder" `
            $concurrentHome $concurrentCache $concurrentProjects 10
        [void](Wait-ForLockTicket $lockRoot)
        $contender = Start-SyncProcess bash "bash-timeout" `
            $concurrentHome $concurrentCache $concurrentProjects 0 1
        $contenderResult = Wait-SyncProcess $contender
        if ($contenderResult.ExitCode -eq 0 -or
            $contenderResult.Output + $contenderResult.Error -notmatch
                'external extension sync lock timed out') {
            throw "Bash contender did not time out on a live PowerShell lock"
        }
        if ($holder.Process.HasExited) {
            throw "PowerShell lock holder exited before the contender timed out"
        }
        $holderResult = Wait-SyncProcess $holder
        if ($holderResult.ExitCode -ne 0) {
            throw "PowerShell lock holder failed: $($holderResult.Error)"
        }
        Assert-InstalledTree $expected $concurrentInstalled

        $remainingLocks = @(Get-ChildItem -LiteralPath $lockRoot -Directory -Force)
        if ($remainingLocks.Count -ne 0) {
            throw "External extension lock candidates remain"
        }
        $materializedRoot = Join-Path $concurrentCache ".materialized"
        $remnants = @(
            Get-ChildItem -LiteralPath $materializedRoot -Recurse -Force |
                Where-Object { $_.Name -like "*.tmp.*" -or $_.Name -like "*.backup" }
        )
        if ($remnants.Count -ne 0) {
            throw "External extension staging remnants remain"
        }
    } finally {
        $env:PATH = $previousPath
        $env:FIXTURE_REPOSITORY = $previousFixtureRepository
    }

    Write-Output "PowerShell external extension cache tests passed"
} finally {
    Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
