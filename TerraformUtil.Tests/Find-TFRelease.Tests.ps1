$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    Describe "Find-TFRelease unit tests" {
        It "Returns nothing when specified invalid version" {
            Find-TFRelease -Version 999.9.9 | Should -BeNullOrEmpty
            Find-TFRelease -Version 0.0.1 | Should -BeNullOrEmpty
        }
    
        It "Should get stable version specified -Version parameter" {
            $actual = Find-TFRelease -Version 1.2.5 
            $actual.Count | Should -Be 1
            $actual.Version | Should -Be '1.2.5'
        }

        It "Should get the latest release information" {
            $expected = [semver](Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/latest" | Select-Object -ExpandProperty version)
            $actual = Find-TFRelease -Latest
            $actual.Count | Should -Be 1
            $actual.Version | Should -Be $expected
        }
    }
}