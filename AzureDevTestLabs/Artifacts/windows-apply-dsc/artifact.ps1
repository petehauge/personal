Param
(
	[Parameter(Mandatory=$true)]
    [string] $dscConfiguration
)

# Location to save the DSC configuration, subfolder from script location
$dscPath = Join-Path -Path $env:TEMP -childPath "DSC"

if (Test-Path $dscPath) {
    # If the directory exists, remove it, probably left over from prior iteration
    Write-Output "Path $dscPath exists, removing it..."
    Remove-Item -Recurse -Path $dscPath -Force
}

# Create the DSC directory
$newDir = New-Item -Path $env:TEMP -Name "DSC" -ItemType Directory
Write-Output "Created directory for config files: $newDir" 

$localDSCFile = Join-Path $dscPath "configuration.ps1"
# if the local file exists, delete it (must be from prior iteration)
if (Test-Path $localDSCFile) {
    Remove-Item -Path $localDSCFile -Force | Out-Null
}

# Save the URL to the local file location
DownloadToFilePath $dscConfiguration $localDSCFile

if (Test-Path $localDSCFile) {

    # First make sure the machine is configured to accept DSC scripts
    Write-Output "Ensuring the VM can apply DSC scripts via 'winrm quickconfig -quiet'"
    winrm quickconfig -quiet

    # Upgrading the version of NuGet package manager on the system, in case DSC script has Imports
    Install-PackageProvider -Name NuGet -Force

    # Grab the DSC file contents so we can inspect the configuration elements
    $localDscFileContent = Get-Content $localDSCFile

    Write-Output "Installing modules used in DSC file..."
    $localDscFileContent | 
        Where-Object {$_.Trim().StartsWith("Import-DscResource", $true, $null)} | 
        ForEach-Object {"Install-Module -Name $($_.Split(' ')[-1]) -Force" } | 
        Get-Unique -AsString |
        ForEach-Object { 
            Write-Output "Running command: $($_)"
            Invoke-Expression $_ 
        }

    Write-Output "Executing the DSC Configuration"
    # Execute the DSC configuration
    . $localDSCFile

    # Figure out the configuration entries in the DSC configuration
    $configurationEntries = $localDscFileContent | Where-Object {$_.Trim().StartsWith("configuration", $true, $null)} | ForEach-Object {$_.Split(' ')[1].Replace('{','')}
    Write-Output "Configuration entries discovered: "
    Write-Output $configurationEntries

    # Find the MOF files that were generated
    $MofDirectories = Get-ChildItem -Path (Resolve-Path .) -Recurse -Filter "*.mof" | ForEach-Object { $_.Directory }

    # Run the DsC Configurations
    $MofDirectories | ForEach-Object {Start-DscConfiguration -Path $_.FullName -Wait -Force}

    Write-Output "Completed applying the DSC configurations"

}
else {
    Write-Error "Unable to download DSC Configuration from $dscConfiguration"
}
