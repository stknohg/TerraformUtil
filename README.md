# TerraformUtil

![build](https://github.com/stknohg/TerraformUtil/workflows/build/badge.svg)

PowerShell utility functions for [Terraform](https://www.terraform.io/).

## Prerequisite

Terraform binary is installed to the PATH.

## How to install

You can install it from [PowerShell gallery](https://www.powershellgallery.com/packages/TerraformUtil/).

```powershell
Install-Module -Name TerraformUtil
```

## Functions

### Register-TFArgumentCompleter

Register auto-completer for `terraform` command.

```powershell
# register auto-completer
Register-TFArgumentCompleter
```

### UnRegister-TFArgumentCompleter

Unregister auto-completer for `terraform` command.

```powershell
# unregister auto-completer
UnRegister-TFArgumentCompleter
```

### Test-TFVersion

Test installed Terraform version is the latest version.  
This function is same as `terraform version` command, but you can treat version object with `-PassThru` parameter.

```powershell
# same as "terraform version"
C:\ > Test-TFVersion
Newer version Terraform v1.3.0 is available. (Current : v1.2.9)

# returns version object with -PassThru parameter
C:\ > Test-TFVersion -PassThru
Newer version Terraform v1.3.0 is available. (Current : v1.2.9)

Result CurrentVersion LatestVersion
------ -------------- -------------
 False 1.2.9          1.3.0
```

### Find-TFRelease

Get Terraform release information using [Hashicorp Releases API](https://releases.hashicorp.com/docs/api/v1/#operation/listReleasesV1).

```powershell
# get the latest release information
C:\ > Find-TFRelease -Latest

Version State     Created              Updated
------- -----     -------              -------
1.3.0   supported 9/21/2022 1:58:58 PM 9/21/2022 1:58:58 PM
```

### Save-TFWindowsBinary

Save the specific version's Windows Terraform binary file (`terraform.exe`).  

> **Warning**  
> This function is supported for Windows only.

```powershell
# save the latest binary file (terraform.exe) to "C:\hashicorp\terraform" folder
Save-TFWindowsBinary -Latest -DestinationPath C:\hashicorp\terraform

# save the ver.1.2.9 binary file to "C:\hashicorp\terraform" folder
Save-TFWindowsBinary -Version 1.2.9 -DestinationPath C:\hashicorp\terraform
```

## License

* [MIT](./LICENSE)
