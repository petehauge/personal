Param
(
	[Parameter(Mandatory=$true)]
    [string] $dscConfiguration
)

# Location to save the DSC configuration, subfolder from script location
$dscPath = Join-Path -Path $env:TEMP -childPath "DSC"

if (Test-Path $dscPath) {
    # If the directory exists, remove it, probably left over from prior iteration
    Remove-Item -Recurse -Path $dscPath -Force
}

# Create the DSC directory
New-Item -Path $env:TEMP -Name "DSC" -ItemType Directory

$localDSCFile = Join-Path $dscPath "configuration.ps1"
# if the local file exists, delete it (must be from prior iteration)
if (Test-Path $localDSCFile) {
    Remove-Item -Path $localDSCFile -Force
}

# Write out the dsc configuration to a local file location
$dscConfiguration | Out-File -FilePath $localDSCFile -Force

# Execute the DSC configuration
. $localDSCFile

# Figure out the configuration entries in the DSC configuration
$configurationEntries = Get-Content $localDSCFile | Where-Object {$_.Trim().StartsWith("configuration", $true, $null)} | ForEach-Object {$_.Split(' ')[1].Replace('{','')}
Write-Output "Configuration entries discovered: "
Write-Output $configurationEntries

# Find the MOF files that were generated
$MofDirectories = Get-ChildItem -Path (Resolve-Path .) -Recurse -Filter "*.mof" | ForEach-Object { $_.Directory }

# Run the DsC Configurations
$MofDirectories | ForEach-Object {Start-DscConfiguration -Path $_.FullName -Wait -Force}

Write-Output "Completed applying the DSC configurations"
