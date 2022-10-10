$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $env:TFALIAS_PATH = "$TestDrive\.tfenv"
        if (-not(Test-Path $env:TFALIAS_PATH)) { mkdir $env:TFALIAS_PATH }

        $LATEST_VERSION = [semver](Invoke-RestMethod -Uri "https://api.releases.hashicorp.com/v1/releases/terraform/latest" | Select-Object -ExpandProperty version)
        Write-Output "Latest Terraform version is $LATEST_VERSION"

        Push-Location $TestDrive
    }

    Describe "Get-TFInstalledAlias unit tests" {

        It "Should get nothing when not initialized" {
            Get-TFInstalledAlias | Should -BeNullOrEmpty
            Get-TFInstalledAlias -Current | Should -BeNullOrEmpty
        }

        It "Should get all proper alias" {
            Set-TFAlias -Initialize
            Set-TFAlias -Version 1.2.3
            Set-TFAlias -Version 1.2.5
            $actual = Get-TFInstalledAlias
            $actual.Count | Should -Be 3
            $actual[0].Version |  Should -Be $LATEST_VERSION
            $actual[1].Version |  Should -Be 1.2.5
            $actual[2].Version |  Should -Be 1.2.3
        }

        It "Should get proper current alias" {
            Set-TFAlias -Initialize
            Set-TFAlias -Version 1.2.5
            Set-TFAlias -Version 1.2.3
            $actual = Get-TFInstalledAlias -Current
            $actual.Count | Should -Be 1
            $actual.Version |  Should -Be 1.2.3
        }

    }

    AfterAll {
        $env:TFALIAS_PATH = $null
        Pop-Location
    }
}