#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "import")]
    [string]$Command,

    [string]$DotfilesRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CopilotHome = (Join-Path $HOME ".copilot"),
    [string]$ProjectsRoot = "Q:\",
    [string]$ExternalCacheRoot,
    [string]$ExternalExtensionsFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRepo = Join-Path $DotfilesRoot "copilot"
$ExtensionsDirectoryName = "extensions"
if (-not $ExternalExtensionsFile) {
    $ExternalExtensionsFile = Join-Path $CopilotRepo "external-extensions"
}
$ExternalSkillsFile = Join-Path $CopilotRepo "external-skills"
if (-not $ExternalCacheRoot) {
    $ExternalCacheRoot = Join-Path $ProjectsRoot ".copilot-external-extensions"
}
$ExternalMaterializedRoot = Join-Path $ExternalCacheRoot ".materialized"
$ExternalLockRoot = Join-Path (Join-Path $CopilotHome ".locks") "external-extensions"
$PathComparison = if ($IsWindows) {
    [StringComparison]::OrdinalIgnoreCase
} else {
    [StringComparison]::Ordinal
}
$PathComparer = if ($IsWindows) {
    [StringComparer]::OrdinalIgnoreCase
} else {
    [StringComparer]::Ordinal
}

function Write-Green([string]$Message) {
    Write-Host $Message -ForegroundColor Green
}

function Write-Yellow([string]$Message) {
    Write-Host $Message -ForegroundColor Yellow
}

function Get-NormalizedPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-PathWithin([string]$Path, [string]$Root) {
    $normalizedPath = Get-NormalizedPath $Path
    $normalizedRoot = Get-NormalizedPath $Root
    return $normalizedPath.Equals($normalizedRoot, $PathComparison) -or
        $normalizedPath.StartsWith(
            $normalizedRoot + [IO.Path]::DirectorySeparatorChar,
            $PathComparison
        )
}

function Get-ExistingItem([string]$Path) {
    return Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Get-LinkTarget([string]$Path) {
    $item = Get-ExistingItem $Path
    if ($null -eq $item -or [string]::IsNullOrEmpty($item.LinkType)) {
        return $null
    }

    $target = @($item.Target)[0]
    if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path (Split-Path -Parent $Path) $target
    }
    return Get-NormalizedPath $target
}

function Resolve-LinkPath([string]$Path) {
    $resolved = Get-NormalizedPath $Path
    $visitedLinks = [Collections.Generic.HashSet[string]]::new($PathComparer)

    for ($pass = 0; $pass -lt 40; $pass++) {
        $root = [IO.Path]::GetPathRoot($resolved)
        $current = $root
        $changed = $false
        $relative = $resolved.Substring($root.Length)
        $parts = @($relative -split '[\\/]' | Where-Object { $_ })

        foreach ($part in $parts) {
            $candidate = Join-Path $current $part
            $target = Get-LinkTarget $candidate
            if ($null -ne $target) {
                $linkPath = Get-NormalizedPath $candidate
                if (-not $visitedLinks.Add($linkPath)) {
                    throw "Link cycle detected while resolving: $Path"
                }
                $current = $target
                $changed = $true
            } else {
                $current = $candidate
            }
        }

        $next = Get-NormalizedPath $current
        if (-not $changed) {
            return $next
        }
        if ($next.Equals($resolved, $PathComparison)) {
            throw "Link cycle detected while resolving: $Path"
        }
        $resolved = $next
    }

    throw "Could not resolve link path after 40 passes: $Path"
}

function Remove-EmptyParents([string]$Path, [string]$StopAt) {
    $current = Split-Path -Parent $Path
    $stop = Get-NormalizedPath $StopAt

    while ($current -and -not (Get-NormalizedPath $current).Equals($stop, $PathComparison)) {
        $children = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue)
        if ($children.Count -ne 0) {
            break
        }
        Remove-Item -LiteralPath $current
        $current = Split-Path -Parent $current
    }
}

function New-SymbolicLink([string]$Source, [string]$Destination, [switch]$SkipRealDestination) {
    $sourcePath = Get-NormalizedPath $Source
    $item = Get-ExistingItem $Destination

    if ($null -ne $item) {
        $target = Get-LinkTarget $Destination
        if ($null -ne $target) {
            if ($target.Equals($sourcePath, $PathComparison)) {
                return $false
            }
            Remove-Item -LiteralPath $Destination -Force
        } elseif ($SkipRealDestination) {
            Write-Yellow "  skip $Destination (real file or directory, not replacing)"
            return $false
        } else {
            $backup = "$Destination.pre-dotfiles-sync"
            if ($null -ne (Get-ExistingItem $backup)) {
                throw "Cannot back up $Destination because $backup already exists"
            }
            Move-Item -LiteralPath $Destination -Destination $backup
            Write-Yellow "  backed up existing $Destination"
        }
    }

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $sourcePath -ErrorAction Stop | Out-Null
    } catch {
        throw "Could not create symbolic link $Destination -> $sourcePath. Enable Windows Developer Mode or run PowerShell as Administrator. $($_.Exception.Message)"
    }
    return $true
}

