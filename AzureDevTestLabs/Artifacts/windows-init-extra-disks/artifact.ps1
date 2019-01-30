param(
	[Parameter(Mandatory=$true)]
	[string] $projectName,

	[Parameter(Mandatory=$true)]
	[string] $externalId,

	[Parameter(Mandatory=$false)]
	[string] $startingDriveLetter = 'F'

)
# Stop if there's an unexpected error
$ErrorActionPreference = 'stop'

Write-Output "Init Extra Disks script started with project:'$projectName' , externalid '$externalId', starting drive letter '$startingDriveLetter'"

# We need a powershell module to set NTFS permissions (for the Add-NTFSAccess commandlet)
#Install-Module NTFSSecurity -Scope AllUsers -Force
#Import-Module NTFSSecurity

$drives =  GET-WMIOBJECT win32_logicaldisk
Write-Output "Existing Drives are:"
Write-Output ($drives | Format-Table)

$disks = Get-Disk
Write-Output "Exsiting Disks are:"
Write-Output ($disks | Format-Table)

# First check if we have an existing drive at starting letter, if so, we need to fail out
$existingDrive = $drives | Where-Object {$_.DeviceID -eq "$($startingDriveLetter):"}

if ($existingDrive -eq $null) {
    # Get all the 'raw' disks - these are ones that have been attached to the VM but not initialized
    $newDisks = Get-Disk | Where-Object PartitionStyle -eq 'raw' | Sort-Object Number
    $driveLetter = $startingDriveLetter

    if ($newDisks -ne $null) {
        $count = 0
        # We will attach all disks starting at the $startingDriveLetter and skipping any existing assigned letters
        foreach ($disk in $newDisks) {
            $disk | 
            Initialize-Disk -PartitionStyle MBR -PassThru |
            New-Partition -UseMaximumSize -DriveLetter $driveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel $('data' + $count) -Confirm:$false -Force
            
            $count ++
            $driveLetter = [char]([byte][char]$driveLetter + 1)
        }

        # Set up environment variables for the F drive
        $rootDir = "F:\ProjectFiles\"
        $projectName = $projectName.Replace('-',' ')
        $dir = $rootDir + ($projectName.Replace('-',' '))

        [Environment]::SetEnvironmentVariable("DataDirPath", $rootDir, "Machine")
        [Environment]::SetEnvironmentVariable("ProjectFolder", $projectName, "Machine")
        [Environment]::SetEnvironmentVariable("ExternalProjectId", $externalId, "Machine")

        # Set user access, users can have full control over project folders

        if(!(Test-Path -Path $dir )) {
            New-Item -ItemType directory -Path $dir
        }
	    
        # Add-NTFSAccess -Path $rootDir -Account 'Users' -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles

        Write-Output "Script to map raw drives, create project folders & apply NTFS permissions completed!"
    }
    else {
        Write-Error "No attached disks to initialize (Partition Style = RAW), unable to continue."
    }
}
else {
    Write-Error "Unable to mount data disk as Drive $startingDriveLetter - a drive with that letter already exists..."
}
