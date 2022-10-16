$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "Save-TFSecBinary unit tests" {

        BeforeEach {
            if (Test-Path -LiteralPath "$TestDrive\tfsec.exe" -PathType Leaf) {}
        }
    
        It "Shoud stop when specified invalid version" {
            { Save-TFSecBinary -Version 999.0.0 -DestinationPath $TestDrive -ErrorAction Stop } | Should -Throw
        }

        It "Shoud stop when specified invalid destination" {
            { Save-TFSecBinary -Version 1.27.0 -DestinationPath "$TestDrive\notfounddir\" -ErrorAction Stop } | Should -Throw
        }

        It "Should get single proper binary file when -Version parameter specified" {
            Save-TFSecBinary -Version 1.27.0 -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tfsec.exe" -PathType Leaf | Should -BeTrue
        }
    
        It "Should get single proper binary file when -Latest parameter specified" {
            Save-TFSecBinary -Latest -DestinationPath $TestDrive -ErrorAction Stop
            Test-Path -LiteralPath "$TestDrive\tfsec.exe" -PathType Leaf | Should -BeTrue
        }
    }
}