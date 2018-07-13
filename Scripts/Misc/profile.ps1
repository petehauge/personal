<#
.SYNOPSIS
This function just lists out available AzureRM versions available local to your machine

.DESCRIPTION
This is a wrapper function for "Get-Module" to see what versions of AzureRM you have availalbe locally on your machine

.EXAMPLE
Install-AzureRmVersion -MajorVersion 6

.LINK
https://github.com/petehauge/personal/Scripts/Misc/profile.ps1
#>
Function Get-AzureRmVersions {
    Get-Module -Name AzureRm -ListAvailable
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
function Select-AzureRmVersion {
    param
    (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="The major version for Azure Powershell to choose")]
        [ValidateSet(4, 5, 6)]
        [int] $MajorVersion
    )
    $modules = Get-Module | Where-Object {$_.Name.ToLower().StartsWith("azurerm")}
    if ($modules) {
        $modules | Remove-Module
        Write-Output "AzureRM Modules just removed from the session.  Please restart powershell and then call 'Select-AzureRmVersion' again"
    }
    else {
        Import-Module -Name AzureRm -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force
        $module = Get-Module -Name AzureRm
        if ($module) {
            Write-Output "AzureRM Modules loaded, version $($module.Version.ToString())"
        }
    }
}

<#
.SYNOPSIS
This function installs a particular AzureRM module major version, must be run as admin

.DESCRIPTION
This is a wrapper function for "Install-Module" and must be run as administrator.  The
goal is to reduce the amount of 'stuff' you need to know to flip between azure powershell versions.
In this case, all you need is a major version number for AzureRm modules.  As of this writing,
the latest major version of Azure Powershell is 6.

.EXAMPLE
Install-AzureRmVersion -MajorVersion 6

.LINK
https://github.com/petehauge/personal/Scripts/Misc/profile.ps1
#>
function Install-AzureRmVersion {
    param
    (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="The major version for Azure Powershell to install, this function needs to be run as admin")]
        [ValidateSet(4, 5, 6)]
        [int] $MajorVersion
    )

    Install-Module -Name AzureRm -MinimumVersion "$MajorVersion.0.0" -MaximumVersion "$MajorVersion.9.9" -Force

    Write-Output "The available version of Azure Powershell are:"
    Get-AzureRmVersions
}

# Function to walk all the dependencies and completely uninstall a version of AzureRm Powershell Modules, copied 
# from this location:  https://docs.microsoft.com/en-us/powershell/azure/uninstall-azurerm-ps?view=azurermps-6.4.0
function Uninstall-AllAzureRmModules {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version,

        [switch]$Force
    )

    $AllModules = @()

    'Creating list of dependencies...'
    $target = Find-Module "AzureRm" -RequiredVersion $version
    $target.Dependencies | ForEach-Object {
        $AllModules += New-Object -TypeName psobject -Property @{name=$_.name; version=$_.requiredversion}
    }

    $AllModules += New-Object -TypeName psobject -Property @{name="AzureRm"; version=$Version}

    foreach ($module in $AllModules) {
        Write-Host ('Uninstalling {0} version {1}' -f $module.name,$module.version)
        try {
            Uninstall-Module -Name $module.name -RequiredVersion $module.version -Force:$Force -ErrorAction Stop
        } catch {
            Write-Host ("`t" + $_.Exception.Message)
        }
    }
}