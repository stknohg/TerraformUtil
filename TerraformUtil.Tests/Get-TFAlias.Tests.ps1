$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $env:TFALIAS_PATH = "$TestDrive\.tfenv"
        if (-not(Test-Path $env:TFALIAS_PATH)) { mkdir $env:TFALIAS_PATH }

        Push-Location $TestDrive
    }

    Describe "Get-TFAlias unit tests" {

        It "Should get nothing when no alias installed" {
            Get-TFAlias | Should -BeNullOrEmpty
            Get-TFAlias -Current | Should -BeNullOrEmpty
        }

        It "Should get all proper alias" {
            Set-TFAlias -Version 1.2.3
            Set-TFAlias -Version 1.2.5
            $actual = Get-TFAlias
            $actual.Count | Should -Be 2
            $actual[0].Version |  Should -Be 1.2.5
            $actual[1].Version |  Should -Be 1.2.3
        }

        It "Should get proper current alias" {
            Set-TFAlias -Version 1.2.5
            Set-TFAlias -Version 1.2.3
            $actual = Get-TFAlias -Current
            $actual.Count | Should -Be 1
            $actual.Version |  Should -Be 1.2.3
        }
    }

    AfterAll {
        $env:TFALIAS_PATH = $null
        Pop-Location
    }
}