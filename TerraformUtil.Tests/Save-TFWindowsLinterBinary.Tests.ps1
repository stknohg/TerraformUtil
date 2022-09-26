$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "Save-TFWindowsLinterBinary unit tests" {
    
        It "Shoud stop when specified invalid version" {
            { Save-TFWindowsLinterBinary -Version 999.0.0 -DestinationPath $TestDrive -ErrorAction Stop } | Should -Throw
        }

        It "Shoud stop when specified invalid destination" {
            { Save-TFWindowsLinterBinary -Version 0.40.1 -DestinationPath "$TestDrive\notfounddir\" -ErrorAction Stop } | Should -Throw
        }

        It "Should get single proper binary file when -Version parameter specified" {
            Save-TFWindowsLinterBinary -Version 0.40.1 -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tflint.exe" | Should -BeTrue
            Test-Path -LiteralPath "$env:TEMP\tflint_windows_amd64.zip" | Should -BeFalse
        }
    
        It "Should get single proper binary file when -Latest parameter specified" {
            Save-TFWindowsLinterBinary -Latest -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tflint.exe" | Should -BeTrue
            Test-Path -LiteralPath "$env:TEMP\tflint_windows_amd64.zip" | Should -BeFalse
        }
    }
}