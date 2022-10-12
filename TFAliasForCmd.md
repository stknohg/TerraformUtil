# [Experimental] TFAlias for Command Prompt

## How to use

Install PowerShell 7 and do `Set-TFAlias -Initialize` first.

```batch
REM Do after PowerShell 7 installed
pwsh -c "Install-Module -Name TerraformUtil -Force; Set-TFAlias -Initialize"
```

Then add PATH to `%USREPROFILE%\.tfalias\bin`

```batch
REM Add PATH
SET PATH=%USERPROFILE%\.tfalias\bin;%PATH%
```

## tfalias.cmd

`tfalias.cmd` is command line tool like [tfenv](https://github.com/tfutils/tfenv).  

```batch
C:\ > where.exe tfalias

C:\Users\stknohg\.tfalias\bin\tfalias.cmd
```

### tfalias use

Install and use a specific version of Terraform.  

```batch
REM Use latest version Terraform
C:\ > tfalias use latest
C:\ > terraform version
Terraform vX.Y.Z

REM Download Terraform v.1.2.3 and set alias
C:\ > tfalias use 1.2.3
C:\ > terraform version
Terraform v1.2.3
```

### tfalias list

List installed Terraform versions.

```batch
REM Get all installed Terraform.
C:\ > tfalias list
  X.Y.Z
* 1.2.3

REM output json with --json parameter
C:\ > tfalias list --json
[
  {
    "Current": false,
    "Version": "X.Y.X",
    "Path": "C:\\Users\\stknohg\\.tfalias\\terraform\\X.Y.X\\terraform.exe"
  },
  {
    "Current": true,
    "Version": "1.2.3",
    "Path": "C:\\Users\\stknohg\\.tfalias\\terraform\\1.2.3\\terraform.exe"
  }
]
```

### tfalias uninstall

Uninstall a specific version of Terraform. 

```batch
REM Uninstall Terraform v1.2.3
C:\ > tfalias uninstall 1.2.3
Uninstall Terraform v1.2.3
```

### tfalias list-remote

List all installable versions.

```batch
REM List all versions (descending)
C:\ > tfalias list-remote
1.3.2
1.3.1
1.3.0
REM ... snip ...
0.2.0
0.1.1
0.1.0

REM output json with --json parameter
C:\ > tfalias list-remote --json
[
  {
    "Version": "1.3.2"
  },
  {
    "Version": "1.3.1"
  },
  {
    "Version": "1.3.0"
  },
REM ... snip ...
  {
    "Version": "0.2.0"
  },
  {
    "Version": "0.1.1"
  },
  {
    "Version": "0.1.0"
  }
]
```

## Windows PowerShell support

You can also call `tfalias.cmd` in Windows PowerShell console.  
PowerShell 5.0 - 5.1 is required.  

```powershell
# PowerShell 5.0 - 5.1 is required.
PS C:\> $PSVersionTable.PSVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      19041  1682

# You can use tfalias list with ConvertFrom-Json
PS C:\> tfalias list --json | ConvertFrom-Json

Current Version Path
------- ------- ----
  False X.Y.Z   C:\Users\stknohg\.tfalias\terraform\X.Y.Z\terraform.exe
   True 1.2.3   C:\Users\stknohg\.tfalias\terraform\1.2.3\terraform.exe
```