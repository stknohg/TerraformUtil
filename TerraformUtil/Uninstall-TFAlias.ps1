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
        $ailasAppPath = GetTFAliasAppPath
        if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
            Write-Warning ("Alias path {0} not found." -f $ailasAppPath)
            Write-Warning "Do Set-TFAlias -Initialize first."
            return
        }

        # Get version path
        $versionPath = [System.IO.Path]::Join( $ailasAppPath, "$Version")
        if (-not(Test-Path -LiteralPath $versionPath -PathType Container) ) {
            Write-Warning ("Terraform v{0} is not installed." -f $Version)
            return
        }

        # Uninstall
        $currentAlias = Get-TFAlias -Current
        Writeinfo ('Uninstall Terraform v{0}' -f $Version)
        # remove directory
        Remove-Item -LiteralPath $versionPath -Recurse -ErrorAction SilentlyContinue
        # remove alias
        if ($currentAlias -and $currentAlias.Version -eq $Version) {
            Write-Verbose "Remove version file."
            UninstallVersionFile
        }
    }
}

function UninstallVersionFile () {
    $versionFilePath = GetTFAliasVersionFilePath
    if (Test-Path -LiteralPath $versionFilePath -PathType Leaf) {
        Remove-Item -LiteralPath $versionFilePath
    }
}