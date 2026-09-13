#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("on", "remote-only", "off", "status")]
    [string]$Command = "remote-only",

    [string]$DotfilesRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CopilotHome = (Join-Path $HOME ".copilot")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sourceInstructions = Join-Path $DotfilesRoot "copilot\copilot-instructions.md"
$remoteInstructionsSource = Join-Path $DotfilesRoot "copilot\blackbird-remote-only.md"
$generatedDirectory = Join-Path $CopilotHome ".dotfiles"
$remoteInstructions = Join-Path $generatedDirectory "copilot-instructions.blackbird-remote-only.md"
$offInstructions = Join-Path $generatedDirectory "copilot-instructions.blackbird-off.md"
$liveInstructions = Join-Path $CopilotHome "copilot-instructions.md"
$skillsRoot = Join-Path $CopilotHome "skills"
$blackbirdSkill = Join-Path $skillsRoot "blackbird"
$filesetSkill = Join-Path $skillsRoot "blackbird-fileset"

function Get-NormalizedPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
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

function Get-ManagedInstructionsTarget {
    $item = Get-ExistingItem $liveInstructions
    if ($null -eq $item) {
        return $null
    }

    $currentTarget = Get-LinkTarget $liveInstructions
    if ($null -eq $currentTarget) {
        throw "Refusing to replace real file: $liveInstructions"
    }

    $allowedTargets = @(
        (Get-NormalizedPath $sourceInstructions),
        (Get-NormalizedPath $remoteInstructions),
        (Get-NormalizedPath $offInstructions)
    )
    if ($currentTarget -notin $allowedTargets) {
        throw "Refusing to replace unexpected link: $liveInstructions -> $currentTarget"
    }
    return $currentTarget
}

function Set-InstructionsLink([string]$Target) {
    $targetPath = Get-NormalizedPath $Target
    $currentTarget = Get-ManagedInstructionsTarget
    if ($currentTarget -eq $targetPath) {
        return
    }
    if ($null -ne $currentTarget) {
        Remove-Item -LiteralPath $liveInstructions -Force
    }

    New-Item -ItemType Directory -Path $CopilotHome -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $liveInstructions -Target $targetPath -ErrorAction Stop | Out-Null
}

function Write-GeneratedInstructions([string]$Mode, [string]$Destination) {
    $content = Get-Content -LiteralPath $sourceInstructions -Raw
    $section = [regex]::new('(?ms)^## Code Discovery\r?\n.*?(?=^## )')
    if ($section.Matches($content).Count -ne 1) {
        throw "Expected exactly one Code Discovery section in $sourceInstructions"
    }

    $replacement = ""
    if ($Mode -eq "remote-only") {
        if (-not (Test-Path -LiteralPath $remoteInstructionsSource -PathType Leaf)) {
            throw "Remote-only instructions not found: $remoteInstructionsSource"
        }
        $replacement = (Get-Content -LiteralPath $remoteInstructionsSource -Raw).TrimEnd(
            [char[]]"`r`n"
        ) + [Environment]::NewLine + [Environment]::NewLine
    }

    New-Item -ItemType Directory -Path $generatedDirectory -Force | Out-Null
    $temporary = "$Destination.$PID.tmp"
    try {
        [IO.File]::WriteAllText(
            $temporary,
            $section.Replace($content, $replacement, 1),
            [Text.UTF8Encoding]::new($false)
        )
        Move-Item -LiteralPath $temporary -Destination $Destination -Force
    } finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    }
}

function Remove-Skill([string]$Path) {
    $item = Get-ExistingItem $Path
    if ($null -eq $item) {
        return
    }

    if ([string]::IsNullOrEmpty($item.LinkType)) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    } else {
        Remove-Item -LiteralPath $Path -Force
    }
}

function Install-BlackbirdSkills {
    if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "gh is required but was not found in PATH"
    }

    & gh blackbird skills install --dir $skillsRoot
    if ($LASTEXITCODE -ne 0) {
        throw "gh blackbird skills install failed"
    }
}

function Remove-GeneratedInstructions([string[]]$Keep = @()) {
    foreach ($path in @($remoteInstructions, $offInstructions)) {
        if ($path -notin $Keep) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }

    if ((Test-Path -LiteralPath $generatedDirectory -PathType Container) -and
        @(Get-ChildItem -LiteralPath $generatedDirectory -Force).Count -eq 0) {
        Remove-Item -LiteralPath $generatedDirectory
    }
}

function Get-InstructionsMode {
    $item = Get-ExistingItem $liveInstructions
    if ($null -eq $item) {
        return "missing"
    }

    $target = Get-LinkTarget $liveInstructions
    if ($null -eq $target) {
        return "real-file"
    }
    if ($target -eq (Get-NormalizedPath $sourceInstructions)) {
        return "on"
    }
    if ($target -eq (Get-NormalizedPath $remoteInstructions)) {
        if (Test-Path -LiteralPath $remoteInstructions -PathType Leaf) {
            return "remote-only"
        }
        return "broken-remote-only"
    }
    if ($target -eq (Get-NormalizedPath $offInstructions)) {
        if (Test-Path -LiteralPath $offInstructions -PathType Leaf) {
            return "off"
        }
        return "broken-off"
    }
    return "other-link"
}

function Show-Status {
    $instructions = Get-InstructionsMode
    $blackbird = Test-Path -LiteralPath (Join-Path $blackbirdSkill "SKILL.md") -PathType Leaf
    $fileset = Test-Path -LiteralPath (Join-Path $filesetSkill "SKILL.md") -PathType Leaf

    if ($instructions -eq "on" -and $blackbird -and $fileset) {
        Write-Host "Blackbird: on"
        return
    }
    if ($instructions -eq "remote-only" -and $blackbird -and -not $fileset) {
        Write-Host "Blackbird: remote-only"
        return
    }
    if ($instructions -eq "off" -and -not $blackbird -and -not $fileset) {
        Write-Host "Blackbird: off"
        return
    }

    Write-Host "Blackbird: inconsistent (instructions=$instructions; blackbird=$blackbird; blackbird-fileset=$fileset)"
    exit 1
}

if (-not (Test-Path -LiteralPath $sourceInstructions -PathType Leaf)) {
    throw "Copilot instructions not found: $sourceInstructions"
}

switch ($Command) {
    "on" {
        [void](Get-ManagedInstructionsTarget)
        Install-BlackbirdSkills
        Set-InstructionsLink $sourceInstructions
        Remove-GeneratedInstructions
        Write-Host "Blackbird: on"
    }
    "remote-only" {
        [void](Get-ManagedInstructionsTarget)
        Write-GeneratedInstructions "remote-only" $remoteInstructions
        Install-BlackbirdSkills
        Remove-Skill $filesetSkill
        Set-InstructionsLink $remoteInstructions
        Remove-GeneratedInstructions @($remoteInstructions)
        Write-Host "Blackbird: remote-only"
    }
    "off" {
        [void](Get-ManagedInstructionsTarget)
        Write-GeneratedInstructions "off" $offInstructions
        Remove-Skill $blackbirdSkill
        Remove-Skill $filesetSkill
        Set-InstructionsLink $offInstructions
        Remove-GeneratedInstructions @($offInstructions)
        Write-Host "Blackbird: off"
    }
    "status" {
        Show-Status
    }
}
