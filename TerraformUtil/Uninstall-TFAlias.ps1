#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
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
        $currentAlias = Get-TFInstalledAlias -Current
        Writeinfo ('Uninstall Terraform v{0}' -f $Version)
        # remove directory
        Remove-Item -LiteralPath $versionPath -Recurse -ErrorAction SilentlyContinue
        # remove version file when current version removed.
        if ($currentAlias -and $currentAlias.Version -eq $Version) {
            Write-Verbose "Remove current version file."
            UninstallVersionFile
            # To prevent auto-completer shows warning message, need UnRegister-TFArgumentCompleter.
            # ( Auto-completer shows "Failed to find current Terraform vesion." )
            Write-Verbose "Unregister auto-complete"
            UnRegister-TFArgumentCompleter
        }
    }
}

function UninstallVersionFile () {
    $versionFilePath = GetTFAliasVersionFilePath
    if (Test-Path -LiteralPath $versionFilePath -PathType Leaf) {
        Remove-Item -LiteralPath $versionFilePath
    }
}