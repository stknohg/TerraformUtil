$RootPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TerraformUtil'
Import-Module (Join-Path $RootPath 'TerraformUtil.psd1') -Force

InModuleScope 'TerraformUtil' {
    Describe "Test-TFVersion unit tests" {

        It "Test-TFVersion fails when terrafrorm is not installed" {
            Mock -CommandName IsTerraformInstalled -MockWith { $false }
            Test-TFVersion *>&1 | Should -BeLike "*Failed to find 'terraform' command*"
        }
    
        It "Test-TFVersion returns normaly" {
            Mock -CommandName IsTerraformInstalled -MockWith { $true }
            Mock -CommandName GetInstalledTerraformVersion -MockWith { return [semver]'1.2.5' }
            Test-TFVersion *>&1 | Should -BeLike "*Current : v1.2.5*"
        }
    
        It "Test-TFVersion -PassThru returns a result object" {
            Mock -CommandName IsTerraformInstalled -MockWith { $true }
            Mock -CommandName GetInstalledTerraformVersion -MockWith { return [semver]'1.2.5' }
            $actual = Test-TFVersion -PassThru
            $actual | Should -Not -BeNullOrEmpty
            $actual.Result | Should -Not -BeNullOrEmpty
            $actual.Result | Should -BeOfType 'bool'
            $actual.CurrentVersion | Should -Not -BeNullOrEmpty
            $actual.CurrentVersion | Should -Be ([semver]'1.2.5')
            $actual.LatestVersion | Should -Not -BeNullOrEmpty
            $actual.LatestVersion | Should -BeOfType 'semver'
        }
    }
}
