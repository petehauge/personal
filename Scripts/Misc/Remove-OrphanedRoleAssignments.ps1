

# Get Azure Subscription, prompt the user to make sure it's the right one
$subName = (Get-AzContext).Subscription.Name
$subId = (Get-AzContext).Subscription.Id
$response = Read-Host -Prompt "Are you sure this is the right subscription? '$subName' (y/n)"

if ($response -ieq 'y' -or $response -ieq 'yes') {
    Write-Host "Finding role assignments..."
    $roleAssignments = Get-AzRoleAssignment
    Write-Host "There are $($roleAssignments.Count) role assignments in this subscription"
    Write-Host "Finding orphaned role assignments (this will take some time)..."
    $unknownPrincipal = $roleAssignments | Where-Object {$_.ObjectType -ieq "Unknown"}
    $count = 0
    $orphanedRoleAssignments = $roleAssignments | ForEach-Object {
        # We need to exclude a few specific scopes (since we can't query if they exist)
        if ($_.Scope -like "*/microsoft.devtestlab/labs/*/users/*" -or
            $_.Scope -like "*/providers/Microsoft.Management/managementGroups*" -or
            $_.Scope -ieq "/subscriptions/$subId" -or
            $_.Scope -ieq "/") {

            Add-Member -InputObject $_ -MemberType NoteProperty -Name "Exists" -Value $true       
        }
        else {
            $rg = Get-AzResourceGroup -Id $_.Scope -ErrorAction SilentlyContinue
            if ($rg) {
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "Exists" -Value $true
            }
            else {
                $resource = Get-AzResource -Id $_.Scope -ErrorAction SilentlyContinue
                if ($resource) {
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name "Exists" -Value $true
                }
                else {
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name "Exists" -Value $false
                }
            }
            $count ++
            if ($count % 100 -eq 0) {
                Write-Host " ... checked $count role assignments"
            }
        }
        # Put the original object, with extra member, back on the pipeline
        $_
    } | Where-Object {-not $_.Exists}

    $orphanedCount = (($orphanedRoleAssignments | Measure-Object).Count)
    $response = Read-Host -Prompt "We found $orphanedCount orphaned role assignments, would you like to see the scopes? (y/n)"
    if ($response -ieq 'y' -or $response -ieq 'yes') {
        $orphanedRoleAssignments.Scope
    }

    $response = Read-Host -Prompt "Should we delete these $orphanedCount role assignments ? (y/n)"
    
    if ($response -ieq 'y' -or $response -ieq 'yes') {
        $orphanedRoleAssignments | Remove-AzRoleAssignment | Out-Null
    }
}
else {
    Write-Host "Ok, no problem, ending script..."
}
