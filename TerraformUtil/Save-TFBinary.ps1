<#
.SYNOPSIS
    Save the specific version Terraform binary file.
#>
function Save-TFBinary {
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

    # find build url
    $build = GetBuildFromRelease -Release $release
    if (-not $build) {
        Write-Error "Failed to get release build."
        return
    }
    Write-Verbose ("Find build URL : {0}" -f ($build.url))
    
    # download and expand zip archive
    $tempPath = GetTempPath
    $zipFileName = $build.GetFileName()
    $zipFullPath = Join-Path $tempPath -ChildPath $zipFileName
    try {
        # download
        Write-Verbose ("Download {0}" -f ($build.Url))
        Write-Verbose ("  to {0}" -f ($tempPath))
        $build.Download($tempPath)
        # expand
        Write-Verbose ("Expand {0} to {1}" -f $zipFileName, $DestinationPath)
        Expand-Archive -LiteralPath $zipFullPath -DestinationPath $DestinationPath -Force
        # chmod 
        if (-not $IsWindows) {
            Write-Verbose ("chmod +x {0}" -f (Join-Path $DestinationPath 'terraform'))
            chmod +x (Join-Path $DestinationPath 'terraform')
        }
        # success
        WriteInfo ("Binary file is saved to {0}" -f $DestinationPath)
    } finally {
        if (Test-Path -LiteralPath $zipFullPath -PathType Leaf) {
            Write-Verbose ("Remove {0}" -f $zipFullPath)
            Remove-Item -LiteralPath $zipFullPath
        }
    }
}

function GetBuildFromRelease ([TerraformRelease]$Release) {
    # get OS name
    $osName = if ($IsMacOS) { 'darwin' } elseif ($IsLinux) { 'linux' } else { 'windows' }
    Write-Verbose ("OS : {0}" -f $osName)

    # get cpu architecture
    $cpuArchitecture = $null
    # is arm
    if ($IsWindows) {
        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            $cpuArchitecture = 'arm64'
        }
    } else {
        if ((uname -m) -match '(arm64.*|aarch64.*)') {
            $cpuArchitecture = 'arm64'
        }
    }
    # amd64 or i386
    if (-not $cpuArchitecture) {
        $cpuArchitecture = if (IsCurrentProcess64bit) { 'amd64' } else { '386' }
    }
    Write-Verbose ("CPU Archetecture : {0}" -f $cpuArchitecture)
    
    return $Release.Builds | Where-Object { $_.OS -eq $osName -and $_.Architecture -eq $cpuArchitecture }
}
