# TerraformUtil

![build](https://github.com/stknohg/TerraformUtil/workflows/build/badge.svg)

PowerShell utility functions for [Terraform](https://www.terraform.io/).  

* [English](./README.md)

## 事前要求

* PowerShell 7 以降のバージョンに対応しています

## インストール方法

[PowerShell gallery](https://www.powershellgallery.com/packages/TerraformUtil/)からインストールできます。  

```powershell
Install-Module -Name TerraformUtil -Force
```

## TFAlias Functions

このモジュールでは[tfenv](https://github.com/tfutils/tfenv)と同等の機能を提供しています。  

### 比較表

|tfenv|TerraformUtil|notes|
|----|----|----|
|tfenv install|Set-TFAlias|Set-TFAliasでは自動的にTerraformをインストールします|
|tfenv use|Set-TFAlias||
|tfenv uninstall|Uninstall-TFAlias||
|tfenv list|Get-TFInstalledAlias||
|tfenv list-remote|Find-TFVersion|Find-TFReleaseも利用可能です|
|tfenv version-name|-|代わりに`Get-TFInstalledAlias -Current`を利用可能です|
|tfenv init|-|`Set-TFAlias -Initialize`が近い機能となります|
|tfenv pin|Set-TFAlias||

### Set-TFAlias

tfenvの様に`terraform`コマンドへのエイリアスを設定します。    

```powershell
# 初期化処理と、最新バージョンのTerraformをダウンロードします
C:\ > Set-TFAlias -Initialize

# 最新バージョンのTerraformに切り替えます
C:\ > Set-TFAlias -Latest
C:\ > terraform version
Terraform vX.Y.Z

# Terraform v.1.2.3に切り替えます
C:\ > Set-TFAlias -Version 1.2.3  
C:\ > terraform version
Terraform v1.2.3

# Terraformのバイナリはshim経由で実行されます
C:\ > Get-Command -Name 'terraform' | Select-Object CommandType, Name, Definition

CommandType Name      Definition
----------- ----      ----------
      Alias terraform C:\Users\stknohg\.tfalias\bin\terraform.ps1
```

> **Note**  
> 永続化する場合は `Set-TFAlias -Initialize` を [$PROFILE](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles) に記述してください

#### .terraform-version ファイルのサポート

tfenv同様Set-TFAliasでは[.terraform-version](https://github.com/tfutils/tfenv#terraform-version-file)ファイルをサポートしますが `min-required` と `latest-allowed` の扱いが異なります。    

* [min-required & latest-allowed](https://github.com/tfutils/tfenv#min-required--latest-allowed)

```terraform
// min-required

// tfenvは 0.12.3 と判定しますが、Set-TFAliasは 0.10.0 と判定します
terraform {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

```terraform
// latest-allowed

// tfenvだとエラーになりますが、Set-TFAliasは 0.12.2 と判定します
terraform {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

`Set-TFAlias -Pin`コマンドを使うと`.terraform-version`ファイルにピン止めできます。   

```powershell
# .terraform-version ファイルにピン止めできます
C:\temp > Set-TFAlias -Pin
Pinned version by writing "1.2.3" to C:\temp\.terraform-version
```

### Get-TFInstalledAlias

インストール済みの`terraform`エイリアスを取得します。  

```powershell
# 全てのインストール済みTerraformを取得
C:\ > Get-TFInstalledAlias

Current Version   Path
------- -------   ----
  False X.Y.Z     C:\Users\stknohg\.tfalias\terraform\X.Y.Z\terraform.exe
   True 1.2.3     C:\Users\stknohg\.tfalias\terraform\1.2.3\terraform.exe
```

### Uninstall-TFAlias

`terraform`エイリアスをアンインストールします。  

```powershell
# Terraform v1.2.3をアンインストール
C:\ > Uninstall-TFAlias -Version 1.2.3
Uninstall Terraform v1.2.3
```

## TFAlias for Command Prompt

> **Note**  
> これは試験的な機能であり、非サポートです

* [[Experimental] TFAlias for Command Prompt](./TFAliasForCmd.md)

## Other Functions

### Register-TFArgumentCompleter

`terraform`コマンドに対する入力補完を登録します。  

```powershell
# auto-completerの登録
Register-TFArgumentCompleter
```

### UnRegister-TFArgumentCompleter

`terraform`コマンドに対する入力補完を解除します。  

```powershell
# auto-completerの解除
UnRegister-TFArgumentCompleter
```

### Find-TFRelease

[Hashicorp Releases API](https://releases.hashicorp.com/docs/api/v1/#operation/listReleasesV1)を使いTerraformのリリース情報を取得します。  

> **Note**  
> 現時点ではページネーションを実装する予定はありません

```powershell
# 最新バージョンのリリース情報を取得
C:\ > Find-TFRelease -Latest

Version PreRelease State     Created              Updated
------- ---------- -----     -------              -------
1.3.2   False      supported 10/6/2022 4:57:24 PM 10/6/2022 4:57:24 PM
```

### Find-TFVersion

`tfenv list-remote`コマンドと同様に `https://releases.hashicorp.com/terraform` をスクレイピングしてTerraformのバージョンリストを取得します。  

> **Note**  
> オリジンへのアクセスを制限するため結果は10分キャッシュされます  

```powershell
# 全バージョン取得 (デフォルトで降順)
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

# -Filter スクリプトブロックを使用可能
C:\ > Find-TFVersion -Filter { $_ -lt '1.0.0' -and (-not $_.PreReleaseLabel) } -Take 1

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
0      15     5

# Find-TFReleaseへパイプ可能
C:\ > Find-TFVersion -Filter { $_ -lt '1.0.0' -and (-not $_.PreReleaseLabel) } -Take 1 | Find-TFRelease

Version PreRelease State     Created             Updated
------- ---------- -----     -------             -------
0.15.5  False      supported 6/2/2021 6:01:19 PM 6/2/2021 6:01:19 PM
```

### Save-TFBinary

特定バージョンのTerraformバイナリファイル(`terraform.exe`または`terraform`)を保存します。  

```powershell
# 最新バージョンのバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFBinary -Latest -DestinationPath C:\hashicorp\terraform

# Ver.1.2.9のバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFBinary -Version 1.2.9 -DestinationPath C:\hashicorp\terraform
```

### Save-TFSecBinary

特定バージョンの[Terraform securiy scanner](https://github.com/aquasecurity/tfsec)バイナリファイル(`tfsec.exe`または`tfsec`)を保存します。  

```powershell
# 最新バージョンのバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFSecBinary -Latest -DestinationPath C:\hashicorp\terraform

# Ver.1.23.3のバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFSecBinary -Version 1.23.3 -DestinationPath C:\hashicorp\terraform
```

### Save-TFLinterBinary

特定バージョンの[Linter](https://github.com/terraform-linters/tflint)バイナリファイル(`tflint.exe`または`tflint`)を保存します。  

```powershell
# 最新バージョンのバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFLinterBinary -Latest -DestinationPath C:\hashicorp\terraform

# Ver.0.40.0のバイナリを "C:\hashicorp\terraform" フォルダに保存
Save-TFLinterBinary -Version 0.40.0 -DestinationPath C:\hashicorp\terraform
```

### Write-TFLinterHCL

基本的な`.tflint.hcl`ファイル向けの設定内容を出力します。  
`-Plugin`パラメーターの値は [Terraform](https://github.com/terraform-linters/tflint), [AWS](https://github.com/terraform-linters/tflint-ruleset-aws),[AzureRM](https://github.com/terraform-linters/tflint-ruleset-azurerm), [Google](https://github.com/terraform-linters/tflint-ruleset-google) がサポートされています。  

```powershell
# terraform-provider-aws 向けの設定を出力
C:\Sample > Write-TFLinterHCL -Plugin AWS
plugin "aws" {
  enabled = true
  version = "0.17.1" # set the latest version automatically.
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# -Save パラメーターを使うと .tflint.hcl ファイルに内容を保存可能
C:\Sample > Write-TFLinterHCL -Plugin AWS -Save
Save configuration to ".tflint.hcl".

# もちろんリダイレクトを使って保存しても構いません
C:\Sample > Write-TFLinterHCL -Plugin AWS > '.tflint.hcl'
```

## アンインストール方法

```powershell
# Step 1. モジュールをアンインストールします
Uninstall-Module TerraformUtil -Force

# Step 2. "terraform"エイリアスを削除します
Remove-Alias terraform

# Step 3. "$HOME\.tfenv"ディレクトリを削除します
Remove-Item -LiteralPath (Join-Path $HOME '.tfalias') -Recurse
```

## ライセンス

* [MIT](./LICENSE)
