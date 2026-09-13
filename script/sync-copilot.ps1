#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "import")]
    [string]$Command,

    [string]$DotfilesRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CopilotHome = (Join-Path $HOME ".copilot"),
    [string]$ProjectsRoot = "Q:\",
    [string]$ExternalCacheRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRepo = Join-Path $DotfilesRoot "copilot"
$ExtensionsDirectoryName = "extensions"
$ExternalExtensionsFile = Join-Path $CopilotRepo "external-extensions"
$ExternalSkillsFile = Join-Path $CopilotRepo "external-skills"
if (-not $ExternalCacheRoot) {
    $ExternalCacheRoot = Join-Path $ProjectsRoot ".copilot-external-extensions"
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
    return $normalizedPath.Equals($normalizedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $normalizedPath.StartsWith(
            $normalizedRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
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
                $current = $target
                $changed = $true
            } else {
                $current = $candidate
            }
        }

        $next = Get-NormalizedPath $current
        if (-not $changed -or $next.Equals($resolved, [StringComparison]::OrdinalIgnoreCase)) {
            return $next
        }
        $resolved = $next
    }

    throw "Could not resolve link path after 40 passes: $Path"
}

function Remove-EmptyParents([string]$Path, [string]$StopAt) {
    $current = Split-Path -Parent $Path
    $stop = Get-NormalizedPath $StopAt

    while ($current -and -not (Get-NormalizedPath $current).Equals($stop, [StringComparison]::OrdinalIgnoreCase)) {
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
            if ($target.Equals($sourcePath, [StringComparison]::OrdinalIgnoreCase)) {
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
    $expected = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
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

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
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

    $kept = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
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

function Install-ExternalExtensions {
    if (-not (Test-Path -LiteralPath $ExternalExtensionsFile -PathType Leaf)) {
        return
    }

    if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Yellow "  skip external extensions (gh not in PATH)"
        return
    }

    $destinationRoot = Join-Path $CopilotHome $ExtensionsDirectoryName
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $ExternalCacheRoot -Force | Out-Null
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
        if ($spec -notmatch '^[^/\\]+/[^/\\]+$') {
            Write-Yellow "  skip external entry (expected owner/repo): $line"
            continue
        }

        $owner, $repo = $spec -split '/', 2
        if (-not $installName) {
            $installName = $repo
        }
        $destination = Get-NormalizedPath (Join-Path $destinationRoot $installName)
        if (-not (Test-PathWithin $destination $destinationRoot)) {
            throw "External extension install path escapes its root: $line"
        }

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

        if ($ref) {
            & git -C $cloneDirectory checkout --quiet $ref
            if ($LASTEXITCODE -ne 0) {
                Write-Yellow "  skip $owner/$repo@$ref (checkout failed)"
                continue
            }
            $branch = & git -C $cloneDirectory symbolic-ref -q HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $branch) {
                & git -C $cloneDirectory merge --quiet --ff-only "origin/$ref" 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Yellow "  skip $owner/$repo@$ref (fast-forward failed)"
                    continue
                }
            }
        } else {
            $defaultBranch = & git -C $cloneDirectory symbolic-ref --short refs/remotes/origin/HEAD 2>$null
            if (-not $defaultBranch) {
                $defaultBranch = "main"
            } else {
                $defaultBranch = $defaultBranch -replace '^origin/', ''
            }
            & git -C $cloneDirectory checkout --quiet $defaultBranch 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Yellow "  skip $owner/$repo (checkout failed)"
                continue
            }
            & git -C $cloneDirectory merge --quiet --ff-only "origin/$defaultBranch" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Yellow "  skip $owner/$repo (fast-forward failed)"
                continue
            }
        }

        $source = Get-NormalizedPath (Join-Path $cloneDirectory $subpath)
        if (-not (Test-PathWithin $source $cloneDirectory)) {
            throw "External extension subpath escapes its clone: $line"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $source "extension.mjs") -PathType Leaf)) {
            Write-Yellow "  skip $owner/$repo (no extension.mjs at $subpath)"
            continue
        }

        $keptInstalls.Add($installName)
        Link-TreeIntoExtensionsDirectory `
            $source `
            $destination `
            $cloneDirectory `
            "extensions/$installName (external: $owner/$repo)"
    }

    Remove-UnlistedManagedExtensionDirectories `
        $destinationRoot `
        $ExternalCacheRoot `
        @($keptInstalls) `
        "extensions (external)"
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
