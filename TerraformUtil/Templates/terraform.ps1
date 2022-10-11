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

# Check .terraform-version file
# Note : must use Test-Path to resolve relative path.
$testPath = $pwd.Path
do {
    if (Test-Path -Path ([System.IO.Path]::Join($testPath, '.terraform-version')) -PathType Leaf) {
        break
    }
    $testPath = [System.IO.Path]::GetDirectoryName($testPath)
} while (-not [string]::IsNullOrEmpty($testPath))
if (-not [string]::IsNullOrEmpty($testPath)) {
    Write-Verbose ('.terraform-version is detected at {0}' -f $testPath)
    $fileVersion = Get-TFVersionFromFile -LiteralPath ([System.IO.Path]::Join($testPath, '.terraform-version'))
    if (-not $fileVersion) {
        Write-Warning '.terraform-version is detected, but failed to parse.'
    } else {
        if ($currentVersion -ne $fileVersion) {
            Write-Host ('Preferred version.{0} is detected from {1}.' -f $fileVersion, ([System.IO.Path]::Join($testPath, '.terraform-version'))) -ForegroundColor Yellow
            Set-TFAlias -Version $fileVersion
            $currentVersion = $fileVersion
        }
    }
}

# Get Terraform binary path
$binaryName = if ($IsWindows) { 'terraform.exe' } else { 'terraform' }
$binaryPath = [System.IO.Path]::Join($aliasAppPath, $currentVersion, $binaryName)

# Invoke Terraform binary
& "$binaryPath" $args