function Test-DisabledSkill([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notmatch '(?ms)\A---[ \t]*\r?\n(?<frontmatter>.*?)^---[ \t]*\r?$') {
        return $false
    }
    return $Matches.frontmatter -match '(?m)^disabled:[ \t]*true[ \t]*\r?$'
}

function Get-PortableFiles([string]$Root) {
    $files = [Collections.Generic.List[string]]::new()

    $instructions = Join-Path $Root "copilot-instructions.md"
    if ($null -ne (Get-ExistingItem $instructions)) {
        $files.Add("copilot-instructions.md")
    }

    $agents = Join-Path $Root "agents"
    if (Test-Path -LiteralPath $agents -PathType Container) {
        Get-ChildItem -LiteralPath $agents -Filter "*.agent.md" -Force |
            Where-Object { -not $_.PSIsContainer } |
            ForEach-Object { $files.Add((Join-Path "agents" $_.Name)) }
    }

    $skills = Join-Path $Root "skills"
    if (Test-Path -LiteralPath $skills -PathType Container) {
        Get-ChildItem -LiteralPath $skills -Directory -Force | ForEach-Object {
            $skill = Join-Path $_.FullName "SKILL.md"
            if ($null -ne (Get-ExistingItem $skill)) {
                $files.Add((Join-Path (Join-Path "skills" $_.Name) "SKILL.md"))
            }
        }
    }

    $docs = Join-Path $Root "docs"
    if (Test-Path -LiteralPath $docs -PathType Container) {
        Get-ChildItem -LiteralPath $docs -Force |
            Where-Object { -not $_.PSIsContainer } |
            ForEach-Object { $files.Add((Join-Path "docs" $_.Name)) }
    }

    return @($files | Sort-Object -Unique)
}

function Prune-RemovedLinks([string[]]$ExpectedFiles) {
    $expected = [Collections.Generic.HashSet[string]]::new($PathComparer)
    foreach ($relativePath in $ExpectedFiles) {
        [void]$expected.Add($relativePath)
    }

    foreach ($relativePath in Get-PortableFiles $CopilotHome) {
        if ($expected.Contains($relativePath)) {
            continue
        }

        $destination = Join-Path $CopilotHome $relativePath
        $target = Get-LinkTarget $destination
        if ($null -ne $target -and (Test-PathWithin $target $CopilotRepo)) {
            Remove-Item -LiteralPath $destination -Force
            Remove-EmptyParents $destination $CopilotHome
            Write-Yellow "  removed $($relativePath.Replace('\', '/'))"
        }
    }
}

function Link-TreeIntoExtensionsDirectory(
    [string]$Source,
    [string]$Destination,
    [string]$SafePrefix,
    [string]$Label
) {
    $destinationItem = Get-ExistingItem $Destination
    if ($null -ne $destinationItem -and $null -ne (Get-LinkTarget $Destination)) {
        Remove-Item -LiteralPath $Destination -Force
        $destinationItem = $null
    }
    if ($null -ne $destinationItem -and -not $destinationItem.PSIsContainer) {
        Write-Yellow "  skip $Label (exists, not a directory)"
        return
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    $seen = [Collections.Generic.HashSet[string]]::new($PathComparer)
    foreach ($entry in Get-ChildItem -LiteralPath $Source -Force) {
        if ($entry.Name -in @(".git", ".github", ".gitignore", ".gitattributes", "node_modules")) {
            continue
        }
        [void]$seen.Add($entry.Name)
        [void](New-SymbolicLink $entry.FullName (Join-Path $Destination $entry.Name))
    }

    foreach ($entry in Get-ChildItem -LiteralPath $Destination -Force) {
        if ($seen.Contains($entry.Name)) {
            continue
        }
        $target = Get-LinkTarget $entry.FullName
        if ($null -ne $target -and (Test-PathWithin $target $SafePrefix)) {
            Remove-Item -LiteralPath $entry.FullName -Force
            Write-Yellow "  removed $Label/$($entry.Name)"
        }
    }

    Write-Green "  linked $Label ($($seen.Count) entries)"
}

function Remove-UnlistedManagedExtensionDirectories(
    [string]$DestinationRoot,
    [string]$SafePrefix,
    [string[]]$Keep,
    [string]$LabelPrefix
) {
    if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
        return
    }

    $kept = [Collections.Generic.HashSet[string]]::new($PathComparer)
    foreach ($name in $Keep) {
        [void]$kept.Add($name)
    }

    foreach ($directory in Get-ChildItem -LiteralPath $DestinationRoot -Directory -Force) {
        if ($null -ne (Get-LinkTarget $directory.FullName) -or $kept.Contains($directory.Name)) {
            continue
        }

        $entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force)
        if ($entries.Count -eq 0) {
            continue
        }

        $safe = $true
        foreach ($entry in $entries) {
            $target = Get-LinkTarget $entry.FullName
            if ($null -eq $target -or -not (Test-PathWithin $target $SafePrefix)) {
                $safe = $false
                break
            }
        }
        if ($safe) {
            Remove-Item -LiteralPath $directory.FullName -Recurse -Force
            Write-Yellow "  removed $LabelPrefix/$($directory.Name)"
        }
    }
}

