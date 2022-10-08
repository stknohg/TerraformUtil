<#
.SYNOPSIS
    Uninstall "terraform" alias
#>
function Uninstall-TFAlias {
    [CmdletBinding(DefaultParameterSetName = 'Version')]
    param (
        [Parameter(ParameterSetName = 'Version', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [semver]$Version
    )
    process {
        # for when $null is piped
        if ($null -eq $Version) {
            return
        }
        Write-Verbose ('Start uninstall Terraform v{0}' -f $Version)

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

        # Get version path
        $versionPath = Join-Path $ailasAppPath "$Version"
        if (-not(Test-Path -LiteralPath $versionPath -PathType Container) ) {
            Write-Warning ("Terraform v{0} is not installed." -f $Version)
            return
        }

        # Uninstall
        Writeinfo ('Uninstall Terraform v{0}' -f $Version)
        # remove directory
        Remove-Item -LiteralPath $versionPath -Recurse -ErrorAction SilentlyContinue
        # remove alias
        $currentAlias = Get-Alias terraform -ErrorAction SilentlyContinue
        if ($currentAlias -and (Split-Path (Get-Alias terraform -ErrorAction SilentlyContinue).Definition) -eq $versionPath) {
            Write-Verbose "Do Remove-Alias -Name 'terraform' -Scope Global"
            Remove-Alias -Name 'terraform' -Scope Global
        }
    }
}