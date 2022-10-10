# TerraformUtil

![build](https://github.com/stknohg/TerraformUtil/workflows/build/badge.svg)

PowerShell utility functions for [Terraform](https://www.terraform.io/).  

## Prerequisites

* PowerShell 7 and later

## How to install

You can install it from [PowerShell gallery](https://www.powershellgallery.com/packages/TerraformUtil/).

```powershell
Install-Module -Name TerraformUtil
```

## Functions

### Set-TFAlias

Set the `terraform` alias like [tfenv](https://github.com/tfutils/tfenv).   

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

### Test-TFVersion

Test installed Terraform version is the latest version.  
This function is same as `terraform version` command, but you can treat version object with `-PassThru` parameter.

```powershell
# Same as "terraform version"
C:\ > Test-TFVersion
Newer version Terraform vX.Y.Z is available. (Current : v1.2.3)

# Returns version object with -PassThru parameter
C:\ > Test-TFVersion -PassThru

Result CurrentVersion LatestVersion
------ -------------- -------------
 False 1.2.3          X.Y.Z
```

### Find-TFRelease

Get Terraform release information using [Hashicorp Releases API](https://releases.hashicorp.com/docs/api/v1/#operation/listReleasesV1).

> **Note**  
> Currently, no plans to implement pagenation.

```powershell
# Get the latest release information
C:\ > Find-TFRelease -Latest

Version PreRelease State     Created              Updated
------- ---------- -----     -------              -------
1.3.0   False      supported 9/21/2022 1:58:58 PM 9/21/2022 1:58:58 PM
```

### Find-TFVersion

Get Terraform versions list by scraping `https://releases.hashicorp.com/terraform` same as `tfenv list-remote`.  

```powershell
# Get all versions (descending by default)
C:\ > Find-TFVersion

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
1      3      0
1      3      0      rc1
1      3      0      beta1
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

Save the specific version Terraform binary file (`terraform.exe` or `terraform`).  

```powershell
# Save the latest binary file to "C:\hashicorp\terraform" folder
Save-TFBinary -Latest -DestinationPath C:\hashicorp\terraform

# Save the ver.1.2.9 binary file to "C:\hashicorp\terraform" folder
Save-TFBinary -Version 1.2.9 -DestinationPath C:\hashicorp\terraform
```

### Save-TFLinterBinary

Save the specific version [linter](https://github.com/terraform-linters/tflint) binary file (`tflint.exe` or `tflint`).  

```powershell
# Save the latest linter binary file to "C:\hashicorp\terraform" folder
Save-TFLinterBinary -Latest -DestinationPath C:\hashicorp\terraform

# Save the ver.0.40.0 binary file to "C:\hashicorp\terraform" folder
Save-TFLinterBinary -Version 0.40.0 -DestinationPath C:\hashicorp\terraform
```

## License

* [MIT](./LICENSE)
