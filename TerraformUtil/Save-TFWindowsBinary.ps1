<#
.SYNOPSIS
    Save the specific version Windows Terraform binary file.
#>
function Save-TFWindowsBinary {
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
    if (-not $IsWindows) {
        Write-Warning "This function is supported for Windows only."
        return 
    }
    # Test path
    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-Error "DestinationPath $DestinationPath does not exist."
        return 
    }

    # get release information
    $release = switch ($PSCmdlet.ParameterSetName) {
        'Latest' {
            Find-TFRelease -Latest
        }
        'Version' {
            Find-TFRelease -Version $Version
        }
    }
    if (-not $release) {
        Write-Error "Failed to get Terraform release information."
        return 
    }

    # find windows build url
    $build = if (IsCurrentProcess64bit) {
        $release.Builds | Where-Object { $_.OS -eq 'windows' -and $_.Architecture -eq 'amd64' }
    } else {
        $release.Builds | Where-Object { $_.OS -eq 'windows' -and $_.Architecture -eq '386' }
    }
    Write-Verbose ("Find build URL : {0}" -f ($build.url))
    
    # download and expand zip archive
    $tempPath = $env:TEMP
    $zipFileName = $build.GetFileName()
    $zipFullPath = Join-Path $tempPath -ChildPath $zipFileName
    try {
        # download
        WriteInfo ("Download {0}" -f ($build.Url))
        WriteInfo ("  to {0}" -f ($tempPath))
        $build.Download($tempPath)
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
