<#
.SYNOPSIS
    Find Terraform releases.
#>
function Find-TFRelease {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [SemVer]$Version,
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Switch]$Latest,
        [Parameter(ParameterSetName = 'Default')]
        [int]$MaxItems = 10
    )
    begin {
        # validate parameters
        if ($MaxItems -gt 20) {
            $MaxItems = 20
        }
        if ($MaxItems -lt 0) {
            $MaxItems = 10
        }
    }
    process {
        $response = switch ($PSCmdlet.ParameterSetName) {
            'Latest' {
                Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/latest"
            }
            'Version' {
                Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/$Version"
            }
            Default {
                Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/?limit=$MaxItems"
            }
        }

        # output object
        $objectsForOutput = [System.Collections.ArrayList]::new()
        foreach ($r in $response) {
            $obj = ConvertResponseItemToObject -ResponseItem $r
            # excude pre release version by default
            if ($PSCmdlet.ParameterSetName -eq 'Default') {
                if (-not $IncludePreRelease -and $obj.PreRelease) {
                    Write-Verbose "-IncludePreRelease filter excludes version $($obj.Version)"
                    continue
                }
            }
            [void]$objectsForOutput.Add($obj)
        }
    }
    end {
        switch ($objectsForOutput.Count) {
            0 {
                # do nothing
            }
            1 {
                $objectsForOutput[0]
            }
            Default {
                $objectsForOutput | Sort-Object -Property Version -Descending
            }
        }
    }
}

function ConvertResponseItemToObject ([PSCustomObject]$ResponseItem) {
    if (-not $ResponseItem) {
        return $null
    }
    # convert to class
    $obj = [TerraformRelease]::new()
    $obj.Version = [semver]$ResponseItem.version
    $obj.State = $ResponseItem.status.state
    $obj.Created = $ResponseItem.timestamp_created
    $obj.Updated = $ResponseItem.timestamp_updated
    $obj.ChangeLogUrl = $ResponseItem.url_changelog
    $obj.LicenseUrl = $ResponseItem.url_license
    $obj.DockerHubUrl = $ResponseItem.url_docker_registry_dockerhub
    $obj.AmazonECRUrl = $ResponseItem.url_docker_registry_ecr
    $obj.SHA256SUMsUrl = $ResponseItem.url_shasums
    # set builds
    $obj.Builds = [System.Collections.Generic.List[TerraformReleaseBuild]]::new()
    foreach ($b in $ResponseItem.builds) {
        $item = [TerraformReleaseBuild]::new()
        $item.Architecture = $b.arch
        $item.OS = $b.os
        $item.Url = $b.url
        $obj.Builds.Add($item)
    }
    #
    return $obj
}
