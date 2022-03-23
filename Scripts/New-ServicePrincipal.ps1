param
(
    [Parameter(Mandatory=$true, HelpMessage="Subscription to create service principal into")]
    [string] $SubscriptionId,
    [Parameter(Mandatory=$true, HelpMessage="Name of app")]
    [string] $ApplicationDisplayName

)
Import-Module Az.Resources

$sub = Get-AzSubscription -SubscriptionId $SubscriptionId

# Create the service principal!
$ServicePrincipal = New-AzADServicePrincipal -DisplayName $ApplicationDisplayName

Write-Host "--------------------------------------------------"
Write-Host "Service Principle Information"
Write-Host "Connection Name: $ApplicationDisplayName"
Write-Host "Subscription Id: $($sub.Id)"
Write-Host "Subscription Name: $($sub.Name)"
Write-Host "Service Principal Client Id: $($ServicePrincipal.AppId)"
Write-Host "Service Principal Key Id:  $($ServicePrincipal.PasswordCredentials[0].KeyId)"
Write-Host "Service Principal Key: $($ServicePrincipal.PasswordCredentials[0].SecretText)"
Write-Host "Tenant Id: $($sub.TenantId)"
Write-Host "Object Id: $($ServicePrincipal.Id)"
Write-Host "--------------------------------------------------"

Start-Sleep -Seconds 30

New-AzRoleAssignment -ObjectId $ServicePrincipal.Id -Scope "/subscriptions/$($sub.Id)" -RoleDefinitionName "Contributor"

