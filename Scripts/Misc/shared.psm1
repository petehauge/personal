<#
.SYNOPSIS
This function logs out messages nicely using Write-Host.  The ##[] tags are highlighted when viewing the log in VSTS

.DESCRIPTION
This is a wrapper function for "Write-Host" that adds some extra text that is picked up and highlighted by VSTS

.EXAMPLE
Log "This is an example Message" $true

.LINK
https://github.com/petehauge/personal/Scripts/Misc/shared.psm1
#>
function Log ($message, $section) {
    if ($section) {
        # NOTE:  we use the tag ##[section] becuase VSTS automatically highlights this nicely in the log when looking in the portal...
        Write-Host " "
        Write-Host "--------------------------------------------------------------"
        Write-Host "##[section] $message"
        Write-Host "--------------------------------------------------------------"
    }
    else {
        # We use Out-Host in the pipeline here so we get nicely formatted objects if a PSCustomObject is passed in
        $message | Out-Host
    }
}

<#
.SYNOPSIS
This function gets the current script directory.  If run interactively (PowerShell ISE), gets the current directory instead

.DESCRIPTION
This is a wrapper function for "PSScriptRoot" that handles PowerShell interactive modes

.EXAMPLE
Log "This is an example Message" $true

.LINK
https://github.com/petehauge/personal/Scripts/Misc/shared.psm1
#>
function Get-ScriptDirectory {
    # Enable local debugging of the script
    if ($PSScriptRoot -eq "") {
        $currentDirectory = Resolve-Path "."
    }
    else {
        $currentDirectory = $PSScriptRoot
    }
    
    return $currentDirectory
}

<#
.SYNOPSIS
This function switches to another subscription only if required

.DESCRIPTION
Uses Get-AzureRmContext to determine existing subscription and only call Set-AzureRmContext if required

.EXAMPLE
SelectSubscription "39df6a21-006d-4800-a958-2280925030cb"

.LINK
https://github.com/petehauge/personal/Scripts/Misc/shared.psm1
#>
function SelectSubscription($subId){
    # switch to another subscription assuming it's not the one we're already on
    if((Get-AzureRmContext).Subscription.Id -ne $subId){

        Log "Switching to subscription $subId"

        $sub = Set-AzureRmContext -SubscriptionId $subId

        if ($sub -eq $null) {
            Write-Error "Unable to access subscription, perhaps you need ot run 'Add-AzureRmAccount -TenantId 0ae51e19-07c8-4e4b-bb6d-648ee58410f4' before running this script? Unable to proceed."
        }
    }
}

<#
.SYNOPSIS
This function saves the profile to a file, used in Powershell jobs (save & load profile to avoid requiring logins)

.DESCRIPTION
Uses SaveProfile to save the current profile to profile.json location.  Can be read in again with LoadProfile

.EXAMPLE
SaveProfile

.LINK
https://github.com/petehauge/personal/Scripts/Misc/shared.psm1
#>
function SaveProfile {
    $profilePath = Join-Path $PSScriptRoot "profile.json"

    If (Test-Path $profilePath){
	    Remove-Item $profilePath
    }
    
    Save-AzureRmContext -Path $profilePath
}

<#
.SYNOPSIS
This function loads back in a profile that was saved with SaveProfile function.  Typically used in Powershell jobs (save & load profile to avoid requiring logins)

.DESCRIPTION
Uses LoadProfile to load the profile saved in profile.json.  The profile.json file is created by calling the "SaveProfile" function above before launching powershell jobs.

.EXAMPLE
LoadProfile

.LINK
https://github.com/petehauge/personal/Scripts/Misc/shared.psm1
#>
function LoadProfile {
    $profilePath = Join-Path $PSScriptRoot "profile.json"
    Import-AzureRmContext -Path (Join-Path $profilePath "profile.json") | Out-Null
}

