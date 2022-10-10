$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $env:TFALIAS_PATH = "$TestDrive\.tfenv"
        if (-not(Test-Path $env:TFALIAS_PATH)) { mkdir $env:TFALIAS_PATH }

        $LATEST_VERSION = Find-TFRelease -Latest | Select-Object -ExpandProperty Version
        Write-Output "Latest Terraform version is $LATEST_VERSION"

        Push-Location $TestDrive
    }

    Describe "Set-TFAlias unit tests" {

        It "Should saved proper files and alias after -Initialize" {
            Set-TFAlias -Initialize
            # Latest Terraform binary
            Test-Path -Path "$env:TFALIAS_PATH\terraform\$LATEST_VERSION\terraform.exe" | Should -BeTrue
            # terraform.ps1
            Test-Path -Path "$env:TFALIAS_PATH\bin\terraform.ps1" | Should -BeTrue
            # others
            if ($IsWindows) {
                Test-Path -Path "$env:TFALIAS_PATH\bin\terraform.cmd" | Should -BeTrue
                Test-Path -Path "$env:TFALIAS_PATH\bin\tfalias.cmd" | Should -BeTrue
                Test-Path -Path "$env:TFALIAS_PATH\bin\tfalias.ps1" | Should -BeTrue
            }
            # Alias
            $expectedPath = "$env:TFALIAS_PATH\bin\terraform.ps1"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should saved proper Terraform binary after -Version" {
            Set-TFAlias -Version 1.2.3
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            Test-Path -Path $expectedPath | Should -BeTrue
        }

        It "Should error when invalid -Version selected" {
            Set-TFAlias -Version 9999.9.9 *>&1 | Should -Be "Terraform v9999.9.9 not found."
        }

        It "Should show proper terraform version with -Latest" {
            Set-TFAlias -Version 1.2.3
            GetInstalledTerraformVersion | Should -Be '1.2.3'

            Set-TFAlias -Latest
            GetInstalledTerraformVersion | Should -Be $LATEST_VERSION
        }

    }

    AfterAll {
        $env:TFALIAS_PATH = $null
        Pop-Location
    }
}