function Install-Extensions {
    $sourceRoot = Join-Path $CopilotRepo $ExtensionsDirectoryName
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        return
    }

    $destinationRoot = Join-Path $CopilotHome $ExtensionsDirectoryName
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    $kept = [Collections.Generic.List[string]]::new()

    foreach ($source in Get-ChildItem -LiteralPath $sourceRoot -Directory -Force) {
        $kept.Add($source.Name)
        Link-TreeIntoExtensionsDirectory `
            $source.FullName `
            (Join-Path $destinationRoot $source.Name) `
            $CopilotRepo `
            "extensions/$($source.Name)"
    }

    Remove-UnlistedManagedExtensionDirectories $destinationRoot $CopilotRepo @($kept) "extensions"
}

function Expand-HomePath([string]$Path) {
    if ($Path.StartsWith('$PROJECTS/')) {
        return Join-Path $ProjectsRoot $Path.Substring(10)
    }
    if ($Path -eq "~") {
        return $HOME
    }
    if ($Path.StartsWith("~/") -or $Path.StartsWith("~\")) {
        return Join-Path $HOME $Path.Substring(2)
    }
    return $Path
}

function Install-ExternalSkills {
    if (-not (Test-Path -LiteralPath $ExternalSkillsFile -PathType Leaf)) {
        return
    }
    $destinationRoot = Join-Path $CopilotHome "skills"
    $linked = 0

    foreach ($rawLine in Get-Content -LiteralPath $ExternalSkillsFile) {
        $line = ($rawLine -replace '#.*$', '').Trim()
        if (-not $line) {
            continue
        }

        $root = Expand-HomePath $line
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            Write-Yellow "  skip external skills: $line (not checked out)"
            continue
        }

        foreach ($directory in Get-ChildItem -LiteralPath $root -Directory -Force) {
            $skill = Join-Path $directory.FullName "SKILL.md"
            if (-not (Test-Path -LiteralPath $skill -PathType Leaf)) {
                continue
            }
            $destination = Join-Path (Join-Path $destinationRoot $directory.Name) "SKILL.md"
            if (Test-DisabledSkill $skill) {
                Write-Yellow "  skip $($directory.Name) (disabled: true)"
                continue
            }

            if (New-SymbolicLink $skill $destination -SkipRealDestination) {
                Write-Green "  linked skills/$($directory.Name)/SKILL.md -> $root/$($directory.Name)"
                $linked++
            }
        }
    }

    if ($linked -gt 0) {
        Write-Host "External skills: $linked linked"
    }
}

function Configure-Blackbird {
    if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
        return
    }

    & gh blackbird skills install --help *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Yellow "  skip Blackbird configuration (gh blackbird not installed)"
        return
    }

    & (Join-Path $DotfilesRoot "script\configure-blackbird.ps1") remote-only `
        -DotfilesRoot $DotfilesRoot `
        -CopilotHome $CopilotHome
}

function Resolve-ExternalCommit([string]$CloneDirectory, [string]$Ref) {
    if (-not $Ref) {
        $defaultBranch = & git -C $CloneDirectory symbolic-ref --short refs/remotes/origin/HEAD 2>$null
        if (-not $defaultBranch) {
            $defaultBranch = "main"
        } else {
            $defaultBranch = $defaultBranch -replace '^origin/', ''
        }
        $commit = & git -C $CloneDirectory rev-parse --verify "refs/remotes/origin/$defaultBranch`^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        return $commit.Trim()
    }

    & git -C $CloneDirectory show-ref --verify --quiet "refs/remotes/origin/$Ref"
    if ($LASTEXITCODE -eq 0) {
        $commit = & git -C $CloneDirectory rev-parse --verify "refs/remotes/origin/$Ref`^{commit}" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $commit.Trim()
        }
    }

    $commit = & git -C $CloneDirectory rev-parse --verify "$Ref`^{commit}" 2>$null
    if ($LASTEXITCODE -eq 0) {
        return $commit.Trim()
    }

    & git -C $CloneDirectory fetch --quiet origin $Ref
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    $commit = & git -C $CloneDirectory rev-parse --verify "FETCH_HEAD`^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    return $commit.Trim()
}

function Get-ExternalLockProcessIdentity {
    if ($IsWindows) {
        $process = Get-Process -Id $PID -ErrorAction Stop
        return @{
            Platform = "windows"
            Pid = $PID
            Started = $process.StartTime.ToUniversalTime().Ticks.ToString()
        }
    }

    $started = (& env "LC_ALL=C" ps -p $PID -o "lstart=" 2>$null) -replace '[^A-Za-z0-9]', ''
    if ($LASTEXITCODE -ne 0 -or -not $started) {
        throw "Could not determine external extension sync process identity"
    }
    return @{
        Platform = "unix"
        Pid = $PID
        Started = $started
    }
}

