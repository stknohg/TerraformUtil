<#
.SYNOPSIS
    Get Terraform version from ".terraform-version" file.
    This function is mainly for internal use.
#>
function Get-TFVersionFromFile {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default', Mandatory = $false)]
        [string]$LiteralPath = './.terraform-version'
    )
    if ([string]::IsNullOrEmpty($LiteralPath)) {
        $LiteralPath = './.terraform-version'
    }
    # Test path
    if (-not (Test-Path -LiteralPath $LiteralPath)) {
        Write-Warning ('{0} not found.' -f $LiteralPath)
        return
    }

    # TODO : implement more formal parser
    $rowString = @(Get-Content -LiteralPath $LiteralPath)[0].Trim()
    if ('latest-allowed' -eq $rowString) {
        # TODO
        Write-Warning 'latest-allowed is not supported.'
        return 
    }
    if ('min-required' -eq $rowString) {
        # TODO
        Write-Warning 'min-required is not supported.'
        return 
    }
    if ('latest' -eq $rowString) {
        Write-Verbose 'Detect the latest version'
        return (Find-TFRelease -Latest).Version
    }
    if ($rowString -match '^latest:(?<match_exp>.+)$' ) {
        $matchExp = $Matches.match_exp
        Write-Verbose ("version match expression : {0}" -f $matchExp)
        # exclude prerelease
        $matchVersion = Find-TFVersion -Filter { "$_" -match $matchExp -and (-not $_.PreReleaseLabel) } -Take 1
        if (-not $matchVersion) {
            Write-Warning ('Failed to detect Terraform version. (expression = {0})' -f $matchExp)
            return
        }
        Write-Verbose ('Detect version {0}' -f $matchVersion)
        return $matchVersion
    }
    try {
        $version = [semver]$rowString
        Write-Verbose ('Detect version {0}' -f $version)
        return $version
    } catch {
        # do nothing
    }
    Write-Warning ('Failed to parse .terraform-version : {0}' -f $rowString)
}
