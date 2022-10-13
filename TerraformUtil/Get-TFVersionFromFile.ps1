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

    $rowString = @(Get-Content -LiteralPath $LiteralPath)[0].Trim()
    if ('latest-allowed' -eq $rowString) {
        # -RootPath must be .terraform-version directory.
        $requiredValue = GetTerraformRequiredValue -RootPath $([System.IO.Path]::GetDirectoryName($LiteralPath))
        if ([string]::IsNullOrEmpty($requiredValue)) {
            Write-Warning '.terraform-version contains "latest-allowed", but "required_version" statement not found.'
            return
        }
        $arrowedVersion = ParseTerraformRequiredVersion -RawString $requiredValue
        if (-not $arrowedVersion) {
            Write-Warning '.terraform-version contains "latest-allowed", but failed to parse "required_version" statement.'
            return
        }
        return $arrowedVersion.AllowedMaxVersion
    }
    if ('min-required' -eq $rowString) {
        # -RootPath must be .terraform-version directory.
        $requiredValue = GetTerraformRequiredValue -RootPath $([System.IO.Path]::GetDirectoryName($LiteralPath))
        if ([string]::IsNullOrEmpty($requiredValue)) {
            Write-Warning '.terraform-version contains "min-required", but "required_version" statement not found.'
            return
        }
        $arrowedVersion = ParseTerraformRequiredVersion -RawString $requiredValue
        if (-not $arrowedVersion) {
            Write-Warning '.terraform-version contains "min-required", but failed to parse "required_version" statement.'
            return
        }
        return $arrowedVersion.AllowedMinVersion
    }
    if ('latest' -eq $rowString) {
        Write-Verbose 'Detect the latest version'
        return (Find-TFRelease -Latest).Version
    }
    if ($rowString -match '^latest:(?<match_exp>.+)$' ) {
        $matchExp = $Matches.match_exp
        Write-Verbose ("version match expression : {0}" -f $matchExp)
        $matchVersion = Find-TFVersion -Filter { "$_" -match $matchExp } -Take 1
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

# TODO : implement more formal parser
function GetTerraformRequiredValue ([string]$RootPath) {
    if (-not (Test-Path -Path $RootPath -PathType Container)) {
        return ""
    }
    foreach ($file in (Get-ChildItem -LiteralPath $RootPath -Include '*.tf', '*.tf.json')) {
        Select-String -LiteralPath $file.FullName -Pattern '^\s*[^#]*\s*required_version\s*=\s*["''](?<match_exp>.+)["'']$' | ForEach-Object {
            $rawString = ($_.Matches.Groups).Where({ $_.Name -eq 'match_exp' }).Value
            if ($rawString) {
                Write-Verbose ('Found rawString : {0}' -f $rawString)
                return $rawString
            }
        }
    }
}

# TODO : implement more formal parser
function ParseTerraformRequiredVersion ([string]$RawString) {
    $allVersions = Find-TFVersion

    # Get each expressions
    $expressions = foreach ($str in $RawString -split ',') {
        $str = $str.Trim()
        switch -Regex ($str) {
            '^\s*(?<match_op>(=|>=|<=|~>|<|>))\s*(?<match_ver>.+)$' {
                # Value must be string to validate ~> operator
                switch ($Matches.match_op) {
                    '=' {
                        [PSCustomObject]@{
                            Operator   = $Matches.match_op
                            Value      = $Matches.match_ver
                            MinVersion = [semver]($Matches.match_ver)
                            MaxVersion = [semver]($Matches.match_ver)
                        }
                        break
                    }
                    '>=' {
                        [PSCustomObject]@{
                            Operator   = $Matches.match_op
                            Value      = $Matches.match_ver
                            MinVersion = [semver]($Matches.match_ver)
                            MaxVersion = $allVersions[0]
                        }
                        break
                    }
                    '<=' {
                        [PSCustomObject]@{
                            Operator   = $Matches.match_op
                            Value      = $Matches.match_ver
                            MinVersion = [semver]$allVersions[-1]
                            MaxVersion = [semver]($Matches.match_ver)
                        }
                        break
                    }
                    '~>' {
                        $v = $Matches.match_ver.Substring(0, $Matches.match_ver.LastIndexOf('.'))
                        $tempVersions = $allVersions.Where({ $_ -ge "$($Matches.match_ver)" -and $_ -like "${v}.*" })
                        [PSCustomObject]@{
                            Operator   = $Matches.match_op
                            Value      = $Matches.match_ver
                            MinVersion = [semver]$tempVersions[-1]
                            MaxVersion = [semver]$tempVersions[0]
                        }
                        break
                    }
                    '<' {
                        $tempVersions = $allVersions.Where({ $_ -lt "$($Matches.match_ver)" })
                        [PSCustomObject]@{
                            Operator   = $Matches.match_op
                            Value      = $Matches.match_ver
                            MinVersion = [semver]$allVersions[-1]
                            MaxVersion = [semver]$tempVersions[0]
                        }
                        break
                    }
                    '>' {
                        $tempVersions = $allVersions.Where( { $_ -gt "$($Matches.match_ver)" } )
                        [PSCustomObject]@{
                            Operator   = ($Matches.match_op)
                            Value      = ($Matches.match_ver)
                            MinVersion = [semver]$tempVersions[-1]
                            MaxVersion = [semver]$allVersions[0]
                        }
                        break
                    }
                }
                break
            }
            Default {
                # No matched : treat as "="
                try {
                    $tempVer = [semver]($str)
                    [PSCustomObject]@{
                        Operator   = '='
                        Value      = $str
                        MinVersion = $tempVer
                        MaxVersion = $tempVer
                    }
                } catch {
                    Write-Warning $_
                }
                break
            }
        }
    }
    
    # Simply "AND" all expressions
    $minVer = ($expressions.MinVersion | Measure-Object -Maximum).Maximum
    $maxVer = ($expressions.MaxVersion | Measure-Object -Minimum).Minimum
    if ($minVer -gt $maxVer) {
        Write-Warning ('"required_version" has inconsistent expression "{0}". (Min={1}, Max={2})' -f $RawString, $minVer, $maxVer)
        return
    }
    return [PSCustomObject]@{
        AllowedMinVersion = $minVer
        AllowedMaxVersion = $maxVer
    }
}
