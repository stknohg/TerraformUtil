<#
.SYNOPSIS
    Get installed "terraform" alias
#>
function Get-TFInstalledAlias {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Current', Mandatory = $false)]
        [Switch]$Current
    )

    # Check Alias path
    $ailasAppPath = GetTFAliasAppPath
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        Write-Warning ("Alias path {0} not found." -f $ailasAppPath)
        Write-Warning "Do Set-TFAlias -Initialize first."
        return
    }

    # Get current version
    $currentVersion = GetCurrentAliasVersion

    # Get installed versions
    $installedVersions = Get-ChildItem -LiteralPath $ailasAppPath -Directory | ForEach-Object {
        try {
            [TFAliasVersion]::new(
                $(if ($currentVersion -and "$currentVersion" -eq $_.Name) { $true } else { $false }),
                [semver]($_.Name),
                $(Join-Path $_.FullName (GetTerraformBinaryName))
            )
        } catch {
            # do nothing
        }
    }
    switch ($PSCmdlet.ParameterSetName) {
        'Current' {
            $installedVersions | Where-Object { $_.Current }
            return
        }
        Default {
            $installedVersions | Sort-Object Version -Descending
        }
    }
}

function GetCurrentAliasVersion () {
    $verFilePath = GetTFAliasVersionFilePath
    if (-not (Test-Path -LiteralPath $verFilePath -PathType Leaf)) {
        return
    }
    try {
        return [semver]@(Get-Content -LiteralPath $verFilePath)[0]
    } catch {
        # do nothing
    }
}