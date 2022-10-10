$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        $env:TFALIAS_PATH = "$TestDrive\.tfenv"
        if (-not(Test-Path $env:TFALIAS_PATH)) { mkdir $env:TFALIAS_PATH }

        Push-Location $TestDrive
    }

    Describe "Uninstall-TFAlias unit tests" {
        
        It "Should uninstall proper alias" {
            Set-TFAlias -Initialize
            Set-TFAlias -Version 1.2.5
            Set-TFAlias -Version 1.2.3
            { Uninstall-TFAlias -Version 1.2.3 } | Should -Not -Throw
            Get-TFInstalledAlias | Where-Object { $_.Version -eq '1.2.5'} | Should -Not -BeNullOrEmpty
            Get-TFInstalledAlias | Where-Object { $_.Version -eq '1.2.3'} | Should -BeNullOrEmpty
        }

        It "Should uninstall all alias" {
            Set-TFAlias -Initialize
            Set-TFAlias -Version 1.2.5
            Set-TFAlias -Version 1.2.3
            { Get-TFInstalledAlias | Uninstall-TFAlias } | Should -Not -Throw
            Get-TFInstalledAlias | Should -BeNullOrEmpty
        }
    }

    AfterAll {
        $env:TFALIAS_PATH = $null
        Pop-Location
    }
}