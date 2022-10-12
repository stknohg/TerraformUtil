$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {

    BeforeAll {
        # Use Find-TFVersion in this test cases. 
        $MIN_VERSION = "0.1.0"
        Write-Output "First Terraform version is $MIN_VERSION"
        $LATEST_VERSION = Find-TFVersion -Latest
        Write-Output "Latest Terraform version is $LATEST_VERSION"
        Push-Location $TestDrive
    }

    Describe "GetTerraformRequiredValue function unit test" -Tag "Function" {
        BeforeEach {
            if (Test-Path -LiteralPath '.\main.tf' -PathType Leaf) { Remove-Item -Path '.\main.tf' }
        }

        It "Return empty string when no *.tf was found" {
            GetTerraformRequiredValue -RootPath '.\' | Should -BeNullOrEmpty
        }

        It "Return empty string when no required_version was found" {
            @'
terraform {
    required_providers {
        aws = {
        version = ">= 4.0.0"
        source = "hashicorp/aws"
        }
    }
}
'@ |Out-File -FilePath '.\main.tf'
            GetTerraformRequiredValue -RootPath '.\' | Should -BeNullOrEmpty
        }

        It "Return proper value when required_version was found" {
            @'
terraform {
    required_providers {
        aws = {
        version = ">= 4.0.0"
        source = "hashicorp/aws"
        }
    }
    required_version = " >0.11, <0.12 "
}
'@ |Out-File -FilePath '.\main.tf'
            GetTerraformRequiredValue -RootPath '.\' | Should -Be " >0.11, <0.12 "
        }
    }

    Describe "ParseTerraformRequiredVersion function unit test" -Tag "Function" {
        $testCases = @(
            @{RawString = "1.2.3"; MinVersion = "1.2.3"; MaxVersion = "1.2.3" }
            @{RawString = "=1.2.3"; MinVersion = "1.2.3"; MaxVersion = "1.2.3" }
            @{RawString = "<=1.2.3"; MinVersion = "MIN_VERSION"; MaxVersion = "1.2.3" }
            @{RawString = "<1.2.3"; MinVersion = "MIN_VERSION"; MaxVersion = "1.2.2" }
            @{RawString = ">=1.2.3"; MinVersion = "1.2.3"; MaxVersion = "LATEST_VERSION" }
            @{RawString = ">1.2.3"; MinVersion = "1.2.4"; MaxVersion = "LATEST_VERSION" }
            @{RawString = "~>0.11.0"; MinVersion = "0.11.0"; MaxVersion = "0.11.15" }
            @{RawString = "~>0.11.3"; MinVersion = "0.11.3"; MaxVersion = "0.11.15" }
            @{RawString = "~>0.11"; MinVersion = "0.11.0"; MaxVersion = "0.15.5" }
            @{RawString = ">=0.11, <=0.12"; MinVersion = "0.11.0"; MaxVersion = "0.12.0" }
            @{RawString = ">0.11, <0.12"; MinVersion = "0.11.1"; MaxVersion = "0.12.0-rc1" }
            @{RawString = "~>0.11.0, >0.11.3, <0.11.8"; MinVersion = "0.11.4"; MaxVersion = "0.11.7" }
            # ref : https://github.com/tfutils/tfenv#min-required--latest-allowed
            @{RawString = "<0.12.3, >= 0.10.0"; MinVersion = "0.10.0"; MaxVersion = "0.12.2" } # 0.12.2 is correct
            @{RawString = "~> 0.10.0, <0.12.3"; MinVersion = "0.10.0"; MaxVersion = "0.10.8" } # treat range(0.10.0 - 0.10.8) AND (< 0.12.3) 
            # ref : https://github.com/tfutils/tfenv/blob/master/test/test_use_latestallowed.sh
            @{RawString = "~> 1.1.0"; MinVersion = "1.1.0"; MaxVersion = "1.1.9" }
            @{RawString = "<=0.13.0-rc1"; MinVersion = "MIN_VERSION"; MaxVersion = "0.13.0-rc1" }
            @{RawString = "~> 0.12"; MinVersion = "0.12.0"; MaxVersion = "0.15.5" }
            @{RawString = "~> 1.0.0"; MinVersion = "1.0.0"; MaxVersion = "1.0.11" }
            @{RawString = "~> 0.14.3"; MinVersion = "0.14.3"; MaxVersion = "0.14.11" }
            # ref : https://github.com/tfutils/tfenv/blob/master/test/test_use_minrequired.sh
            @{RawString = ">=0.8.0"; MinVersion = "0.8.0"; MaxVersion = "LATEST_VERSION" }
            @{RawString = ">=0.13.0-rc1"; MinVersion = "0.13.0-rc1"; MaxVersion = "LATEST_VERSION" }
            @{RawString = ">=0.12"; MinVersion = "0.12.0"; MaxVersion = "LATEST_VERSION" }
            @{RawString = ">=1.0.0"; MinVersion = "1.0.0"; MaxVersion = "LATEST_VERSION" }
            @{RawString = ">=1.1.0"; MinVersion = "1.1.0"; MaxVersion = "LATEST_VERSION" }
        )
        It "Should return proper version when -RawString is <RawString>" -TestCases $testCases {
            if ($MinVersion -eq "MIN_VERSION") { $MinVersion = $MIN_VERSION }
            if ($MaxVersion -eq "LATEST_VERSION") { $MaxVersion = $LATEST_VERSION }
            $actural = ParseTerraformRequiredVersion -RawString $RawString
            $actural.AllowedMinVersion | Should -Be $MinVersion
            $actural.AllowedMaxVersion | Should -Be $MaxVersion
        }
    }

    Describe "Get-TFVersionFromFile unit tests" {

        BeforeEach {
            if (Test-Path -LiteralPath '.\main.tf' -PathType Leaf) { Remove-Item -Path '.\main.tf' }
        }

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
    
        It "Should show warning when .terraform-version has latest-allowed and required_version not found" {
            Write-Output ' latest-allowed ' | Out-File -FilePath '.\.terraform-version'
            Get-TFVersionFromFile *>&1 | Should -Be '.terraform-version contains "latest-allowed", but "required_version" statement not found.'
        }

        It "Should saved proper terraform version with -FromVersionFile (latest-allowed)" {
            Write-Output ' latest-allowed ' | Out-File -FilePath '.\.terraform-version'
            @'
terraform {
    required_providers {
        aws = {
        version = ">= 4.0.0"
        source = "hashicorp/aws"
        }
    }
    required_version = ">0.11, <0.12"
}
'@ |Out-File -FilePath '.\main.tf'
            $actual = Get-TFVersionFromFile
            $actual | Should -Be "0.12.0-rc1"
        }
    
        It "Should show warning when .terraform-version has min-required and required_version not found" {
            Write-Output ' min-required ' | Out-File -FilePath '.\.terraform-version'
            Get-TFVersionFromFile *>&1 | Should -Be '.terraform-version contains "min-required", but "required_version" statement not found.'
        }
    
        It "Should saved proper terraform version with -FromVersionFile (min-required)" {
            Write-Output ' min-required ' | Out-File -FilePath '.\.terraform-version'
            @'
terraform {
    required_providers {
        aws = {
        version = ">= 4.0.0"
        source = "hashicorp/aws"
        }
    }
    required_version = ">0.11, <0.12"
}
'@ |Out-File -FilePath '.\main.tf'
            $actual = Get-TFVersionFromFile
            $actual | Should -Be "0.11.1"
        }
    }
    
    AfterAll {
        Pop-Location
    }
}