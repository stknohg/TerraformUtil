$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "Save-TFLinterBinary unit tests" {
    
        It "Shoud stop when specified invalid version" {
            { Save-TFLinterBinary -Version 999.0.0 -DestinationPath $TestDrive -ErrorAction Stop } | Should -Throw
        }

        It "Shoud stop when specified invalid destination" {
            { Save-TFLinterBinary -Version 0.40.1 -DestinationPath "$TestDrive\notfounddir\" -ErrorAction Stop } | Should -Throw
        }

        It "Should get single proper binary file when -Version parameter specified" {
            Save-TFLinterBinary -Version 0.40.1 -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tflint.exe" -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath "$env:TEMP\tflint_windows_amd64.zip" | Should -BeFalse
        }
    
        It "Should get single proper binary file when -Latest parameter specified" {
            Save-TFLinterBinary -Latest -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tflint.exe" -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath "$env:TEMP\tflint_windows_amd64.zip" | Should -BeFalse
        }
    }
}