function Get-ExternalLockOwnerStatus(
    [string]$Platform,
    [int]$OwnerPid,
    [string]$Started
) {
    if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_OWNER_STATUS -eq "unknown") {
        return "unknown"
    }
    if ($Platform -eq "windows") {
        if (-not $IsWindows) {
            return "unknown"
        }
        $process = Get-Process -Id $OwnerPid -ErrorAction SilentlyContinue
        if ($null -eq $process) {
            return "dead"
        }
        try {
            $current = $process.StartTime.ToUniversalTime().Ticks.ToString()
        } catch {
            return "unknown"
        }
        return $(if ($current -eq $Started) { "live" } else { "dead" })
    }
    if ($Platform -ne "unix" -or $IsWindows) {
        return "unknown"
    }

    $current = (& env "LC_ALL=C" ps -p $OwnerPid -o "lstart=" 2>$null) -replace '[^A-Za-z0-9]', ''
    if ($LASTEXITCODE -eq 0 -and $current) {
        return $(if ($current -eq $Started) { "live" } else { "dead" })
    }
    & env "LC_ALL=C" ps -p $OwnerPid *> $null
    if ($LASTEXITCODE -eq 1) {
        return "dead"
    }
    return "unknown"
}

function Get-ExternalLockCandidateIdentity([string]$Name) {
    if ($Name -match '^choosing--(windows|unix)--([0-9]+)--([A-Za-z0-9]+)--([0-9a-f]+)$' -or
        $Name -match '^ticket-[0-9]{10}--(windows|unix)--([0-9]+)--([A-Za-z0-9]+)--([0-9a-f]+)$') {
        return @{
            Platform = $Matches[1]
            Pid = [int]$Matches[2]
            Started = $Matches[3]
            Token = $Matches[4]
        }
    }
    return $null
}

function Remove-ExternalLockCandidateIfStale(
    [IO.DirectoryInfo]$Candidate,
    [string]$OwnedToken
) {
    $identity = Get-ExternalLockCandidateIdentity $Candidate.Name
    if ($null -eq $identity -or $identity.Token -eq $OwnedToken) {
        return
    }
    if ((Get-ExternalLockOwnerStatus $identity.Platform $identity.Pid $identity.Started) -ne "dead") {
        return
    }

    $ownerFile = Join-Path $Candidate.FullName "owner"
    $entries = @(
        Get-ChildItem -LiteralPath $Candidate.FullName -Force -ErrorAction SilentlyContinue
    )
    if (-not (Test-Path -LiteralPath $Candidate.FullName -PathType Container)) {
        return
    }
    if ($entries.Count -eq 0) {
        try {
            [IO.Directory]::Delete($Candidate.FullName)
        } catch [IO.DirectoryNotFoundException] {
            return
        } catch [IO.IOException] {
            return
        }
        if (-not (Test-Path -LiteralPath $Candidate.FullName)) {
            Write-Yellow "  removed stale external extension sync lock"
        }
        return
    }
    if ($entries.Count -ne 1 -or
        -not (Test-Path -LiteralPath $ownerFile -PathType Leaf)) {
        return
    }

    [IO.File]::Delete($ownerFile)
    try {
        [IO.Directory]::Delete($Candidate.FullName)
    } catch [IO.DirectoryNotFoundException] {
        return
    } catch [IO.IOException] {
        return
    }
    if (-not (Test-Path -LiteralPath $Candidate.FullName)) {
        Write-Yellow "  removed stale external extension sync lock"
    }
}

function Write-ExternalLockOwner(
    [string]$Directory,
    [hashtable]$Identity,
    [string]$Token
) {
    $content = @(
        "version=1"
        "platform=$($Identity.Platform)"
        "pid=$($Identity.Pid)"
        "process_started=$($Identity.Started)"
        "token=$Token"
    ) -join "`n"
    [IO.File]::WriteAllText(
        (Join-Path $Directory "owner"),
        "$content`n",
        [Text.UTF8Encoding]::new($false)
    )
}

