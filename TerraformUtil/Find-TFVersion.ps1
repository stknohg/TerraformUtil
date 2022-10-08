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

    # scraping https://releases.hashicorp.com/terraform
    $response = Invoke-WebRequest -Uri https://releases.hashicorp.com/terraform
    $versions = $response.Links.href | ForEach-Object {
        if ($_ -match '^/terraform/(?<version>.+)/$') { [semver]($Matches.version) }
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