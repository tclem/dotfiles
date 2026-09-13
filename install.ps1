#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesRoot = $PSScriptRoot

if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required but was not found in PATH"
}

if ($null -ne (Get-Command gh -ErrorAction SilentlyContinue)) {
    & gh alias import (Join-Path $DotfilesRoot "gh\aliases.yml") --clobber
    if ($LASTEXITCODE -ne 0) {
        throw "gh alias import failed"
    }
} else {
    Write-Warning "gh was not found in PATH; skipping GitHub CLI aliases and external Copilot extensions"
}

$gitConfig = @(
    @("user.name", "Timothy Clem"),
    @("user.email", "timothy.clem@gmail.com"),
    @("github.user", "tclem"),
    @("credential.helper", "manager"),
    @("alias.co", "checkout"),
    @("alias.lo", "log --oneline --decorate"),
    @("alias.lol", "log --oneline --graph --decorate"),
    @("alias.last", "log -1 HEAD"),
    @("pull.rebase", "true"),
    @("push.default", "simple"),
    @("push.autoSetupRemote", "true"),
    @("push.followTags", "true"),
    @("branch.sort", "-committerdate"),
    @("tag.sort", "version:refname"),
    @("init.defaultBranch", "main"),
    @("diff.algorithm", "histogram"),
    @("diff.colorMoved", "plain"),
    @("diff.mnemonicPrefix", "true"),
    @("diff.renames", "true"),
    @("fetch.prune", "true"),
    @("fetch.pruneTags", "true"),
    @("fetch.all", "true"),
    @("commit.verbose", "true"),
    @("rerere.enabled", "true"),
    @("rerere.autoupdate", "true"),
    @("core.fsmonitor", "true"),
    @("core.untrackedCache", "true")
)

& git config --global --unset-all alias.first 2>$null

foreach ($entry in $gitConfig) {
    & git config --global $entry[0] $entry[1]
    if ($LASTEXITCODE -ne 0) {
        throw "git config failed for $($entry[0])"
    }
}

& (Join-Path $DotfilesRoot "script\sync-copilot.ps1") install

Write-Host "Windows dotfiles installed." -ForegroundColor Green
