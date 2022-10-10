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
    $shimBinPath = GetShimBinPath

    # Check Alias path
    if (-not (Test-Path -LiteralPath $ailasAppPath -PathType Container)) {
        WriteInfo ("Create path : {0}" -f $ailasAppPath)
        [void](New-Item -Path $ailasAppPath -ItemType Directory)
    }
    # Check shim bin path
    if (-not (Test-Path -LiteralPath $shimBinPath -PathType Container)) {
        WriteInfo ("Create path : {0}" -f $shimBinPath)
        [void](New-Item -Path $shimBinPath -ItemType Directory)
    }
    # Copy templates if nessecary
    InstallTemplateFiles -Destination $shimBinPath

    # Check current version
    $version = Get-TFInstalledAlias -Current
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
    DoSetAlias
}

function GetShimBinPath () {
    return [System.IO.Path]::Join((GetTFAliasRoot), 'bin')
}

function CopyFileWithTimeStampCheck ([string]$ParentPath, [string]$FileName, [string]$Destination) {
    $sourcePath = [System.IO.Path]::Combine($ParentPath, $FileName)
    $destPath = [System.IO.Path]::Combine($Destination, $FileName)
    if (-not [System.IO.File]::Exists($sourcePath)) {
        Write-Warning ('Source file {0} not found.' -f $sourcePath)
        return
    }
    if (-not [System.IO.File]::Exists($destPath)) {
        Write-Verbose ('Copy {0} to {1}' -f $sourcePath, $destPath)
        [System.IO.File]::Copy($sourcePath, $destPath, $true)
        return
    }
    if (-not ([System.IO.File]::GetLastWriteTime($sourcePath) -eq [System.IO.File]::GetLastWriteTime($destPath))) {
        Write-Verbose ('Copy {0} to {1}' -f $sourcePath, $destPath)
        [System.IO.File]::Copy($sourcePath, $destPath, $true)
        return
    }
}

function InstallTemplateFiles ([string]$Destination) {
    $templatePath = [System.IO.Path]::Join($PSScriptRoot, 'Templates')
    # All platforms
    CopyFileWithTimeStampCheck -ParentPath $templatePath -FileName 'terraform.ps1' -Destination $Destination
    # WindowsOnly
    if ($IsWindows) {
        CopyFileWithTimeStampCheck -ParentPath $templatePath -FileName 'terraform.cmd' -Destination $Destination
        CopyFileWithTimeStampCheck -ParentPath $templatePath -FileName 'tfalias.ps1' -Destination $Destination
        CopyFileWithTimeStampCheck -ParentPath $templatePath -FileName 'tfalias.cmd' -Destination $Destination
    }
}

function UpdateVersionFile ([semver]$Version) {
    $versionFilePath = GetTFAliasVersionFilePath
    Write-Verbose ("Update version {0} to {1}" -f $Version, $versionFilePath)
    $Version.ToString() | Out-File -FilePath $versionFilePath -NoNewline
}

function DoSetAlias () {
    # Set-Alias global
    $targetPath = [System.IO.Path]::Join((GetShimBinPath), 'terraform.ps1')
    Set-Alias -Name 'terraform' -Value $targetPath -Scope Global    
    # Register auto completion
    Register-TFArgumentCompleter
}
