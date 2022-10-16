$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    Describe "Write-TFLinterHCL unit tests" {
        
        It "Should return porper value with -Plugin Terraform" {
            Write-TFLinterHCL -Plugin Terraform | Should -Be @'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
'@
        }

        It "Should return porper value with -Plugin AWS" {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {$Uri -eq 'https://api.github.com/repos/terraform-linters/tflint-ruleset-aws/releases/latest'} -MockWith { [PSCustomObject]@{tag_name = 'v0.12.3'} }

            Write-TFLinterHCL -Plugin AWS | Should -Be @'
plugin "aws" {
  enabled = true
  version = "0.12.3"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
'@
        }

        It "Should return porper value with -Plugin AzureRM" {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {$Uri -eq 'https://api.github.com/repos/terraform-linters/tflint-ruleset-azurerm/releases/latest'} -MockWith { [PSCustomObject]@{tag_name = 'v0.12.3'} }

            Write-TFLinterHCL -Plugin AzureRM | Should -Be @'
plugin "azurerm" {
  enabled = true
  version = "0.12.3"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
'@
        }

        It "Should return porper value with -Plugin Google" {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {$Uri -eq 'https://api.github.com/repos/terraform-linters/tflint-ruleset-google/releases/latest'} -MockWith { [PSCustomObject]@{tag_name = 'v0.12.3'} }

            Write-TFLinterHCL -Plugin Google | Should -Be @'
plugin "google" {
  enabled = true
  version = "0.12.3"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
'@
        }
    }

}
