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
            @'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
'@
            break
        }
    }

    if ($Save) {
        WriteInfo 'Save configuration to ".tflint.hcl".'
        $content | Out-File -FilePath './.tflint.hcl' -NoNewline
        return
    }
    Write-Output $content
}

function GetPluginLatestVersion ([string]$Plugin) {
    $response = switch ($Plugin) {
        'AWS' {
            InvokeGitHubReleaseAPI -Owner 'terraform-linters' -Repository 'tflint-ruleset-aws' -Release 'latest'
            break
        }
        'AzureRM' {
            InvokeGitHubReleaseAPI -Owner 'terraform-linters' -Repository 'tflint-ruleset-azurerm' -Release 'latest'
            break
        }
        'Google' {
            InvokeGitHubReleaseAPI -Owner 'terraform-linters' -Repository 'tflint-ruleset-google' -Release 'latest'
            break
        }
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