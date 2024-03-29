@{
    ModuleVersion        = '0.13.0'
    CompatiblePSEditions = @('Core')
    GUID                 = '9f940cba-7b6c-4793-8a2a-35da59c45c40'
    Author               = 'Takuya Shibata'
    CompanyName          = 'Takuya Shibata'
    Copyright            = '(c) Takuya Shibata. All rights reserved.'
    Description          = 'PowerShell utility functions for Terraform.'
    PowerShellVersion    = '7.0.0'
    RootModule           = 'TerraformUtil.psm1'
    FunctionsToExport    = @('Register-TFArgumentCompleter', 'UnRegister-TFArgumentCompleter',
                             'Find-TFRelease', 'Find-TFVersion', 'Get-TFVersionFromFile',
                             'Save-TFBinary', 'Save-TFSecBinary', 'Save-TFLinterBinary', 'Write-TFLinterHCL',
                             'Set-TFAlias', 'Get-TFInstalledAlias', 'Uninstall-TFAlias')
    FormatsToProcess     = @('TerraformUtil.format.ps1xml')
    PrivateData = @{
        PSData = @{
            LicenseUri = 'https://github.com/stknohg/TerraformUtil/blob/main/LICENSE'
            ProjectUri = 'https://github.com/stknohg/TerraformUtil'
            Tags       = @('Terraform', 'tfenv', 'tflint', 'tfsec')
        } 
    } 
}