function Acquire-ExternalExtensionsLock {
    $timeoutValue = $env:COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS
    $timeoutSeconds = if ($timeoutValue) { 0 } else { 30 }
    if ($timeoutValue -and
        (-not [int]::TryParse($timeoutValue, [ref]$timeoutSeconds) -or
            $timeoutSeconds -lt 1 -or $timeoutSeconds -gt 300)) {
        throw "COPILOT_EXTERNAL_EXTENSIONS_LOCK_TIMEOUT_SECONDS must be between 1 and 300"
    }

    if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_LOCK_ROOT_BARRIER) {
        $barrier = $env:COPILOT_EXTERNAL_EXTENSIONS_TEST_LOCK_ROOT_BARRIER
        $marker = "$barrier.powershell.$PID.$([Guid]::NewGuid().ToString('N'))"
        [IO.File]::WriteAllText($marker, "ready")
        $barrierWait = [Diagnostics.Stopwatch]::StartNew()
        try {
            while (-not (Test-Path -LiteralPath "$barrier.release")) {
                if ($barrierWait.Elapsed.TotalSeconds -ge 10) {
                    throw "External extension test lock barrier timed out"
                }
                Start-Sleep -Milliseconds 50
            }
        } finally {
            Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        }
    }

    $lockItem = Get-ExistingItem $ExternalLockRoot
    if ($null -eq $lockItem) {
        New-Item -ItemType Directory -Path $ExternalLockRoot -Force | Out-Null
        $lockItem = Get-ExistingItem $ExternalLockRoot
    } elseif (-not $lockItem.PSIsContainer) {
        throw "External extension lock root is not a directory: $ExternalLockRoot"
    }
    if ($null -eq $lockItem -or -not $lockItem.PSIsContainer) {
        throw "External extension lock root is not a directory: $ExternalLockRoot"
    }
    if (-not (Test-PathWithin (Resolve-LinkPath $ExternalLockRoot) (Resolve-LinkPath $CopilotHome))) {
        throw "External extension lock root escapes Copilot home: $ExternalLockRoot"
    }

    $identity = Get-ExternalLockProcessIdentity
    $token = [Guid]::NewGuid().ToString("N")
    $suffix = "$($identity.Platform)--$($identity.Pid)--$($identity.Started)--$token"
    $choosing = Join-Path $ExternalLockRoot "choosing--$suffix"
    $ticket = $null
    try {
        New-Item -ItemType Directory -Path $choosing -ErrorAction Stop | Out-Null
        Write-ExternalLockOwner $choosing $identity $token
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_LOCK_STAGE -eq "after-choosing-owner") {
            throw "Injected external extension lock failure after choosing owner"
        }

        $maxTicket = 0
        foreach ($candidate in Get-ChildItem -LiteralPath $ExternalLockRoot -Directory -Filter "ticket-*") {
            if ($candidate.Name -match '^ticket-([0-9]{10})--') {
                $maxTicket = [Math]::Max($maxTicket, [int]$Matches[1])
            }
        }
        $ticketName = "ticket-{0:D10}--{1}" -f ($maxTicket + 1), $suffix
        $ticket = Join-Path $ExternalLockRoot $ticketName
        New-Item -ItemType Directory -Path $ticket -ErrorAction Stop | Out-Null
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_LOCK_STAGE -eq "after-ticket-directory") {
            throw "Injected external extension lock failure after ticket directory"
        }
        Write-ExternalLockOwner $ticket $identity $token
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_LOCK_STAGE -eq "after-ticket-owner") {
            throw "Injected external extension lock failure after ticket owner"
        }
        Remove-Item -LiteralPath (Join-Path $choosing "owner")
        Remove-Item -LiteralPath $choosing

        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        while ($true) {
            foreach ($candidate in Get-ChildItem -LiteralPath $ExternalLockRoot -Directory) {
                Remove-ExternalLockCandidateIfStale $candidate $token
            }

            $choosingExists = @(
                Get-ChildItem -LiteralPath $ExternalLockRoot -Directory -Filter "choosing--*"
            ).Count -gt 0
            if (-not $choosingExists) {
                $winner = $null
                foreach ($candidate in Get-ChildItem -LiteralPath $ExternalLockRoot -Directory -Filter "ticket-*") {
                    if ($null -eq $winner -or
                        [StringComparer]::Ordinal.Compare($candidate.Name, $winner.Name) -lt 0) {
                        $winner = $candidate
                    }
                }
                if ($null -ne $winner -and
                    $winner.FullName.Equals($ticket, $PathComparison)) {
                    return @{
                        Ticket = $ticket
                        Token = $token
                    }
                }
            }

            if ($stopwatch.Elapsed.TotalSeconds -ge $timeoutSeconds) {
                throw "External extension sync lock timed out after ${timeoutSeconds}s"
            }
            Start-Sleep -Milliseconds 50
        }
    } catch {
        if ($null -ne $ticket) {
            Release-ExternalExtensionsLock @{ Ticket = $ticket; Token = $token }
        }
        $choosingOwner = Join-Path $choosing "owner"
        if ((Test-Path -LiteralPath $choosingOwner -PathType Leaf) -and
            (Select-String -LiteralPath $choosingOwner -SimpleMatch -Quiet "token=$token")) {
            Remove-Item -LiteralPath $choosingOwner
            Remove-Item -LiteralPath $choosing
        } elseif ((Test-Path -LiteralPath $choosing -PathType Container) -and
            @(Get-ChildItem -LiteralPath $choosing -Force).Count -eq 0 -and
            (Split-Path -Leaf $choosing).EndsWith("--$token", [StringComparison]::Ordinal)) {
            Remove-Item -LiteralPath $choosing
        }
        throw
    }
}

function Release-ExternalExtensionsLock([hashtable]$Lock) {
    if ($null -eq $Lock -or -not (Test-Path -LiteralPath $Lock.Ticket -PathType Container)) {
        return
    }
    $ownerFile = Join-Path $Lock.Ticket "owner"
    if (-not (Split-Path -Leaf $Lock.Ticket).EndsWith(
        "--$($Lock.Token)",
        [StringComparison]::Ordinal
    )) {
        return
    }
    if (Test-Path -LiteralPath $ownerFile -PathType Leaf) {
        if (@(Get-ChildItem -LiteralPath $Lock.Ticket -Force).Count -ne 1) {
            return
        }
        Remove-Item -LiteralPath $ownerFile
    } elseif (@(Get-ChildItem -LiteralPath $Lock.Ticket -Force).Count -ne 0 -or
        -not (Split-Path -Leaf $Lock.Ticket).EndsWith("--$($Lock.Token)", [StringComparison]::Ordinal)) {
        return
    }
    Remove-Item -LiteralPath $Lock.Ticket
}

