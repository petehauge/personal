Param
(
	[Parameter(Mandatory=$true)]
    [string] $Executable,

    [Parameter(Mandatory=$false)]
    [string] $Parameters
)

Write-Output "--------------------------"
Write-Output "Executable Provided:"
Write-Output "    $Executable"
Write-Output "Parameters Provided:"
Write-Output "    $Parameters"
Write-Output "--------------------------"

if ($Executable -match "http*") {
    Write-Output "Executable location is an http/https address, must download before executing"
    $tempLocation = Join-Path $env:TEMP "RunExeArtifact"

    # If the path exists, remove it - likely from prior iteration
    if (Test-Path $tempLocation) {
        Remove-Item -Path $tempLocation -Recurse -Force
    }

    $fileName = $Executable.Split('/')[-1];
    $fileLocation = Join-Path $tempLocation $fileName
    DownloadToFilePath $Executable $fileLocation

}
else {
    Write-Output "Executable location is local to the machine, skipping any download"
    
    # First call resolve-path in case there is any relative path info
    $fileLocation = Resolve-Path $Executable
}

# Confirm that the file exists
if (Test-Path $fileLocation) {

    $exeFile = Get-Item -Path $fileLocation
    
    # change directory to the appropriate location
    pushd $exeFile.Directory
   
    # Execute the file making sure to seperate the parameters
    & $fileLocation $Parameters.Split(' ')
}
else {
    Write-Error "Unable to locate executable: $fileLocation"
}

popd