Set-StrictMode -Version 3.0
<#
.SYNOPSIS
    Register PowerShell completer for Terraform.
#>
function Register-TFArgumentCompleter ([string]$CommandName = 'terraform') {
    if ([string]::IsNullOrEmpty($CommandName)) {
        $CommandName = 'terraform'
    }
    if ( -not (IsTerraformInstalled) ) {
        return
    }

    # register completer
    Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $env:COMP_LINE = $commandAst.ToString()
            terraform | ForEach-Object {
                $toolTip = switch ($_) {
                    # Main commands
                    'init' { 'Prepare your working directory for other commands' }
                    'validate' { 'Check whether the configuration is valid' }
                    'plan' { 'Show changes required by the current configuration' }
                    'apply' { 'Create or update infrastructure' }
                    'destroy' { 'Destroy previously-created infrastructure' }
                    # All other commands:
                    'console' { 'Try Terraform expressions at an interactive command prompt' }
                    'fmt' { 'Reformat your configuration in the standard style' }
                    'force-unlock' { 'Release a stuck lock on the current workspace' }
                    'get' { 'Install or upgrade remote Terraform modules' }
                    'graph' { 'Generate a Graphviz graph of the steps in an operation' }
                    'import' { 'Associate existing infrastructure with a Terraform resource' }
                    'login' { 'Obtain and save credentials for a remote host' }
                    'logout' { 'Remove locally-stored credentials for a remote host' }
                    'metadata' { 'Metadata related commands' }
                    'output' { 'Show output values from your root module' }
                    'providers' { 'Show the providers required for this configuration' }
                    'refresh' { 'Update the state to match remote systems' }
                    'show' { 'Show the current state or a saved plan' }
                    'state' { 'Advanced state management' }
                    'taint' { 'Mark a resource instance as not fully functional' }
                    'test' { 'Experimental support for module integration testing' }
                    'untaint' { 'Remove the ''tainted'' state from a resource instance' }
                    'version' { 'Show the current Terraform version' }
                    'workspace' { 'Workspace management' }
                    # Global options (exclude -chdir)
                    '-help' { 'Show this help output, or the help for a specified subcommand.' }
                    '-version' { 'An alias for the "version" subcommand.' }
                    # Others
                    '-install-autocomplete' { 'Install tab-completion configuration for bash and zsh.' }
                    '-uninstall-autocomplete' { 'Unnstall tab-completion configuration for bash and zsh.' }
                    # deprecated
                    'env' { '[Deprecated] Use "terraform workspace" instead.' }
                    'push' { '[Deprecated] Use Terraform Cloud CLI integration instead.' }
                    Default { $_ }
                }
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $toolTip)
            }
        } catch {
            # Record exception to $Error.
            Write-Error $_
        } finally {
            Remove-Item Env:\COMP_LINE
        }
    }
}

<#
.SYNOPSIS
    UnRegister PowerShell completer for Terraform.
#>
function UnRegister-TFArgumentCompleter ([string]$CommandName = 'terraform') {
    if ([string]::IsNullOrEmpty($CommandName)) {
        $CommandName = 'terraform'
    }
    if ( -not (IsTerraformInstalled) ) {
        return
    }
    
    # unregister completer
    Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock $null
}
