
class TerraformRelease {

    [string]$Name;
    
    [semver]$Version;

    [bool]$PreRelease;

    [string]$State;

    [datetime]$Created;

    [datetime]$Updated;

    [string]$LicenseClass;

    [string]$ChangeLogUrl;

    [string]$LicenseUrl;

    [string]$ProjectWebSiteUrl;

    [string]$DockerHubUrl;

    [string]$AmazonECRUrl;

    [string]$SourceRepositoryUrl;
    
    [string]$SHA256SUMsUrl;

    [System.Collections.Generic.List[TerraformReleaseBuild]]$Builds;

    [System.Collections.Generic.Dictionary[string, string]] GetSHA256SUMs () {
        $dict = [System.Collections.Generic.Dictionary[string, string]]::new()
        try {
            $rows = (Invoke-RestMethod -Uri $this.SHA256SUMsUrl) -split "\n"
        } catch {
            $rows = $null
        }
        foreach ($r in $rows) {
            $v, $k = $r -split '  ' # need 2 spaces
            $dict.Add($k, $v)
        }
        return $dict
    }
}

class TerraformReleaseBuild {

    [string]$Architecture;

    [string]$OS;

    [string]$Url;

    [string] GetFileName () {
        return $this.Url.split("/")[-1]
    }

    [void] DownLoad ([string]$LiteralPath) {
        # to download sliently, use System.Net.WebClient.
        $client = $null
        $outPath = Join-Path -Path $LiteralPath -ChildPath ($this.GetFileName())
        try {
            $client = [System.Net.WebClient]::new() 
            $client.DownloadFile($this.Url, $outPath)
        } finally {
            $client.Dispose()
        }
    }   
}

function WriteInfo ([string]$message) {
    Write-Host $message -ForegroundColor Green
}

function IsCurrentProcess64bit () {
    return ([System.IntPtr]::Size -eq 8)
}

function IsTerraformInstalled () {
    try {
        $cmd = Get-Command -Name 'terraform' -CommandType Application, Alias -ErrorAction SilentlyContinue
        return (-not ($null -eq $cmd))
    } catch {
        return $false
    }
}

function GetInstalledTerraformVersion () {
    try {
        $match = InvokeTerraformVersion | Select-String 'Terraform v' -SimpleMatch
        return [semver]($match.ToString() -split 'Terraform v')[1]
    } catch {
        return $null
    }
}
function InvokeTerraformVersion () {
    # function for mocking
    return terraform version
}
