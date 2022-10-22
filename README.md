# TerraformUtil

![build](https://github.com/stknohg/TerraformUtil/workflows/build/badge.svg)

PowerShell utility functions for [Terraform](https://www.terraform.io/).  

## Prerequisites

* PowerShell 7 and later

## How to install

You can install it from [PowerShell gallery](https://www.powershellgallery.com/packages/TerraformUtil/).

```powershell
Install-Module -Name TerraformUtil -Force
```

## TFAlias Functions

This module provides functionality equivalent to [tfenv](https://github.com/tfutils/tfenv).  

### Comparison table

|tfenv|TerraformUtil|notes|
|----|----|----|
|tfenv install|Set-TFAlias|Set-TFAlias automatically install Terraform|
|tfenv use|Set-TFAlias||
|tfenv uninstall|Uninstall-TFAlias||
|tfenv list|Get-TFInstalledAlias||
|tfenv list-remote|Find-TFVersion|You can also use Find-TFRelease|
|tfenv version-name|-|You can use `Get-TFInstalledAlias -Current` instead|
|tfenv init|-|`Set-TFAlias -Initialize` is a similar function|
|tfenv pin|Set-TFAlias||

### Set-TFAlias

Set `terraform` alias like tfenv.  

```powershell
# Initialize and download the latest version Terraform
C:\ > Set-TFAlias -Initialize

# Use latest version Terraform
C:\ > Set-TFAlias -Latest
C:\ > terraform version
Terraform vX.Y.Z

# Download Terraform v.1.2.3 and set alias
C:\ > Set-TFAlias -Version 1.2.3  
C:\ > terraform version
Terraform v1.2.3

# Terraform binary is executed via shim.
C:\ > Get-Command -Name 'terraform' | Select-Object CommandType, Name, Definition

CommandType Name      Definition
----------- ----      ----------
      Alias terraform C:\Users\stknohg\.tfalias\bin\terraform.ps1
```

> **Note**  
> Call `Set-TFAlias -Initialize` in [$PROFILE](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles) for persistence.

#### .terraform-version support

Set-TFAlias supports [.terraform-version](https://github.com/tfutils/tfenv#terraform-version-file) file same as tfenv, but handling of `min-required` and `latest-allowed` differs.  

* [min-required & latest-allowed](https://github.com/tfutils/tfenv#min-required--latest-allowed)

```terraform
// min-required

// tfenv detect 0.12.3, but Set-TFAlias detect 0.10.0
terraform {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

```terraform
// latest-allowed

// tfenv raise error, but Set-TFAlias detect 0.12.2
terraform {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

You can write `.terraform-version` file using `Set-TFAlias -Pin` command.  

```powershell
# Pin .terraform-version file.
C:\temp > Set-TFAlias -Pin
Pinned version by writing "1.2.3" to C:\temp\.terraform-version
```

### Get-TFInstalledAlias

Get installed `terraform` alias.

```powershell
# Get all installed Terraform.
C:\ > Get-TFInstalledAlias

Current Version   Path
------- -------   ----
  False X.Y.Z     C:\Users\stknohg\.tfalias\terraform\X.Y.Z\terraform.exe
   True 1.2.3     C:\Users\stknohg\.tfalias\terraform\1.2.3\terraform.exe
```

### Uninstall-TFAlias

Uninstall `terraform` alias.

```powershell
# Uninstall Terraform v1.2.3
C:\ > Uninstall-TFAlias -Version 1.2.3
Uninstall Terraform v1.2.3
```

## TFAlias for Command Prompt

> **Note**  
> This is experimental feature, no support.

* [[Experimental] TFAlias for Command Prompt](./TFAliasForCmd.md)

## Other Functions

### Register-TFArgumentCompleter

Register auto-completer for `terraform` command.

```powershell
# Register auto-completer
Register-TFArgumentCompleter
```

### UnRegister-TFArgumentCompleter

Unregister auto-completer for `terraform` command.

```powershell
# Unregister auto-completer
UnRegister-TFArgumentCompleter
```

### Find-TFRelease

Get Terraform release information using [Hashicorp Releases API](https://releases.hashicorp.com/docs/api/v1/#operation/listReleasesV1).

> **Note**  
> Currently, no plans to implement pagenation.

```powershell
# Get latest release information
C:\ > Find-TFRelease -Latest

Version PreRelease State     Created              Updated
------- ---------- -----     -------              -------
1.3.2   False      supported 10/6/2022 4:57:24 PM 10/6/2022 4:57:24 PM
```

### Find-TFVersion

Get Terraform versions list by scraping `https://releases.hashicorp.com/terraform` same as `tfenv list-remote`.  

> **Note**  
> Result values is cached 10 minutes to restrict access to origin.

```powershell
# Get all versions (descending by default)
C:\ > Find-TFVersion

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
1      3      2
1      3      1
1      3      0
# ... snip ...
0      2      0
0      1      1
0      1      0

# Use filter script block
C:\ > Find-TFVersion -Filter { $_ -lt '1.0.0' -and (-not $_.PreReleaseLabel) } -Take 1

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
0      15     5

# Pipe to Find-TFRelease
C:\ > Find-TFVersion -Filter { $_ -lt '1.0.0' -and (-not $_.PreReleaseLabel) } -Take 1 | Find-TFRelease

Version PreRelease State     Created             Updated
------- ---------- -----     -------             -------
0.15.5  False      supported 6/2/2021 6:01:19 PM 6/2/2021 6:01:19 PM
```

### Save-TFBinary

Save a specific version Terraform binary file (`terraform.exe` or `terraform`).  

```powershell
# Save the latest binary file to "C:\hashicorp\terraform" folder
Save-TFBinary -Latest -DestinationPath C:\hashicorp\terraform

# Save ver.1.2.9 binary file to "C:\hashicorp\terraform" folder
Save-TFBinary -Version 1.2.9 -DestinationPath C:\hashicorp\terraform
```

### Save-TFSecBinary

Save a specific version [Terraform securiy scanner](https://github.com/aquasecurity/tfsec) file (`tfsec.exe` or `tfsec`).  

```powershell
# Save the latest binary file to "C:\hashicorp\terraform" folder
Save-TFSecBinary -Latest -DestinationPath C:\hashicorp\terraform

# Save ver.1.23.3 binary file to "C:\hashicorp\terraform" folder
Save-TFSecBinary -Version 1.23.3 -DestinationPath C:\hashicorp\terraform
```

### Save-TFLinterBinary

Save a specific version [linter](https://github.com/terraform-linters/tflint) binary file (`tflint.exe` or `tflint`).  

```powershell
# Save the latest linter binary file to "C:\hashicorp\terraform" folder
Save-TFLinterBinary -Latest -DestinationPath C:\hashicorp\terraform

# Save ver.0.40.0 binary file to "C:\hashicorp\terraform" folder
Save-TFLinterBinary -Version 0.40.0 -DestinationPath C:\hashicorp\terraform
```

### Write-TFLinterHCL

Output a basic HCL configuration for .tflint.hcl.  
`-Plugin` parameter supports [Terraform](https://github.com/terraform-linters/tflint), [AWS](https://github.com/terraform-linters/tflint-ruleset-aws), [AzureRM](https://github.com/terraform-linters/tflint-ruleset-azurerm), [Google](https://github.com/terraform-linters/tflint-ruleset-google).

```powershell
# Output configuration for terraform-provider-aws
C:\Sample > Write-TFLinterHCL -Plugin AWS
plugin "aws" {
  enabled = true
  version = "0.17.1" # set the latest version automatically.
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Use -Save parameter to save .tflint.hcl
C:\Sample > Write-TFLinterHCL -Plugin AWS -Save
Save configuration to ".tflint.hcl".

# Of cource you can use redirection.
C:\Sample > Write-TFLinterHCL -Plugin AWS > '.tflint.hcl'
```

## How to uninstall

```powershell
# Step 1. Uninstall module
Uninstall-Module TerraformUtil -Force

# Step 2. Remove "terraform" alias
Remove-Alias terraform

# Step 3. Remove "$HOME\.tfenv" directory
Remove-Item -LiteralPath (Join-Path $HOME '.tfalias') -Recurse
```

## License

* [MIT](./LICENSE)
