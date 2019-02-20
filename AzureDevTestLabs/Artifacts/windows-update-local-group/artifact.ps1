Param
(
	[Parameter(Mandatory=$true)]
    [string] $Users,  ## This can be a comma delimited set of users

    [Parameter(Mandatory=$true)]
    [string] $Group,

    [bool] $KeepSystemAccounts = $true,

    [bool] $AddOnly = $true
)

function OutputGroupMembers ($groups) {
    Write-Output "---------------------------------"
    foreach ($grp in $groups) {
        Write-Output "Group Name: $grp"
        $users = ([ADSI]"WinNT://$env:COMPUTERNAME/$grp").psbase.Invoke('Members') | % {
                             ([ADSI]$_).InvokeGet('AdsPath')
                         }
        $users | ForEach-Object {Write-Output "   $_"}
    }
    Write-Output "---------------------------------"
}

Write-Output "---------------------------------"
Write-Output "windows-update-local-group artifact called with the following parameters:"
Write-Output "     Users = $Users"
Write-Output "     Group = $Group"
Write-Output "     KeepSystemAccounts = $KeepSystemAccounts"
Write-Output "     AddOnly = $AddOnly"
Write-Output "---------------------------------"

Write-Output "All Existing Groups + Users:"
$groups = ([ADSI]"WinNT://$env:COMPUTERNAME").psbase.children | Where-Object {$_.psbase.SchemaClassName -eq "group"} | ForEach-Object {$_.Path -replace "WinNT://(.*)$env:COMPUTERNAME/", "" }
OutputGroupMembers $groups

$systemAccounts = @{
    "Administrators" = @("Administrator")
    "Event Log Readers" = @("NT AUTHORITY/NETWORK SERVICE")
    "Guests" = @("Guest")
    "IIS_IUSRS" = @("NT Authority/IUSR")
    "Performance Log Users" = @("NT AUTHORITY/INTERACTIVE")
    "System Managed Accounts Group" = @("DefaultAccount")
    "Users" = @("NT AUTHORITY/INTERACTIVE", "NT AUTHORITY/Authenticated Users")
}

# Is this a valid group?
if ($groups -contains $Group) {

    $groupObj = ([ADSI]"WinNT://$env:COMPUTERNAME/$Group")

    # If we got here, it's a valid group - so let's get the current list of users
    # We can't use Get-LocalGroupMember because of a powershell bug:  https://github.com/PowerShell/PowerShell/issues/2996 
    # Method copied from here:  https://p0w3rsh3ll.wordpress.com/2016/06/14/any-documented-adsi-changes-in-powershell-5-0/
    $existingUsers = $groupObj.psbase.Invoke('Members') | % {
                         ([ADSI]$_).InvokeGet('adspath').Replace('WinNT://', '')
                     }

    $usersList = $Users.Split(',') | ForEach-Object {
        if ($_ -match '.+[/\\].+') {
            # If the user is already formatted as domain\user, then just fix the slashes if necessary
            $_.Replace('\','/') 
        }
        else {
            # If the user isn't formatted as domain\user, we need to do it.  Assume local machine
            "$env:COMPUTERNAME/$_"
        }
    }

    # Add the list of users not already in the group
    $usersList | ForEach-Object {
        if ($existingUsers -notcontains $_) {
            Write-Output "User '$_' added to group '$Group'"
            $groupObj.add("WinNT://$_")
        }
    }

    # Remove the users who are not on the list passed in AND if we keep Sys accounts, not on the Sys accounts list
    if (-not $AddOnly) {
        $existingUsers | ForEach-Object {
            if ($usersList -notcontains $_) {
                if ($KeepSystemAccounts) {
                    if ($systemAccounts[$Group] -notcontains $_) {
                        # User account wasn't passed in, and isn't on the approved system list, so remove it
                        Write-Output "User '$_' removed from group '$Group'"
                        $groupObj.remove("WinNT://$_")
                    }
                }
                else {
                    # We arne't keeping system accounts, and user wasn't passed in, so remove them
                    Write-Output "User '$_' removed from group '$Group'"
                    $groupObj.remove("WinNT://$_")
                }
            }
        }
    }
    else {
        Write-Output "Only adding users (not removing any) becaues AddOnly flag was specified"
    }

    Write-Output "All Existing Groups + Users:"
    $groups = ([ADSI]"WinNT://$env:COMPUTERNAME").psbase.children | Where-Object {$_.psbase.SchemaClassName -eq "group"} | ForEach-Object {$_.Path -replace "WinNT://(.*)$env:COMPUTERNAME/", "" }
    OutputGroupMembers $groups

}
else {
    Write-Error "Unable to find local group named $Group "
    Write-Output "Available Local Groups:"
    Get-LocalGroup | Write-Output
}
