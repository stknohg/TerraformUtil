#!/usr/bin/env pwsh
#Requires -Version 5.0.0
Set-StrictMode -Version 3.0
# Redirect Windows PowerShell to PowerShell 7
if ($PSVersionTable.PSVersion.Major -le 5) {
    pwsh -NonInteractive -NoProfile -Command "$($Script:MyInvocation.MyCommand.Path)" $args
    exit $LASTEXITCODE
}
<#
    terraform.ps1 : Shim for terraform binary.
#>
$rootPath = [System.IO.Path]::GetDirectoryName($Script:MyInvocation.MyCommand.Path)
$aliasAppPath = [System.IO.Path]::Join([System.IO.Path]::GetDirectoryName($rootPath), 'terraform')

# Get current version
$verFilePath = [System.IO.Path]::Join($aliasAppPath, 'version')
if (-not [System.IO.File]::Exists($verFilePath)) {
    Write-Warning 'Failed to find current Terraform vesion.'
    Write-Warning 'Do Set-TFAlias -Initialize first.'
    return 
}
$currentVersion = [semver]@([System.IO.File]::ReadAllLines($verFilePath))[0]
Write-Verbose ('Detect currnent version : {0}' -f $currentVersion)

# Check if -chdir parameter selected
$chdirPath = ''
$chdirArg = $args.Where({ $_.StartsWith('-chdir=') -and $_.Length -gt 7 }) | Select-Object -First 1 # Note : '-chdir='.Length = 7
if ($chdirArg) {
    try {
        Write-Verbose ('-chdir parameter detect : {0}' -f $chdirArg)
        $chdirPath = Resolve-Path -LiteralPath ($chdirArg.Substring(7)) -ErrorAction Stop | Select-Object -ExpandProperty Path
    } catch {
        Write-Warning ('Failed to parse -chdir parameter. ({0})' -f $_)
    }
}

# Check .terraform-version file
# Note.1 : tfenv searches .terraform-version in two phases, from $pwd recursively and from $HOME recursively.
#          But terraform.ps1 does not search $HOME recursively, this is intentional.
# Note.2 : Must use Test-Path to resolve relative path.
$testPath = if (-not [string]::IsNullOrEmpty($chdirPath)) { $chdirPath } else { $pwd.Path }
do {
    Write-Verbose ('Seacrh .terraform-version : {0}' -f $testPath)
    if (Test-Path -Path ([System.IO.Path]::Join($testPath, '.terraform-version')) -PathType Leaf) {
        break
    }
    $testPath = [System.IO.Path]::GetDirectoryName($testPath)
} while (-not [string]::IsNullOrEmpty($testPath))
if ([string]::IsNullOrEmpty($testPath)) {
    Write-Verbose ('Seacrh .terraform-version : {0}' -f $HOME)
    if (Test-Path -Path ([System.IO.Path]::Join($HOME, '.terraform-version')) -PathType Leaf) {
        $testPath = $HOME
    }
}
if (-not [string]::IsNullOrEmpty($testPath)) {
    Write-Verbose ('.terraform-version is detected at {0}' -f $testPath)
    $fileVersion = Get-TFVersionFromFile -LiteralPath ([System.IO.Path]::Join($testPath, '.terraform-version'))
    if (-not $fileVersion) {
        Write-Warning '.terraform-version is detected, but failed to parse.'
    } else {
        if ($currentVersion -ne $fileVersion) {
            Write-Warning ('Preferred version.{0} is detected from {1}.' -f $fileVersion, ([System.IO.Path]::Join($testPath, '.terraform-version')))
            Write-Warning ('Override version {0} to {1}' -f $currentVersion, $fileVersion)
            Set-TFAlias -Version $fileVersion -Force
            $currentVersion = $fileVersion
        }
    }
}
Write-Verbose ('Decided version : {0}' -f $currentVersion)

# Get Terraform binary path
$binaryName = if ($IsWindows) { 'terraform.exe' } else { 'terraform' }
$binaryPath = [System.IO.Path]::Join($aliasAppPath, $currentVersion, $binaryName)

# Invoke Terraform binary
Write-Verbose ('Invoke terraform : {0}' -f $binaryPath)
& "$binaryPath" $args
