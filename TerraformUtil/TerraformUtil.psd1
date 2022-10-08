@{
    ModuleVersion        = '0.3.0'
    CompatiblePSEditions = @('Core')
    GUID                 = '9f940cba-7b6c-4793-8a2a-35da59c45c40'
    Author               = 'Takuya Shibata'
    CompanyName          = 'Takuya Shibata'
    Copyright            = '(c) Takuya Shibata. All rights reserved.'
    Description          = 'PowerShell utility functions for Terraform.'
    PowerShellVersion    = '7.0.0'
    NestedModules        = @('TerraformUtil.psm1')
    FunctionsToExport    = @('Register-TFArgumentCompleter', 'UnRegister-TFArgumentCompleter',
                             'Find-TFRelease', 'Test-TFVersion',
                             'Save-TFWindowsBinary', 'Save-TFWindowsLinterBinary',
                             'Set-TFAlias')
    FormatsToProcess     = @('TerraformUtil.format.ps1xml')
    PrivateData = @{
        PSData = @{
            LicenseUri = 'https://github.com/stknohg/TerraformUtil/blob/main/LICENSE'
            ProjectUri = 'https://github.com/stknohg/TerraformUtil'
        } 
    } 
}
