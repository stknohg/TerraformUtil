$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "IsTerraformInstalled function tests" {
        It "IsTerraformInstalled return false when terraform is not installed" {
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'terraform' } -MockWith { throw }
            
            IsTerraformInstalled | Should -BeFalse
        }
        It "IsTerraformInstalled return true when terraform is installed" {
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'terraform' } -MockWith { } # don't throw
            
            IsTerraformInstalled | Should -BeTrue
        }
    }

    Describe "GetInstalledTerraformVersion function tests" {
        It "GetInstalledTerraformVersion return correct version" {
            Mock -CommandName 'terraform' -MockWith { return @'
Terraform v1.2.5
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.3.0. You can update by downloading from https://www.terraform.io/downloads.html
'@ -split "`r`n" }

            GetInstalledTerraformVersion | Should -Be '1.2.5'
        }
    }
}
