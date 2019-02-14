Param
(
	[Parameter(Mandatory=$true)]
    [string] $Users,

    [Parameter(Mandatory=$true)]
    [string] $Group,

    [Parameter]
    [bool] $AddOnly = $true,

    [Parameter]
    [bool] $KeepSystemAccounts = $true
)

Write-Output "---------------------------------"
Write-Output "windows-update-local-group artifact called with the following parameters:"
Write-Output "     Users = $Users"
Write-Output "     Group = $Group"
Write-Output "     AddOnly = $AddOnly"
Write-Output "     KeepSystemAccounts = $KeepSystemAccounts"
Write-Output "---------------------------------"

Write-Output "All Existing Groups + Users:"
$groups = Get-LocalGroup
foreach ($grp in $groups) {
    Write-Output "Group Name: $grp"
    $users = ([ADSI]"WinNT://./$grp").psbase.Invoke('Members') | % {
                         ([ADSI]$_).InvokeGet('AdsPath')
                     }
    $users | ForEach-Object {Write-Output "   $_"}
}
Write-Output "---------------------------------"

$systemAccounts = @{
    "Administrators" = @("Administrator")
    "Event Log Readers" = @("NT AUTHORITY/NETWORK SERVICE")
    "Guests" = @("Guest")
    "IIS_IUSRS" = @("NT Authority/IUSR")
    "Performance Log Users" = @("NT AUTHORITY/INTERACTIVE")
    "System Managed Accounts Group" = @("DefaultAccount")
    "Users" = @("NT AUTHORITY/INTERACTIVE", "NT AUTHORITY/Authenticated Users")
}

<#
# Is this a valid group?
$groupObj = Get-LocalGroup | Where-Object {$_.Name -eq $Group}
if ($groupObj) {
    # If we got here, it's a valid group - so let's get the current list of users
    # We can't use Get-LocalGroupMember because of a powershell bug:  https://github.com/PowerShell/PowerShell/issues/2996 
    # Method copied from here:  https://p0w3rsh3ll.wordpress.com/2016/06/14/any-documented-adsi-changes-in-powershell-5-0/
    $existingUsers = ([ADSI]"WinNT://./$Group").psbase.Invoke('Members') | % {
                         ([ADSI]$_).InvokeGet('AdsPath')
                     }
}
else {
    Write-Error "Unable to find local group named $Group "
    Write-Output "Available Local Groups:"
    Get-LocalGroup | Write-Output
}


#>