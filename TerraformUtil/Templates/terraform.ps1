#!/usr/bin/env pwsh
#Requires -Version 7.0.0
#Requires -Modules TerraformUtil
Set-StrictMode -Version 3.0
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
if (Test-Path -Path './.terraform-version' -PathType Leaf) {
    $fileVersion = Get-TFVersionFromFile
    if (-not $fileVersion) {
        Write-Warning '.terraform-version is detected, but failed to parse.'
    } else {
        if ($currentVersion -ne $fileVersion) {
            Write-Host ('Preferred version.{0} is detected from .terraform-version' -f $fileVersion) -ForegroundColor Yellow
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
