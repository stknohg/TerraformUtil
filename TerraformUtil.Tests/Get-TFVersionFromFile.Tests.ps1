$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        Push-Location $TestDrive
    }

    Describe "Get-TFVersionFromFile unit tests" {

        It "Should show warning when .terraform-version not found" {
            if (Test-Path -LiteralPath '.\.terraform-version' -PathType Leaf) { Remove-Item -Path '.\.terraform-version' } 
            Get-TFVersionFromFile *>&1 | Should -Be "./.terraform-version not found."
        }

        It "Should saved proper terraform version (latest:^0.8)" {
            Write-Output ' latest:^0.8 ' | Out-File -FilePath '.\.terraform-version'
            
            $actual = Get-TFVersionFromFile
            $actual | Should -Be "0.8.8"
        }
    
        It "Should saved proper terraform version with -FromVersionFile (1.2.3)" {
            Write-Output ' 1.2.3 ' | Out-File -FilePath '.\.terraform-version'
            
            $actual = Get-TFVersionFromFile
            $actual | Should -Be "1.2.3"
        }
    
        It "Should show warning when .terraform-version has latest-allowed" {
            Write-Output ' latest-allowed ' | Out-File -FilePath '.\.terraform-version'
            Get-TFVersionFromFile *>&1 | Should -Be "latest-allowed is not supported."
        }
    
        It "Should show warning when .terraform-version has min-required" {
            Write-Output ' min-required ' | Out-File -FilePath '.\.terraform-version'
            Get-TFVersionFromFile *>&1 | Should -Be "min-required is not supported."
        }
    
    }
    
    AfterAll {
        Pop-Location
    }
}