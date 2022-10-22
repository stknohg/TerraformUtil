#!/usr/bin/env pwsh
#Requires -Version 5.0
Set-StrictMode -Version 3.0
# Redirect Windows PowerShell to PowerShell 7
if ($PSVersionTable.PSVersion.Major -le 5) {
    pwsh -NonInteractive -NoProfile -Command "$($Script:MyInvocation.MyCommand.Path)" $script:args
    exit $LASTEXITCODE
}
<#
    tfalias.ps1 : TerraformUtil for command prompt
#>

function ShowHelp () {
    @"
tfalias

Usage:
  tfalias use [version]  Install and use a specific version of Terraform
  tfalias list           List installed Terraform versions
  tfalias list-remote    List all installable versions
  tfalias uninstall      Uninstall a specific version of Terraform
  tfalias pin            Write current version to .terraform-version file
  tfalias --version      Show version

Example
  C:\> tfalias use latest
  C:\> tfalias use 1.2.3
  C:\> tfalias list
  C:\> tfalias list-remote
  C:\> tfalias uninstall 1.2.3
  C:\> tfalias pin
"@ | Out-Host
}

function ShowVersion () {
    # Note : loading module is slow, so separeted --version command.
    "tfalias ver.{0}" -f (Get-InstalledModule TerraformUtil).Version | Out-Host
}

function Main () {
    $command, $commandArgs = $script:args -split ' '
    if ($null -eq $command) {
        ShowHelp
        return
    }
    switch ($command) {
        'use' {
            if ($null -eq $commandArgs) {
                ShowHelp
                return
            }
            switch (@($commandArgs)[0]) {
                'latest' {
                    Set-TFAlias -Latest
                }
                Default {
                    try {
                        $ver = [semver](@($commandArgs)[0])
                        Set-TFAlias -Version $ver
                    } catch {
                        Write-Warning "Failed to parse version."
                    }
                }
            }
            return
        }
        'uninstall' {
            if ($null -eq $commandArgs) {
                ShowHelp
                return
            }
            try {
                $ver = [semver](@($commandArgs)[0])
                Uninstall-TFAlias -Version $ver
            } catch {
                Write-Warning "Failed to parse version."
            }
            return
        }
        'list' {
            if ( @($commandArgs).Where({ $_ -eq '--json' })) {
                Get-TFInstalledAlias | ForEach-Object { [PSCustomObject]@{ Current = $_.Current; Version = $_.Version.ToString(); Path = $_.Path } } | ConvertTo-Json
                return
            }
            Get-TFInstalledAlias | ForEach-Object { "{0} {1}" -f $(if ($_.Current) { '*' } else { ' ' }), ($_.Version.ToString()) }
            return
        }
        'list-remote' {
            if ( @($commandArgs).Where({ $_ -eq '--json' })) {
                Find-TFVersion | ForEach-Object { [PSCustomObject]@{ Version = $_.ToString() } } | ConvertTo-Json
                return
            }
            Find-TFVersion | ForEach-Object { $_.ToString() }
            return
        }
        'pin' {
            Set-TFAlias -Pin
            return
        }
        { $_ -in ('--version', '-V') } {
            ShowVersion
            return
        }
        Default {
            ShowHelp
            return
        }
    }
}

# Start main
Main
