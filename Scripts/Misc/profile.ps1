<#
.SYNOPSIS
This function just lists out available Azure Powershell Module versions available local to your machine

.DESCRIPTION
This is a wrapper function for "Get-Module" to see what versions of AzureRm/AZ modules you have available locally on your machine

.EXAMPLE
Install-AzureModuleVersion -MajorVersion 1

.LINK
https://github.com/petehauge/personal/Scripts/Misc/profile.ps1
#>
Function Get-AzureModuleVersions {
    Get-Module -ListAvailable | Where-Object {$_.Name -eq "AzureRm" -or $_.Name -eq "Az.Accounts"}
}

<#
.SYNOPSIS
This function selects a particular AzureRM module version and unloads all others

.DESCRIPTION
When developing Azure Powershell scripts, I often find the need to test with various
versions of Azure Powershell to confirm that breaking changes wouldn't break the script or
to adapt the script to work with various versions.  It's tough to 'flip' between Azure versions,
this function aims to make switching between AzureRm versions easier

.EXAMPLE
Select-AzureRmVersion -MajorVersion 6

.LINK
https://github.com/petehauge/personal/Scripts/Misc/profile.ps1
#>
function Select-AzureModuleVersion {
    param
    (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="The major version for Azure Powershell Modules to select.  Version 1 is for the new Az module")]
        [ValidateSet(1, 4, 5, 6)]
        [int] $MajorVersion
    )

    $modules = Get-Module | Where-Object {$_.Name.ToLower().StartsWith("azurerm") -or $_.Name.ToLower().StartsWith("az")}
    if ($modules) {
        $modules | Remove-Module
        Write-Output "Azure Modules just removed from the session.  Please restart powershell and then call 'Select-AzureModuleVersion' again"
    }
    else {
        if ($MajorVersion -eq 1) {
            Import-Module -Name Az -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force  -AllowClobber
            $module = Get-Module -Name Az
            if ($module) {
                Write-Output "Azure Module loaded (Az), version $($module.Version.ToString())"
            }
        }
        else {
            Import-Module -Name AzureRm -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force  -AllowClobber
            $module = Get-Module -Name AzureRm
            if ($module) {
                Write-Output "Azure Modules loaded (AzureRm), version $($module.Version.ToString())"
            }
        }
    }
}

<#
.SYNOPSIS
This function installs a particular AzureRM module major version, must be run as admin

.DESCRIPTION
This is a wrapper function for "Install-Module" and must be run as administrator.  The
goal is to reduce the amount of 'stuff' you need to know to flip between azure powershell versions.
In this case, all you need is a major version number for AzureRm/Az modules.  As of this writing,
the latest major version of Azure Powershell is an Az module version 1 .

.EXAMPLE
Install-AzureModuleVersion -MajorVersion 6

.LINK
https://github.com/petehauge/personal/Scripts/Misc/profile.ps1
#>
function Install-AzureModuleVersion {
    param
    (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="The major version for Azure Powershell to install.  Version 1 is for the new Az module.  This function needs to be run as admin")]
        [ValidateSet(1, 4, 5, 6)]
        [int] $MajorVersion
    )
    if ($MajorVersion -eq 1) {
        Install-Module -Name Az -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force -AllowClobber
    }
    else {
        Install-Module -Name AzureRm -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force -AllowClobber
    }

    Write-Output "The available version of Azure Powershell are:"
    Get-AzureModuleVersions
}

# Function to walk all the dependencies and completely uninstall a version of Azure Powershell Modules, copied and tweaked
# from this location:  https://docs.microsoft.com/en-us/powershell/azure/uninstall-azurerm-ps?view=azurermps-6.4.0
function Uninstall-AzureModules {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version,

        [switch]$Force
    )

    $AllModules = @()

    if ($Version.StartsWith('1')) {
        $moduleName = "Az"
    }
    else {
        $moduleName = "AzureRm"
    }

    'Creating list of dependencies...'
    $target = Find-Module $moduleName -RequiredVersion $version
    $target.Dependencies | ForEach-Object {
        $AllModules += New-Object -TypeName psobject -Property @{name=$_.name; version=$_.requiredversion}
    }

    $AllModules += New-Object -TypeName psobject -Property @{name=$moduleName; version=$Version}

    foreach ($module in $AllModules) {
        if (-not $module.Version) {
            #if the module version is blank, let's assume that it's the main version above...  this is a workaround
            $module.Version = $Version
        }

        Write-Host ('Uninstalling {0} version {1}' -f $module.name,$module.version)
        try {
            Uninstall-Module -Name $module.name -RequiredVersion $module.version -Force:$Force -ErrorAction Stop
        } catch {
            Write-Host ("`t" + $_.Exception.Message)
        }
    }
}