$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "Save-TFWindowsBinary unit tests" {
    
        It "Shoud stop when specified invalid version" {
            { Save-TFWindowsBinary -Version 999.0.0 -DestinationPath $TestDrive -ErrorAction Stop } | Should -Throw
        }

        It "Shoud stop when specified invalid destination" {
            { Save-TFWindowsBinary -Version 1.2.5 -DestinationPath "$TestDrive\notfounddir\" -ErrorAction Stop } | Should -Throw
        }

        It "Should get single proper binary file when -Version parameter specified" {
            Save-TFWindowsBinary -Version 1.2.5 -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\terraform.exe" | Should -BeTrue
            Test-Path -LiteralPath "$env:TEMP\terraform_1.2.0_windows_amd64.zip" | Should -BeFalse
        }
    
        It "Should get single proper binary file when -Latest parameter specified" {
            Save-TFWindowsBinary -Latest -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\terraform.exe" | Should -BeTrue
        }
    }
}