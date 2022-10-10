<#
.SYNOPSIS
    Set the "terraform" alias like tfenv
#>
function Set-TFAlias {
    [CmdletBinding(DefaultParameterSetName = 'Help')]
    param (
        [Parameter(ParameterSetName = 'Initialize', Mandatory = $true)]
        [Switch]$Initialize,
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Switch]$Latest,
        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [semver]$Version,
        [Parameter(ParameterSetName = 'FromVersionFile', Mandatory = $true)]
        [Switch]$FromVersionFile,
        [Parameter(ParameterSetName = 'Help', Mandatory = $false)]
        [Switch]$Help
    )
    switch ($PSCmdlet.ParameterSetName) {
        'Initialize' {
            InvokeTFAliasInitialize
            return
        }
        'Latest' {
            InvokeTFAliasLatestVersion
            return
        }
        'Version' {
            InvokeTFAliasVersion -Version $Version
            return
        }
        'FromVersionFile' {
            InvokeTFAliasFromVersionFile 
            return
        }
        Default {
            ShowHelpMessage
        }
    }
}

function ShowHelpMessage () {
    @"
Set the "terraform" alias like tfenv

Usage:
  -Initialize         Setup TFAlias environment
  -Latast             Set alias to the latest Terraform version
  -Version X.Y.Z      Set alias to Terraform ver.X.Y.Z
  -FromVersionFile    Set alias from .terraform-version file
    * Currently supported "latest", "latest:<regex>", "x.y.z"
  -Help               Show this message

Example:
  PS > Set-TFAlias -Initialize     # Initialize alias
  PS > Set-TFAlias -Latast         # Download latest version and set alias
  PS > terraform version
  Terraform vX.Y.Z
  PS > Set-TFAlias -Version 1.2.3  # Download ver.1.2.3 and set alias
  PS > terraform version
  Terraform v1.2.3
"@ | Out-Host
}

function InvokeTFAliasInitialize([Switch]$Update) {
    $ailasAppPath = GetTFAliasAppPath

    # Check Alias path
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        WriteInfo ("Create path : {0}" -f $ailasAppPath)
        [void](New-Item -Path $ailasAppPath -ItemType Directory)
    }

    # Check current version
    $version = Get-TFAlias -Current
    if ($version) {
        # Set current version silently
        Write-Verbose ('Use current Terraform v{0}.' -f ($version.Version))
        [void](InvokeTFAliasVersion -Version $version.Version *>&1)
        return
    }
    WriteInfo ('Use the latest version of Terraform.')
    InvokeTFAliasLatestVersion
}

function InvokeTFAliasLatestVersion () {
    $ailasAppPath = GetTFAliasAppPath

    # Check Alias path
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        Write-Warning ("Alias path {0} not found." -f $ailasAppPath)
        Write-Warning "Do Set-TFAlias -Initialize first."
        return  
    }

    # get the latest version
    $version = Find-TFRelease -Latest | Select-Object -ExpandProperty Version
    Writeinfo ("Terraform v{0} is the latest version." -f $version)
    InvokeTFAliasVersion -Version $version 
}

function InvokeTFAliasVersion ([semver]$Version) {
    $ailasAppPath = GetTFAliasAppPath

    # Check Alias path
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        Write-Warning ("Alias path {0} not found." -f $ailasAppPath)
        Write-Warning "Do Set-TFAlias -Initialize first."
        return
    }

    # Check version exists
    if (-not (Find-TFRelease -Version $Version)) {
        Write-Warning ("Terraform v{0} not found." -f $Version)
        return
    }

    # Check terraform binary
    $binaryName = GetTerraformBinaryName
    $versionPath = Join-Path $ailasAppPath "$Version"
    $versionBinaryPath = Join-Path $versionPath $binaryName
    if (-not (Test-Path -LiteralPath $versionPath -PathType Container)) {
        [void](New-Item -Path $versionPath -ItemType Directory)  
    }
    if (-not (Test-Path -LiteralPath $versionBinaryPath -PathType Leaf)) {
        # Install Terraform
        WriteInfo ("Install Terraform v{0} to {1}..." -f $Version, $versionPath)
        Save-TFBinary -Version $Version -DestinationPath $versionPath  
    }

    # update version file
    UpdateVersionFile -Version $Version

    # Set alias
    Writeinfo ("Set the v{0} terraform alias." -f $Version)
    DoSetAlias -BinaryPath $versionBinaryPath
}

function InvokeTFAliasFromVersionFile () {
    # Check .terraform-version exists
    if (-not (Test-Path -LiteralPath './.terraform-version' -PathType Leaf)) {
        Write-Warning (".terraform-version file not found.")
        return  
    }
    
    $version = Get-TFVersionFromFile
    if ($null -eq $version) {
        return
    }
    InvokeTFAliasVersion -Version $version
}

function UpdateVersionFile ([semver]$Version) {
    $versionFilePath = GetTFAliasVersionFilePath
    Write-Verbose ("Update version {0} to {1}" -f $Version, $versionFilePath)
    $Version.ToString() | Out-File -FilePath $versionFilePath -NoNewline
}

function DoSetAlias ([string]$BinaryPath) {
    # Set-Alias global
    Set-Alias -Name 'terraform' -Value $BinaryPath -Scope Global    
    # Register auto completion
    Register-TFArgumentCompleter
}
