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

        It "Should saved Terraform binary after -Initialize" {
            Set-TFAlias -Initialize
            $expectedPath = "$env:TFALIAS_PATH\terraform\$LATEST_VERSION\terraform.exe"
            Test-Path -Path $expectedPath | Should -BeTrue
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should saved proper Terraform binary after -Version" {
            Set-TFAlias -Version 1.2.3
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            Test-Path -Path $expectedPath | Should -BeTrue
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should show proper terraform version with -Latest" {
            Set-TFAlias -Version 1.2.3
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath

            Set-TFAlias -Latest
            $expectedPath = "$env:TFALIAS_PATH\terraform\$LATEST_VERSION\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should show warning when .terraform-version file not found with -FromVersionFile" {
            if (Test-Path -Path './.terraform-version' -PathType Leaf) {Remove-Item -LiteralPath './.terraform-version'}
            Set-TFAlias -FromVersionFile *>&1 | Should -Be ".terraform-version file not found."
        }

        It "Should saved latest terraform version with -FromVersionFile (latest)" {
            Write-Output ' latest ' | Out-File -FilePath '.\.terraform-version'
            
            Set-TFAlias -FromVersionFile
            $expectedPath = "$env:TFALIAS_PATH\terraform\$LATEST_VERSION\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should saved proper terraform version with -FromVersionFile (latest:^0.8)" {
            Write-Output ' latest:^0.8 ' | Out-File -FilePath '.\.terraform-version'
            
            Set-TFAlias -FromVersionFile
            $expectedPath = "$env:TFALIAS_PATH\terraform\0.8.8\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should saved proper terraform version with -FromVersionFile (1.2.3)" {
            Write-Output ' 1.2.3 ' | Out-File -FilePath '.\.terraform-version'
            
            Set-TFAlias -FromVersionFile
            $expectedPath = "$env:TFALIAS_PATH\terraform\1.2.3\terraform.exe"
            $actual = Get-Alias terraform
            $actual.Definition | Should -Be $expectedPath
        }

        It "Should show warning when .terraform-version has latest-allowed" {
            Write-Output ' latest-allowed ' | Out-File -FilePath '.\.terraform-version'
            Set-TFAlias -FromVersionFile *>&1 | Should -Be "latest-allowed is not supported."
        }

        It "Should show warning when .terraform-version has min-required" {
            Write-Output ' min-required ' | Out-File -FilePath '.\.terraform-version'
            Set-TFAlias -FromVersionFile *>&1 | Should -Be "min-required is not supported."
        }
    }

    AfterAll {
        $env:TFALIAS_PATH = $null
        Pop-Location
    }
}