function Test-MaterializedExtension([string]$Root) {
    $resolvedRoot = Resolve-LinkPath $Root
    try {
        $links = @(
            Get-ChildItem -LiteralPath $Root -Recurse -Force |
                Where-Object { -not [string]::IsNullOrEmpty($_.LinkType) }
        )
        foreach ($link in $links) {
            $target = @($link.Target)[0]
            if ([string]::IsNullOrEmpty($target) -or
                [IO.Path]::IsPathRooted($target) -or
                $target -match '^[A-Za-z]:' -or
                $target.StartsWith('\', [StringComparison]::Ordinal)) {
                return $false
            }

            $resolved = Resolve-LinkPath $link.FullName
            if (-not (Test-PathWithin $resolved $resolvedRoot) -or
                $null -eq (Get-ExistingItem $resolved)) {
                return $false
            }
        }

        $entrypoint = Resolve-LinkPath (Join-Path $Root "extension.mjs")
        return (Test-PathWithin $entrypoint $resolvedRoot) -and
            (Test-Path -LiteralPath $entrypoint -PathType Leaf)
    } catch {
        Write-Yellow "  reject external extension archive ($($_.Exception.Message))"
        return $false
    }
}

function Materialize-ExternalExtension(
    [string]$CloneDirectory,
    [string]$Commit,
    [string]$Subpath,
    [string]$Owner,
    [string]$Repo,
    [string]$InstallName
) {
    $resolvedCacheRoot = Resolve-LinkPath $ExternalCacheRoot
    $materializedItem = Get-ExistingItem $ExternalMaterializedRoot
    if ($null -eq $materializedItem) {
        New-Item -ItemType Directory -Path $ExternalMaterializedRoot | Out-Null
    } elseif (-not $materializedItem.PSIsContainer) {
        throw "External extension materialized root is not a directory: $ExternalMaterializedRoot"
    }
    $resolvedMaterializedRoot = Resolve-LinkPath $ExternalMaterializedRoot
    if (-not (Test-PathWithin $resolvedMaterializedRoot $resolvedCacheRoot)) {
        throw "External extension materialized root escapes its cache: $ExternalMaterializedRoot"
    }

    $ownerRoot = Get-NormalizedPath (Join-Path $ExternalMaterializedRoot $Owner)
    $ownerItem = Get-ExistingItem $ownerRoot
    if ($null -eq $ownerItem) {
        New-Item -ItemType Directory -Path $ownerRoot | Out-Null
    } elseif (-not $ownerItem.PSIsContainer) {
        throw "External extension owner tree is not a directory: $ownerRoot"
    }
    $resolvedOwnerRoot = Resolve-LinkPath $ownerRoot
    if (-not (Test-PathWithin $resolvedOwnerRoot $resolvedMaterializedRoot)) {
        throw "External extension owner tree escapes its cache: $ownerRoot"
    }

    $repositoryRoot = Get-NormalizedPath (Join-Path $ownerRoot $Repo)
    $repositoryItem = Get-ExistingItem $repositoryRoot
    if ($null -eq $repositoryItem) {
        New-Item -ItemType Directory -Path $repositoryRoot | Out-Null
    } elseif (-not $repositoryItem.PSIsContainer) {
        throw "External extension repository tree is not a directory: $repositoryRoot"
    }
    $resolvedRepositoryRoot = Resolve-LinkPath $repositoryRoot
    if (-not (Test-PathWithin $resolvedRepositoryRoot $resolvedOwnerRoot)) {
        throw "External extension repository tree escapes its cache: $repositoryRoot"
    }

    $target = Get-NormalizedPath (Join-Path $repositoryRoot $InstallName)
    $suffix = "$PID-$([Guid]::NewGuid().ToString('N'))"
    $temporary = Join-Path $repositoryRoot ".$InstallName.tmp.$suffix"
    $archive = Join-Path $repositoryRoot ".$InstallName.archive.$suffix.tar"
    $backup = Join-Path $repositoryRoot ".$InstallName.backup"
    $archiveTree = if ($Subpath -eq ".") { $Commit } else { "${Commit}:$Subpath" }
    $replacedPrevious = $false
    $installedNewTarget = $false
    $committed = $false

    if ($null -eq (Get-ExistingItem $target) -and $null -ne (Get-ExistingItem $backup)) {
        Move-Item -LiteralPath $backup -Destination $target
    } elseif ($null -ne (Get-ExistingItem $target) -and $null -ne (Get-ExistingItem $backup)) {
        Remove-Item -LiteralPath $backup -Recurse -Force
    }

    New-Item -ItemType Directory -Path $temporary | Out-Null
    try {
        if ($Subpath -eq ".") {
            & git -C $CloneDirectory cat-file -e "$Commit`^{commit}" 2>$null
            if ($LASTEXITCODE -ne 0) {
                return $null
            }
        } else {
            $archiveType = & git -C $CloneDirectory cat-file -t $archiveTree 2>$null
            if ($LASTEXITCODE -ne 0 -or $archiveType -ne "tree") {
                return $null
            }
        }
        & git -c core.autocrlf=false -c core.eol=lf -C $CloneDirectory `
            archive --format=tar "--output=$archive" $archiveTree 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Could not archive external extension commit"
        }
        & tar -xf $archive -C $temporary
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract external extension archive"
        }
        if (-not (Test-MaterializedExtension $temporary)) {
            return $null
        }

        if ($null -ne (Get-ExistingItem $target)) {
            Move-Item -LiteralPath $target -Destination $backup
            $replacedPrevious = $true
        }
        Move-Item -LiteralPath $temporary -Destination $target
        $installedNewTarget = $true
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_AFTER_SWAP -eq "1") {
            throw "Injected external extension swap failure"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $target "extension.mjs") -PathType Leaf) -or
            $null -ne (Get-ExistingItem (Join-Path $target (Split-Path -Leaf $temporary)))) {
            throw "External extension target validation failed"
        }
        $committed = $true
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_FAIL_BACKUP_CLEANUP -eq "1") {
            throw "Injected external extension backup cleanup failure"
        }
        if ($replacedPrevious) {
            Remove-Item -LiteralPath $backup -Recurse -Force
            $replacedPrevious = $false
        }
        return $target
    } finally {
        if (-not $committed) {
            if ($installedNewTarget -and $null -ne (Get-ExistingItem $target)) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
            if ($replacedPrevious -and $null -eq (Get-ExistingItem $target) -and
                $null -ne (Get-ExistingItem $backup)) {
                Move-Item -LiteralPath $backup -Destination $target
                $replacedPrevious = $false
            }
        }
        if ($null -ne (Get-ExistingItem $temporary)) {
            Remove-Item -LiteralPath $temporary -Recurse -Force
        }
        if ($null -ne (Get-ExistingItem $archive)) {
            Remove-Item -LiteralPath $archive -Force
        }
    }
}

function Install-ExternalExtensions {
    if (-not (Test-Path -LiteralPath $ExternalExtensionsFile -PathType Leaf)) {
        return
    }

    if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Yellow "  skip external extensions (gh not in PATH)"
        return
    }

    New-Item -ItemType Directory -Path $ExternalCacheRoot -Force | Out-Null
    $lock = Acquire-ExternalExtensionsLock
    try {
        if ($env:COPILOT_EXTERNAL_EXTENSIONS_TEST_HOLD_LOCK_SECONDS) {
            Start-Sleep -Seconds ([double]$env:COPILOT_EXTERNAL_EXTENSIONS_TEST_HOLD_LOCK_SECONDS)
        }
        $destinationRoot = Join-Path $CopilotHome $ExtensionsDirectoryName
        New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $ExternalMaterializedRoot -Force | Out-Null
        $keptInstalls = [Collections.Generic.List[string]]::new()

        foreach ($rawLine in Get-Content -LiteralPath $ExternalExtensionsFile) {
            $line = ($rawLine -replace '#.*$', '').Trim()
            if (-not $line) {
                continue
            }

            $tokens = @($line -split '\s+')
            $spec = $tokens[0]
            $subpath = if ($tokens.Count -gt 1) { $tokens[1] } else { "." }
            $installName = if ($tokens.Count -gt 2) { $tokens[2] } else { "" }
            $ref = ""
            $at = $spec.LastIndexOf("@", [StringComparison]::Ordinal)
            if ($at -ge 0) {
                $ref = $spec.Substring($at + 1)
                $spec = $spec.Substring(0, $at)
            }
            if ($spec -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
                Write-Yellow "  skip external entry (expected owner/repo): $line"
                continue
            }

            $owner, $repo = $spec -split '/', 2
            if (-not $installName) {
                $installName = $repo
            }
            if ($installName -notmatch '^[A-Za-z0-9_.-]+$' -or $installName -in @(".", "..")) {
                Write-Yellow "  skip external entry (invalid install name): $line"
                continue
            }
            if ([IO.Path]::IsPathRooted($subpath) -or $subpath.Contains('\') -or
                @($subpath -split '/').Contains("..")) {
                Write-Yellow "  skip external entry (invalid subpath): $line"
                continue
            }
            $destination = Get-NormalizedPath (Join-Path $destinationRoot $installName)
            if (-not (Test-PathWithin $destination $destinationRoot)) {
                throw "External extension install path escapes its root: $line"
            }
            $keptInstalls.Add($installName)

            $cloneDirectory = Join-Path (Join-Path $ExternalCacheRoot $owner) $repo
            if (-not (Test-PathWithin $cloneDirectory $ExternalCacheRoot) -or
                -not (Test-PathWithin (Resolve-LinkPath $cloneDirectory) $ExternalCacheRoot)) {
                throw "External extension cache path escapes its root: $line"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $cloneDirectory ".git") -PathType Container)) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $cloneDirectory) -Force | Out-Null
                & gh repo clone "$owner/$repo" $cloneDirectory -- --quiet
                if ($LASTEXITCODE -ne 0) {
                    Write-Yellow "  skip $owner/$repo (clone failed)"
                    continue
                }
            } else {
                & git -C $cloneDirectory fetch --quiet origin
                if ($LASTEXITCODE -ne 0) {
                    Write-Yellow "  warn: $owner/$repo fetch failed"
                }
            }

            $commit = Resolve-ExternalCommit $cloneDirectory $ref
            if (-not $commit) {
                Write-Yellow "  skip $owner/$repo$(if ($ref) { "@$ref" }) (commit not found)"
                continue
            }

            $source = Materialize-ExternalExtension `
                $cloneDirectory `
                $commit `
                $subpath `
                $owner `
                $repo `
                $installName
            if (-not $source) {
                Write-Yellow "  skip $owner/$repo (invalid extension at $subpath)"
                continue
            }

            Link-TreeIntoExtensionsDirectory `
                $source `
                $destination `
                $ExternalMaterializedRoot `
                "extensions/$installName (external: $owner/$repo@$commit)"
        }

        Remove-UnlistedManagedExtensionDirectories `
            $destinationRoot `
            $ExternalCacheRoot `
            @($keptInstalls) `
            "extensions (external)"
    } finally {
        Release-ExternalExtensionsLock $lock
    }
}

function Install-CopilotConfig {
    Write-Host "Installing copilot config: $CopilotRepo -> $CopilotHome"
    New-Item -ItemType Directory -Path $CopilotHome -Force | Out-Null
    $installed = [Collections.Generic.List[string]]::new()
    $skipped = [Collections.Generic.List[string]]::new()

    foreach ($relativePath in Get-PortableFiles $CopilotRepo) {
        $source = Join-Path $CopilotRepo $relativePath
        if ($relativePath -like "skills\*\SKILL.md" -and (Test-DisabledSkill $source)) {
            $skipped.Add($relativePath)
            continue
        }

        $installed.Add($relativePath)
        $destination = Join-Path $CopilotHome $relativePath
        if (New-SymbolicLink $source $destination) {
            Write-Green "  linked $($relativePath.Replace('\', '/'))"
        }
    }

    Prune-RemovedLinks @($installed)
    Install-Extensions
    Install-ExternalExtensions
    Install-ExternalSkills
    Configure-Blackbird

    if ($skipped.Count -gt 0) {
        Write-Host
        Write-Yellow "Skipped (disabled: true):"
        foreach ($relativePath in $skipped) {
            Write-Yellow "  $($relativePath.Replace('\', '/'))"
        }
    }
}

function Import-CopilotConfig {
    Write-Host "Importing copilot config: $CopilotHome -> $CopilotRepo"
    foreach ($relativePath in Get-PortableFiles $CopilotHome) {
        if ($relativePath -in @("skills\blackbird\SKILL.md", "skills\blackbird-fileset\SKILL.md")) {
            Write-Yellow "  skip $($relativePath.Replace('\', '/')) (installed by gh blackbird)"
            continue
        }

        $source = Join-Path $CopilotHome $relativePath
        $destination = Join-Path $CopilotRepo $relativePath
        $realSource = Resolve-LinkPath $source
        if ($relativePath -eq "copilot-instructions.md" -and
            (Test-PathWithin $realSource (Join-Path $CopilotHome ".dotfiles"))) {
            Write-Yellow "  skip copilot-instructions.md (generated by configure-blackbird)"
            continue
        }

        if (-not (Test-PathWithin $realSource $CopilotHome)) {
            if (Test-PathWithin $realSource $CopilotRepo) {
                Write-Yellow "  skip $($relativePath.Replace('\', '/')) (already linked)"
            } else {
                Write-Yellow "  skip $($relativePath.Replace('\', '/')) (external source: $realSource)"
            }
            continue
        }

        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
        $suffix = "$PID-$([Guid]::NewGuid().ToString('N'))"
        $temporaryLink = "$source.dotfiles-link-$suffix"
        $temporaryOriginal = "$source.dotfiles-original-$suffix"
        try {
            [void](New-SymbolicLink $destination $temporaryLink)
            Move-Item -LiteralPath $source -Destination $temporaryOriginal
            try {
                Move-Item -LiteralPath $temporaryLink -Destination $source
            } catch {
                Move-Item -LiteralPath $temporaryOriginal -Destination $source
                throw
            }
            Remove-Item -LiteralPath $temporaryOriginal -Force
        } finally {
            if ($null -ne (Get-ExistingItem $temporaryLink)) {
                Remove-Item -LiteralPath $temporaryLink -Force
            }
        }
        Write-Green "  imported $($relativePath.Replace('\', '/'))"
    }
}

if (-not $Command) {
    throw "Usage: script\sync-copilot.ps1 {install|import}"
}

switch ($Command) {
    "install" { Install-CopilotConfig }
    "import" { Import-CopilotConfig }
}
