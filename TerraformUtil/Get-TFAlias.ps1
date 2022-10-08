<#
.SYNOPSIS
    Get installed "terraform" alias
#>
function Get-TFAlias {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Current', Mandatory = $false)]
        [Switch]$Current
    )

    # Check Alias path
    $aliasRoot = GetTFAliasRoot
    $ailasAppPath = Join-Path $aliasRoot 'terraform'
    if (-not (Test-Path -LiteralPath $aliasRoot -PathType Container)) {
        Write-Warning ("Alias path {0} not found. Do nothing." -f $aliasRoot)
        return
    }
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        Write-Warning ("Alias path {0} not found. Do nothing." -f $ailasAppPath)
        return
    }

    # Get current alias
    $currentAlias = Get-Alias terraform -ErrorAction SilentlyContinue

    # Get installed versions
    $installedVersions = Get-ChildItem -LiteralPath $ailasAppPath -Directory | ForEach-Object {
        try {
            [PSCustomObject]@{
                Current = if ($currentAlias -and (Split-Path (Get-Alias terraform -ErrorAction SilentlyContinue).Definition) -eq $_.FullName) { $true } else { $false }
                Version = [semver]($_.Name)
                Path    = Join-Path $_.FullName (GetTerraformBinaryName)
            }
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