<#
.SYNOPSIS
This script creates a new VSTS project using the VSTS Rest APIs.

.DESCRIPTION
This is a script that wraps the VSTS Rest APIs for creating a project to enable execution via PowerShell

.EXAMPLE
.\New-TeamProject.ps1 -ExistingAccountName "PeteSoftwareStuff" -ProjectName "MyNewProject" -PatToken "reallylongstringofcharacters"

.LINK
https://github.com/petehauge/personal/Scripts/VSTS/New-TeamProject.ps1
#> 
param
(
    [Parameter(Mandatory=$true, HelpMessage="The Name of the existing VSTS Account, found in the URL:  https://<accountname>.visualstudio.com")]
    [string] $ExistingAccountName,

    [Parameter(Mandatory=$true, HelpMessage="The Name of the team project to create in the exisitng VSTS Account")]
    [string] $NewProjectName,

    [Parameter(Mandatory=$true, HelpMessage="A valid Personal Access Token to access VSTS and create a Team Project")]
    [string] $PatToken
)

# Clear the errors up front-  helps when running the script multiple times
$error.Clear()

Write-Output "Starting script to create a new Team Project named '$NewProjectName' in the account https://$ExistingAccountName.visualstudio.com !"

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PatToken")))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$uri = "https://$ExistingAccountName.visualstudio.com/_apis/projects?api-version=4.1"

$body=@"
{
    "name": "$NewProjectName",
    "description": "Team Project created automatically for $NewProjectName team cloud",
    "capabilities": {
        "versioncontrol": {
            "sourceControlType": "Git"
        },
        "processTemplate": {
            templateTypeId: "ADCC42AB-9882-485E-A3ED-7678F01F66BC"
        }
    }
}
"@

# Make the call to queue up a project creation
$result = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Headers $headers -Body $body

# Monitor the async operation until it's complete
$asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
while ($asyncOperation.status -eq "inProgress") {
    Start-Sleep -Seconds 5
    $asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
}

# Check the result
if ($asyncOperation.status -eq "succeeded") {
    Write-Output "Successfully created VSTS project named $NewProjectName"
}
else {
    Write-Error "Error creating VSTS Project named $NewProjectName"
}

# Output the ayncOperation details in case there are other messages
Write-Output $asyncOperation