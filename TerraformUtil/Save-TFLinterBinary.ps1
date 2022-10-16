#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Save the specific version tflint binary file.
#>
function Save-TFLinterBinary {
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
        InvokeGitHubReleaseAPI -Owner 'terraform-linters' -Repository 'tflint' -Release "v$Version"
    } else {
        InvokeGitHubReleaseAPI -Owner 'terraform-linters' -Repository 'tflint' -Release 'latest'
    }
    if (-not $response) {
        Write-Error "Failed to get tflint release information."
        return 
    }

    $versionTag = $response.tag_name
    WriteInfo ("Find tflint {0}." -f $versionTag)
    $downloadUrl = GetBinaryUrlFromResponse -Response $response
    if (-not $downloadUrl) {
        Write-Error "Failed to find download url."
        return
    }
    
    # download and expand zip archive
    $tempPath = GetTempPath
    $zipFileName = $downloadUrl.split("/")[-1]
    $zipFullPath = Join-Path $tempPath -ChildPath $zipFileName 
    try {
        # download
        Write-Verbose ("Download {0}" -f ($downloadUrl))
        Write-Verbose ("  to {0}" -f ($zipFullPath))
        $client = $null
        try {
            $client = [System.Net.WebClient]::new() 
            $client.DownloadFile($downloadUrl, $zipFullPath)
        } finally {
            $client.Dispose()
        }
        # expand
        Write-Verbose ("Expand {0} to {1}" -f $zipFileName, $DestinationPath)
        Expand-Archive -LiteralPath $zipFullPath -DestinationPath $DestinationPath -Force
        # chmod 
        if (-not $IsWindows) {
            Write-Verbose ("chmod +x {0}" -f (Join-Path $DestinationPath 'tflint'))
            chmod +x (Join-Path $DestinationPath 'tflint')
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

function GetBinaryUrlFromResponse ($Response) {
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
    
    $queryString = "^.+${osName}_${cpuArchitecture}.zip$"
    return $response.assets.browser_download_url | Where-Object { $_ -match $queryString }
}