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
        [Parameter(ParameterSetName = 'Help', Mandatory = $false)]
        [Switch]$Help
    )
    switch ($PSCmdlet.ParameterSetName) {
        'Initialize' {
            # initialize
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
  -Help               Show this message

Example:
  PS > Set-TFAlias -Initialize     # Initialize and download the latest version
  PS > terraform version
  Terraform vX.Y.Z
  PS > Set-TFAlias -Version 1.2.3  # download ver.1.2.3 and set alias
  PS > terraform version
  Terraform v1.2.3
"@ | Out-Host
}

function InvokeTFAliasInitialize([Switch]$Update) {
    $aliasRoot = GetTFAliasRoot

    # Check Alias path
    if (-not (Test-Path -LiteralPath $aliasRoot -PathType Container)) {
        WriteInfo ("Create TFAlias path : {0}" -f $aliasRoot)
        [void](New-Item -Path $aliasRoot -ItemType Directory)
    }

    InvokeTFAliasLatestVersion
}

function InvokeTFAliasLatestVersion () {
    $aliasRoot = GetTFAliasRoot

    # Check Alias path
    if (-not (Test-Path -LiteralPath $aliasRoot -PathType Container)) {
        Write-Warning ("Alias path {0} not found. Do Set-TFAlias -Initialize first." -f $aliasRoot)
        return  
    }

    # get the latest version
    $version = Find-TFRelease -Latest | Select-Object -ExpandProperty Version
    Writeinfo ("Terraform v{0} is the latest version." -f $version)
    InvokeTFAliasVersion -Version $version 
}

function InvokeTFAliasVersion ([semver]$Version) {
    $aliasRoot = GetTFAliasRoot
    $ailasAppPath = Join-Path $aliasRoot 'terraform'

    # Check Alias path
    if (-not (Test-Path -LiteralPath $aliasRoot -PathType Container)) {
        Write-Warning ("Alias root path {0} not found. Do Set-TFAlias -Initialize first." -f $aliasRoot)
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

    # Set alias
    Writeinfo ("Set the v{0} terraform alias." -f $Version)
    DoSetAlias -BinaryPath $versionBinaryPath
}

function GetTFAliasRoot() {
    if (-not ($env:TFALIAS_PATH)) {
        return (Join-Path $HOME '.tfalias')
    }
    if (-not (Test-Path -LiteralPath $env:TFALIAS_PATH)) {
        Write-Warning ("TFALIAS_PATH {0} not found. So use {1}" -f $env:TFALIAS_PATH, (Join-Path $HOME '.tfalias'))
        return (Join-Path $HOME '.tfalias')
    }
    return $env:TFALIAS_PATH
}

function GetTerraformBinaryName () {
    if ($IsWindows) { 'terraform.exe' } else { 'terraform' }
}

function DoSetAlias ([string]$BinaryPath) {
    # Set-Alias global
    Set-Alias -Name 'terraform' -Value $BinaryPath -Scope Global    
    # Register auto completion
    Register-TFArgumentCompleter
}
