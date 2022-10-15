#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
# Simple cache
$global:g_FTFV_CACHE_MINUTES = 10
$global:g_FTFV_CACHE = [PSCustomObject]@{
    ExpireAt = [datetime]::MinValue;
    Versions = $null;
}

<#
.SYNOPSIS
    Find all Terraform versions.
#>
function Find-TFVersion {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Switch]$Latest,
        [Parameter(ParameterSetName = 'Default', Mandatory = $false)]
        [Switch]$Ascending,
        [Parameter(ParameterSetName = 'Default', Mandatory = $false)]
        [scriptblock]$Filter,
        [Parameter(ParameterSetName = 'Default', Mandatory = $false)]
        [int]$Take = [int]::MaxValue
    )

    if ([datetime]::Now -ge $global:g_FTFV_CACHE.ExpireAt) {
        # scraping https://releases.hashicorp.com/terraform
        $response = Invoke-WebRequest -Uri https://releases.hashicorp.com/terraform
        # get versions
        $versions = $response.Links.href | ForEach-Object {
            if ($_ -match '^/terraform/(?<version>.+)/$') { [semver]($Matches.version) }
        }
        # set cache
        $global:g_FTFV_CACHE.ExpireAt = [datetime]::Now.AddMinutes($global:g_FTFV_CACHE_MINUTES)
        $global:g_FTFV_CACHE.Versions = $versions
        Write-Verbose "Set cache response : ExpireAt = $($global:g_FTFV_CACHE.ExpireAt)"
    } else {
        # use cache
        Write-Verbose "Use cache response : ExpireAt = $($global:g_FTFV_CACHE.ExpireAt)"
        $versions = $global:g_FTFV_CACHE.Versions
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        'Latest' {
            if ($versions.count -ge 1) {
                return $versions | Sort-Object -Descending -Top 1
            }
        }
        Default {
            $retCount = 0
            $sortedVersions = if ($Ascending) { $versions | Sort-Object } else { $versions | Sort-Object -Descending }
            foreach ($ver in $sortedVersions) {
                # match
                if ($Filter) {
                    if ($Filter.InvokeWithContext($null, ([psvariable]::new('_', $ver)), $null)) {
                        $ver
                        $retCount += 1
                    }
                } else {
                    $ver
                    $retCount += 1
                }
                if ($retCount -ge $Take) {
                    return
                }
            }
        }
    }
}
