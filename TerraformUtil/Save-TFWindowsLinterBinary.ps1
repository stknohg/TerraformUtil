<#
.SYNOPSIS
    Save the specific version Windows tflint binary file.
#>
function Save-TFWindowsLinterBinary {
    [CmdletBinding(DefaultParameterSetName = 'Latest')]
    param (
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Switch]$Latest,
        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [SemVer]$Version,
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [string]$DestinationPath
    )
    # This function is for Windows only.
    if ($IsLinux) {
        Write-Warning @"
This function is supported for Windows only.
You can run following installation script instead.

curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
"@
        return
    }
    if ($IsMacOS) {
        Write-Warning @"
This function is supported for Windows only.
You can use "brew install tflint" instead.
"@
        return
    }
    # Test path
    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-Error "DestinationPath $DestinationPath does not exist."
        return 
    }

    # get the latest release information
    $uri = switch ($PSCmdlet.ParameterSetName) {
        'Latest' {
            'https://api.github.com/repos/terraform-linters/tflint/releases/latest'
        }
        'Version' {
            "https://api.github.com/repos/terraform-linters/tflint/releases/tags/v$Version"
        }
        default {
            'https://api.github.com/repos/terraform-linters/tflint/releases/latest'
        }
    }
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers @{ Accept = 'application/vnd.github.v3+json' }
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error ("StatusCode : {0} {1}" -f  [int]$_.Exception.Response.StatusCode, $_)
        return
    } catch {
        Write-Error $_
        return
    }
    $versionTag = $response.tag_name
    $downloadUrl = if (IsCurrentProcess64bit) {
        $response.assets.browser_download_url | Where-Object {$_ -match "^.+windows_amd64.zip$"}
    } else {
        $response.assets.browser_download_url | Where-Object {$_ -match "^.+windows_386.zip$"}
    }
    WriteInfo ("Find tflint {0}." -f $versionTag)

    # download and expand zip archive
    $tempPath = $env:TEMP
    $zipFileName = $downloadUrl.split("/")[-1]
    $zipFullPath = Join-Path $tempPath -ChildPath $zipFileName 
    try {
        # download
        WriteInfo ("Download {0}" -f ($downloadUrl))
        WriteInfo ("  to {0}" -f ($zipFullPath))
        $client = $null
        try {
            $client = [System.Net.WebClient]::new() 
            $client.DownloadFile($downloadUrl, $zipFullPath)
        } finally {
            $client.Dispose()
        }
        # expand
        WriteInfo ("Expand {0} to {1}" -f $zipFileName, $DestinationPath)
        Expand-Archive -LiteralPath $zipFullPath -DestinationPath $DestinationPath -Force
        # success
        WriteInfo ("Binary file is saved to {0}" -f $DestinationPath)
    } finally {
        if (Test-Path -Path $zipFullPath) {
            WriteInfo ("Remove {0}" -f $zipFullPath)
            Remove-Item -LiteralPath $zipFullPath
        }
    }
}
