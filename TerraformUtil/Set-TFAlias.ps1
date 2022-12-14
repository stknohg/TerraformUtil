#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Set "terraform" alias like tfenv
.PARAMETER Initialize
    Setup TFAlias environment
.PARAMETER Latest
    Set alias to the latest Terraform version
.PARAMETER Version
    Set alias to Terraform ver.X.Y.Z
.PARAMETER Pin
    Write current version to .terraform-version file
.PARAMETER Help
     Show help message
.EXAMPLE
    PS > Set-TFAlias -Initialize     # Initialize alias

    PS > Set-TFAlias -Latast         # Download latest version and set alias
    PS > terraform version
    Terraform vX.Y.Z

    PS > Set-TFAlias -Version 1.2.3  # Download ver.1.2.3 and set alias
    PS > terraform version
    Terraform v1.2.3
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
        [Parameter(ParameterSetName = 'Pin', Mandatory = $true)]
        [Switch]$Pin,
        [Parameter(ParameterSetName = 'Help', Mandatory = $false)]
        [Switch]$Helps,
        [Parameter(ParameterSetName = 'Initialize', Mandatory = $false)]
        [Parameter(ParameterSetName = 'Latest', Mandatory = $false)]
        [Parameter(ParameterSetName = 'Version', Mandatory = $false)]
        [Switch]$Force
    )
    switch ($PSCmdlet.ParameterSetName) {
        'Initialize' {
            InvokeTFAliasInitialize
            return
        }
        'Latest' {
            InvokeTFAliasLatestVersion -IsForce $Force
            return
        }
        'Version' {
            InvokeTFAliasVersion -Version $Version -IsForce $Force
            return
        }
        'Pin' {
            InvokeTFAliasPin
            return
        }
        Default {
            ShowHelpMessage
        }
    }
}

function ShowHelpMessage () {
    @"
Set "terraform" alias like tfenv

Usage:
  -Initialize      Setup TFAlias environment
  -Latast          Set alias to the latest Terraform version
  -Version X.Y.Z   Set alias to Terraform ver.X.Y.Z
  -Pin             Write current version to .terraform-version file
  -Help            Show this message

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

function InvokeTFAliasInitialize() {
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
        [void](InvokeTFAliasVersion -Version $version.Version -IsForce $true 6>&1)
        return
    }
    WriteInfo ('Use the latest version of Terraform.')
    InvokeTFAliasLatestVersion -IsForce $true
}

function InvokeTFAliasLatestVersion ([bool]$IsForce) {
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
    InvokeTFAliasVersion -Version $version -IsForce $IsForce
}

function InvokeTFAliasVersion ([semver]$Version, [bool]$IsForce) {
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

    # Check .terraform-version file
    if (-not $IsForce) {
        $resultFromFile = GetVersionFromVersionFile
        if ($resultFromFile.Version) {
            # override
            Write-Warning ($resultFromFile.Message)
            Write-Warning ('Override version {0} to {1}' -f $Version, ($resultFromFile.Version) )
            $Version = $resultFromFile.Version
        }
        if (-not $resultFromFile.Version -and -not [string]::IsNullOrEmpty( $resultFromFile.FilePath) ) {
            # something failed. show warning only
            Write-Warning ($resultFromFile.Message)
        }
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
    Writeinfo ("Set v{0} terraform alias." -f $Version)
    DoSetAlias
}

function InvokeTFAliasPin () {
    $currentVersion = Get-TFInstalledAlias -Current
    if (-not $currentVersion) {
        Write-Warning "Failed to get current version."
        return
    }
    $filePath = [System.IO.Path]::Join($pwd.Path, '.terraform-version')
    WriteInfo ('Pinned version by writing "{0}" to {1}' -f $currentVersion.Version, $filePath )
    $currentVersion.Version.ToString() | Out-File -FilePath $filePath -NoNewline -Force
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

function GetVersionFromVersionFile () {
    # Note.1 : tfenv searches .terraform-version in two phases, from $pwd recursively and from $HOME recursively.
    #          But this function does not search $HOME recursively, this is intentional.
    # Note.2 : Must use Test-Path to resolve relative path.
    $testPath = $pwd.Path
    do {
        Write-Verbose ('Seacrh .terraform-version : {0}' -f $testPath)
        if (Test-Path -Path ([System.IO.Path]::Join($testPath, '.terraform-version')) -PathType Leaf) {
            break
        }
        $testPath = [System.IO.Path]::GetDirectoryName($testPath)
    } while (-not [string]::IsNullOrEmpty($testPath))
    if ([string]::IsNullOrEmpty($testPath)) {
        Write-Verbose ('Seacrh .terraform-version : {0}' -f $HOME)
        if (Test-Path -Path ([System.IO.Path]::Join($HOME, '.terraform-version')) -PathType Leaf) {
            $testPath = $HOME
        }
    }
    # .terraform-version not found
    if ([string]::IsNullOrEmpty($testPath)) {
        Write-Verbose '.terraform-version not found'
        return [PSCustomObject]@{
            Version  = $null
            FilePath = ''
            Message  = '.terraform-version not found'
        }
    }
    # .terraform-version found
    Write-Verbose ('.terraform-version is detected at {0}' -f $testPath)
    $fileVersion = Get-TFVersionFromFile -LiteralPath ([System.IO.Path]::Join($testPath, '.terraform-version'))
    if (-not $fileVersion) {
        return [PSCustomObject]@{
            Version  = $null
            FilePath = [System.IO.Path]::Join($testPath, '.terraform-version')
            Message  = '.terraform-version is detected, but failed to parse.'
        }

    }
    return [PSCustomObject]@{
        Version  = $fileVersion
        FilePath = [System.IO.Path]::Join($testPath, '.terraform-version')
        Message  = 'Preferred version.{0} is detected from {1}.' -f $fileVersion, ([System.IO.Path]::Join($testPath, '.terraform-version'))
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
