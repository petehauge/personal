<#
.SYNOPSIS
This script deletes an existing VSTS project using the VSTS Rest APIs - be careful, you can't undo this action!

.DESCRIPTION
This is a script that wraps the VSTS Rest APIs for deleting a project to enable execution via PowerShell

.EXAMPLE
.\Remove-TeamProject.ps1 -ExistingAccountName "PeteSoftwareStuff" -ExistingProjectName "MyNewProject" -PatToken "reallylongstringofcharacters"

.LINK
https://github.com/petehauge/personal/Scripts/VSTS/New-TeamProject.ps1
#> 
param
(
    [Parameter(Mandatory=$true, HelpMessage="The Name of the existing VSTS Account, found in the URL:  https://<accountname>.visualstudio.com")]
    [string] $ExistingAccountName,

    [Parameter(Mandatory=$true, HelpMessage="The Name of the existing team project to delete in the exisitng VSTS Account")]
    [string] $ExistingProjectName,

    [Parameter(Mandatory=$true, HelpMessage="A valid Personal Access Token to access VSTS and delete a Team Project")]
    [string] $PatToken
)

# Clear the errors up front-  helps when running the script multiple times
$error.Clear()

Write-Output "Starting script to Delete a VSTS Project named '$NewProjectName' in the account https://$ExistingAccountName.visualstudio.com ..."

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PatToken")))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$projectsUri = "https://$ExistingAccountName.visualstudio.com/_apis/projects?api-version=4.1"

# Make the call to get the list of projects
$result = Invoke-RestMethod -Uri $projectsUri -Method Get -ContentType "application/json" -Headers $headers

$existingProject = $result.value | Where-Object {$_.name -eq $ExistingProjectName }

Write-Output "Existing Project:"
Write-Output $existingProject

if ($existingProject -ne $null) {
    # We found the existing project, let's delete it

    $deleteUri = "https://$ExistingAccountName.visualstudio.com/_apis/projects/$($existingProject.id)?api-version=4.1"

    # Make the call to delete the project
    $result = Invoke-RestMethod -Uri $deleteUri -Method Delete -ContentType "application/json" -Headers $headers

    # Monitor the async operation until it's complete
    $asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
    while ($asyncOperation.status -eq "inProgress") {
        Start-Sleep -Seconds 5
        $asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
    }

    # Check the result
    if ($asyncOperation.status -eq "succeeded") {
        Write-Output "Successfully deleted VSTS project named $ExistingProjectName"
    }
    else {
        Write-Error "Error removing VSTS Project named $ExistingProjectName"
    }

    Write-Output $asyncOperation
        
}
else {
    Write-Error "Unable to find existing VSTS project named $ExistingProjectName"
}

