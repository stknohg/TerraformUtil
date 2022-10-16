#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Save the specific version tfsec binary file.
#>
function Save-TFSecBinary {
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

    # get the latest release information
    $response = if ($PSCmdlet.ParameterSetName -eq 'Version') {
        InvokeGitHubReleaseAPI -Owner 'aquasecurity' -Repository 'tfsec' -Release "v$Version"
    } else {
        InvokeGitHubReleaseAPI -Owner 'aquasecurity' -Repository 'tfsec' -Release 'latest'
    }
    if (-not $response) {
        Write-Error "Failed to get tfsec release information."
        return 
    }

    $versionTag = $response.tag_name
    WriteInfo ("Find tfsec {0}." -f $versionTag)
    $downloadUrl = GetTFsecBinaryUrlFromResponse -Response $response
    if (-not $downloadUrl) {
        Write-Error "Failed to find download url."
        return
    }
    
    # download binary
    $binaryFileName = if ($IsWindows) { 'tfsec.exe' } else { 'tfsec' }
    $binaryFullPath = [System.IO.Path]::Join($DestinationPath, $binaryFileName)
    try {
        # download direct
        Write-Verbose ("Download {0}" -f ($downloadUrl))
        Write-Verbose ("  to {0}" -f ($binaryFullPath))
        $client = $null
        try {
            $client = [System.Net.WebClient]::new() 
            $client.DownloadFile($downloadUrl, $binaryFullPath)
        } finally {
            $client.Dispose()
        }
        # chmod 
        if (-not $IsWindows) {
            Write-Verbose ("chmod +x {0}" -f $binaryFullPath)
            chmod +x $binaryFullPath
        }
        # success
        WriteInfo ("Binary file is saved to {0}" -f $DestinationPath)
    } catch {
        Write-Error $_
    }
}

function GetTFsecBinaryUrlFromResponse ($Response) {
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
    
    $queryString = "^.+tfsec-${osName}-${cpuArchitecture}(.exe)*$"
    return $response.assets.browser_download_url | Where-Object { $_ -match $queryString }
}