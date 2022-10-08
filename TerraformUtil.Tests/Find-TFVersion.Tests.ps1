$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $LATEST_VERSION = [semver](Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/latest" | Select-Object -ExpandProperty version)
        Write-Output "Latest Terraform version is $LATEST_VERSION"
    }

    Describe "Find-TFVersion unit tests" {
        It "Should get the latest version" {
            $actual = Find-TFRelease -Latest
            $actual.Count | Should -Be 1
            $actual.Version | Should -Be $LATEST_VERSION
        }

        It "Should return collect count versions with -Filter Parameter" {
            $actual = Find-TFVersion -Filter { $_ -ge '1.2.3' -and $_ -le '1.2.5' }
            $actual.Count | Should -Be 3
            $actual[0] | Should -Be '1.2.5'
            $actual[1] | Should -Be '1.2.4'
            $actual[2] | Should -Be '1.2.3'
        }

        It "Should return collect sort order with -Filter, -Ascending Parameter" {
            $actual = Find-TFVersion -Filter { $_ -ge '1.2.3' -and $_ -le '1.2.5' } -Ascending
            $actual.Count | Should -Be 3
            $actual[0] | Should -Be '1.2.3'
            $actual[1] | Should -Be '1.2.4'
            $actual[2] | Should -Be '1.2.5'
        }

        It "Should return collect single version with -Filter Parameter" {
            $actual = Find-TFVersion -Filter { $_ -gt '1.2.3' -and $_ -lt '1.2.5' }
            $actual.Count | Should -Be 1
            $actual | Should -Be '1.2.4'
        }
    }
}
