﻿###################################################################################################

#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
Push-Location $PSScriptRoot

###################################################################################################

#
# Functions used in this script.
#
$scriptFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
$functionFiles = Get-ChildItem -Path $scriptFolder\* -Include "*artifact-funcs*.ps1" -Exclude "*.tests.ps1" 
foreach($file in $functionFiles)
{
    $fileName = $file.Name
    ."./$fileName"
}

###################################################################################################

#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    Handle-LastError
}

###################################################################################################

#
# Main execution block.
#

try
{
    #arguments passed to this script should be passed to the artifact script
    #$command = $Script:MyInvocation.MyCommand
    $scriptName = $Script:MyInvocation.MyCommand.Name
    $scriptLine = $MyInvocation.Line
    $scriptArgIndex = $scriptLine.IndexOf($scriptName) + $scriptName.Length + 1
    if($scriptLine.Length -gt $scriptArgIndex)
    {
        $scriptArgs = $scriptLine.Substring($scriptArgIndex)
    }

    Invoke-Expression ".\artifact.ps1 $scriptArgs"

    Write-Host 'Artifact installed successfully.'
}
finally
{
    Pop-Location
}
