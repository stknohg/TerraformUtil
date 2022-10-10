#!/usr/bin/env pwsh
#Requires -Version 7.0.0
#Requires -Modules TerraformUtil
Set-StrictMode -Version 3.0
<#
    tfalias.ps1 : TerraformUtil for command prompt
#>

function ShowHelp () {
    @"
tfalias ver.{0}

Usage:
  tfalias use [version]  Install and use a specific version of Terraform
  tfalias list           List installed Terraform versions
  tfalias list-remote    List all installable versions
  tfalias uninstall      Uninstall a specific version of Terraform

Example
  C:\> tfalias use latest
  C:\> tfalias use 1.2.3
  C:\> tfalias list
  C:\> tfalias list-remote
  C:\> tfalias uninstall 1.2.3
"@ -f (Get-Module TerraformUtil).Version | Out-Host
}

function Main () {
    $command, $commandArgs = $args -split ' '
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
            Get-TFAlias | ForEach-Object {
                "{0} {1}" -f $(if ($_.Current) { '*' } else { ' ' }), ($_.Version.ToString())
            }
        }
        'list-remote' {
            Find-TFVersion | ForEach-Object { $_.ToString() }
        }
        Default {
            ShowHelp
            return
        }
    }
}

# Start main
Main $args
