#Requires -Version 7.0.0
Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Find Terraform releases.
#>
function Find-TFRelease {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Version', Mandatory = $true, ValueFromPipeline = $true)]
        [SemVer]$Version,
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Switch]$Latest,
        [Parameter(ParameterSetName = 'Default')]
        [datetime]$TimeAfter,
        [Parameter(ParameterSetName = 'Default')]
        [ValidateRange(1, 20)]
        [int]$MaxItems = 10
    )
    begin {
        # validate parameters
        if ($MaxItems -gt 20) {
            $MaxItems = 20
        }
        if ($MaxItems -le 0) {
            $MaxItems = 10
        }

        # define Arraylist for output
        $objectsForOutput = [System.Collections.ArrayList]::new()
    }
    process {
        $uri = switch ($PSCmdlet.ParameterSetName) {
            'Latest' {
                "https://api.releases.hashicorp.com/v1/releases/terraform/latest"
            }
            'Version' {
                "https://api.releases.hashicorp.com/v1/releases/terraform/$Version"
            }
            Default {
                # Currently, no plans to implement pagenation.
                if ($TimeAfter) {
                    "https://api.releases.hashicorp.com/v1/releases/terraform/?limit={0}&after={1:yyyy-MM-dd'T'HH:mm:ss}" -f $MaxItems, $TimeAfter
                } else {
                    "https://api.releases.hashicorp.com/v1/releases/terraform/?limit={0}" -f $MaxItems
                }
            }
        }
        try {
            Write-Verbose "Invoke-RestMethod to $uri"
            $response = Invoke-RestMethod -Uri $uri
        } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            # Show warning exclude 404 error.
            if (-not ($PSCmdlet.ParameterSetName -eq 'Version' -and [int]$_.Exception.Response.StatusCode -eq 404 )) {
                Write-Warning ("StatusCode : {0} {1}" -f [int]$_.Exception.Response.StatusCode, $_)
            }
            return
        } catch {
            Write-Error $_
            return
        }

        # collect outpt object
        foreach ($r in $response) {
            $obj = ConvertResponseItemToObject -ResponseItem $r
            [void]$objectsForOutput.Add($obj)
        }
    }
    end {
        Write-Verbose ("Output object count : {0}" -f $objectsForOutput.Count)
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
    # TryGetProperty -InputObject $ResponseItem -Name ''
    $obj = [TerraformRelease]::new()
    $obj.Name = $ResponseItem.name
    $obj.Version = [semver]$ResponseItem.version
    $obj.PreRelease = TryGetProperty -InputObject $ResponseItem -Name 'is_prerelease'
    $obj.State = $ResponseItem.status.state
    $obj.Created = TryGetProperty -InputObject $ResponseItem -Name 'timestamp_created'
    $obj.Updated = TryGetProperty -InputObject $ResponseItem -Name 'timestamp_updated'
    $obj.LicenseClass = TryGetProperty -InputObject $ResponseItem -Name 'license_class'
    $obj.ChangeLogUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_changelog'
    $obj.LicenseUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_license'
    $obj.ProjectWebSiteUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_project_website'
    $obj.DockerHubUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_docker_registry_dockerhub'
    $obj.AmazonECRUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_docker_registry_ecr'
    $obj.SourceRepositoryUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_source_repository'
    $obj.SHA256SUMsUrl = TryGetProperty -InputObject $ResponseItem -Name 'url_shasums'
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

function TryGetProperty([PSObject]$InputObject, [string]$Name) {
    if ($InputObject.PSobject.Properties.Where({$_.Name -eq $Name})) {
        return $InputObject.$Name
    }
}