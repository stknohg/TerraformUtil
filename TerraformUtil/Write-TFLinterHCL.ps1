#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Output a basic configuration for .tflint.hcl
#>
function Write-TFLinterHCL {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default', Mandatory = $true)]
        [ValidateSet('Terraform', 'AWS', 'AzureRM', 'Google')]
        [string]$Plugin,
        [Parameter(ParameterSetName = 'Default', Mandatory = $false)]
        [Switch]$Save
    )

    $content = switch ($Plugin) {
        'AWS' {
            @'
plugin "aws" {{
  enabled = true
  version = "{0}"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}}
'@ -f (GetPluginLatestVersion -Plugin $_)
            break
        }
        'AzureRM' {
            @'
plugin "azurerm" {{
  enabled = true
  version = "{0}"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}}
'@ -f (GetPluginLatestVersion -Plugin $_)
            break
        }
        'Google' {
            @'
plugin "google" {{
  enabled = true
  version = "{0}"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}}
'@ -f (GetPluginLatestVersion -Plugin $_)
            break
        }
        Default {
            return @'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
'@
        }
    }

    if ($Save) {
        WriteInfo 'Save configuration to ".tflnt.hcl".'
        $content | Out-File -FilePath './.tflint.hcl'
        return
    }
    Write-Output $content
}

function GetPluginLatestVersion ([string]$Plugin) {
    $uri = switch ($Plugin) {
        'AWS' {
            'https://api.github.com/repos/terraform-linters/tflint-ruleset-aws/releases/latest'
        }
        'AzureRM' {
            'https://api.github.com/repos/terraform-linters/tflint-ruleset-azurerm/releases/latest'
        }
        'Google' {
            'https://api.github.com/repos/terraform-linters/tflint-ruleset-google/releases/latest'
        }
    }
    try {
        Write-Verbose "Invoke-RestMethod to $uri"
        $response = Invoke-RestMethod -Uri $uri -Headers @{ Accept = 'application/vnd.github.v3+json' }
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Warning ("StatusCode : {0} {1}" -f [int]$_.Exception.Response.StatusCode, $_)
    } catch {
        Write-Error $_
        return
    }
    if (-not $response) {
        Write-Error "Failed to get tflint rules release information."
        return 
    }

    # Get version from tag.
    Write-Verbose ('Find version tag : {0}' -f $response.tag_name)
    try {
        return [semver]($response.tag_name -split 'v')[1]
    } catch {
        Write-Error $_
        Write-Warning "Failed to get plugin version."
        return "0.0.0"
    }
}