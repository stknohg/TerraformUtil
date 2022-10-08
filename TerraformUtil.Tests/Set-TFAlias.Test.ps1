$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $env:TFALIAS_PATH = "$TestDrive\.tfenv"
        if (-not(Test-Path $env:TFALIAS_PATH)) { mkdir $env:TFALIAS_PATH }
    }

    Describe "Set-TFAlias unit tests" {

        It "Should saved Terraform binary after -Initialize" {
            $version = Find-TFRelease -Latest | Select-Object -ExpandProperty Version

            Set-TFAlias -Initialize
            $expectedPath = "$env:TFALIAS_PATH\terraform\$version\terraform.exe"
            Test-Path -Path $expectedPath | Should -BeTrue
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should saved proper Terraform binary after -Version" {
            Set-TFAlias -Version 1.2.3
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            Test-Path -Path $expectedPath | Should -BeTrue
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should show proper terraform version with -Latest" {
            $version = Find-TFRelease -Latest | Select-Object -ExpandProperty Version

            Set-TFAlias -Version 1.2.3
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath

            Set-TFAlias -Latest
            $expectedPath = "$env:TFALIAS_PATH\terraform\$version\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }
    }

    AfterAll {
        $env:TFALIAS_PATH = $null
    }
}