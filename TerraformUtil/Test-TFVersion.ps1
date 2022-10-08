<#
.SYNOPSIS
    Test current Terraform is the latest version.
#>
function Test-TFVersion {
    [CmdletBinding()]
    param (
        [switch]$PassThru
    )
    if ( -not (IsTerraformInstalled) ) {
        Write-Warning "Failed to find 'terraform' command."
        return
    }

    # get versions
    $currentVersion = GetInstalledTerraformVersion
    try {
        $latestVersion = Find-TFRelease -Latest | Select-Object -ExpandProperty Version
    } catch {
        Write-Error "Failed to get the latest Terraform version."
        return
    }
    # compare
    if ($currentVersion -gt $latestVersion) {
        if ($PassThru) {
            return [PSCustomObject]@{ Result = $true; CurrentVersion = $currentVersion; LatestVersion = $latestVersion }
        }
        WriteInfo ("Terraform v{0} is newer than the latest version v{1}." -f $currentVersion, $latestVersion)
        return
    }
    if ($currentVersion -eq $latestVersion) {
        if ($PassThru) {
            return [PSCustomObject]@{ Result = $true; CurrentVersion = $currentVersion; LatestVersion = $latestVersion }
        }
        WriteInfo ("Terraform v{0} is the latest version." -f $currentVersion)
        return
    }
    if ($PassThru) {
        return [PSCustomObject]@{ Result = $false; CurrentVersion = $currentVersion; LatestVersion = $latestVersion }
    }
    WriteInfo ("Newer version Terraform v{0} is available. (Current : v{1})" -f $latestVersion, $currentVersion)
}
