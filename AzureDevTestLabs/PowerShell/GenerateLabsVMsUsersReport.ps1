$startTime = Get-Date

$subscriptions = "00000000-0000-0000-0000-000000000000", "00000000-0000-0000-0000-000000000000"

$labdetails = "labdetails-$(Get-Date -Format 'yyyy_MM_dd').csv"
$vmdetails = "vmdetails-$(Get-Date -Format 'yyyy_MM_dd').csv"

$fileLabInfo = Join-Path -Path (Resolve-Path ./) -ChildPath $labdetails
$fileVmInfo = Join-Path -Path (Resolve-Path ./) -ChildPath $vmdetails

if (Test-Path -Path $fileLabInfo){
    # if the file exists, delete the old one
    Remove-Item -Path $fileLabInfo
}

Write-Output "Creating file: $($fileLabInfo)"
New-Item $fileLabInfo -type file | Out-Null
Add-Content -Path $fileLabInfo -Value "SubscriptionId,SubscriptionName,LabName,LabResourceId,LabUId,TotalVMs,AutoStart,AutoShutdown,MarketplaceImages,Owners,Contributors,DevTestLabsUsers"

if (Test-Path -Path $fileVmInfo){
    # if the file exists, delete the old one
    Remove-Item -Path $fileVmInfo
}

Write-Output "Creating vm info file: $($fileVmInfo)"
New-Item $fileVmInfo -type file | Out-Null
Add-Content -Path $fileVmInfo -Value "SubscriptionId,SubscriptionName,LabName,LabResourceId,LabUId,VMUId, VirtualMachineName,OwnerName,CreatedBy,StorageType,OsType,Size,Notes,allowClaim,AutoStart,AutoShutdown,PrivateIP,PublicIP,FQDN"

foreach ($subscription in $subscriptions) {

    # select the subscription
    $subinfo = Select-AzureRmSubscription -SubscriptionId $subscription

    # Give me all labs in the subscription
    $devTestLabs = Get-AzureRmResource -ResourceType 'Microsoft.DevTestLab/labs'

    foreach ($devTestLab in $devTestLabs) {

        # Replace any commas just so it doesn't break the CSV file
        $labName = $devTestLab.Name.Replace(",", " ")

        Write-Output "Getting PS Lab information for $labName"    

        $labResourceID = $devTestLab.ResourceId
        $labResource = Get-AzureRmResource -ResourceId $labResourceID

        $labData = @{}
        $labData.Add("SubscriptionId", $subscription)
        $labData.Add("SubscriptionName", $subinfo.Subscription.Name)
        $labData.Add("DevTestLabName",$labName)
        $labData.Add("ResourceId", $devTestLab.ResourceId)
        $labData.Add("uniqueID", $labResource.Properties.uniqueIdentifier)

        $storageAcct = Get-AzureRmResource -ResourceId $labResource.Properties.artifactsStorageAccount
        $labData.Add("artifactStorage", $storageAcct.Name)
        $labData.Add("AutoShutDown", "Unknown")
        $labData.Add("AutoStart", "Unknown")

        Write-Output "Get Azure RM Resource schedules for $labName"

        try { $labVmsShutdown = Get-AzureRmResource -Name "$($labResource.Name)/LabVmsShutdown" -ResourceType "Microsoft.DevTestLab/labs/schedules" -ResourceGroupName $labResource.ResourceGroupName -ApiVersion 2016-05-15 } catch [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Entities.ErrorResponses.ErrorResponseMessageException] {}

        if ($labVmsShutdown -eq $null) {
            $labData.AutoShutDown = "Disabled"
        }
        else {
            $labData.AutoShutDown = $labVmsShutdown.Properties.Status
        }

        try { $labVmsStartup = Get-AzureRmResource -Name "$($labResource.Name)/LabVmAutoStart" -ResourceType "Microsoft.DevTestLab/labs/schedules" -ResourceGroupName $labResource.ResourceGroupName -ApiVersion 2016-05-15 } catch [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Entities.ErrorResponses.ErrorResponseMessageException] {}
        if ($labVmsStartup -eq $null) {
            $labData.AutoStart = "Disabled"
        }
        else {
            $labData.AutoStart = $labVmsStartup.Properties.Status
        }

        $marketplaceImages = "All"

        $allPolicies = Get-AzureRmResource -ResourceType 'Microsoft.DevTestLab/labs/policySets/policies' `
                            -ResourceName ($labResource.Name + '/default') `
                            -ResourceGroupName $labResource.ResourceGroupName `
                            -ApiVersion 2018-10-15-preview

        $allPolicies | Where-Object {$_.Name -eq 'GalleryImage'} | ForEach-Object {
            if ($_.Properties.status -ne "Disabled") {
                $marketplaceImages = ($_.Properties.threshold | ConvertFrom-Json).Count
            }
        }
        $labData.Add("MarketplaceImages", $marketplaceImages)
  
        Write-Output "Get Owners, contributors and DevTest Labs Users for $labName"
        $userroles = Get-AzureRmRoleAssignment -ResourceName $devTestLab.Name -ResourceType $devTestLab.ResourceType -ResourceGroupName $devTestLab.ResourceGroupName | Where-Object {$_.Scope -eq $devTestLab.ResourceId} | Where-Object {$_.ObjectType -eq 'User'}
        $labOwners = ($userRoles | Where-Object {$_.RoleDefinitionName -eq "Owner"} | ForEach-Object {$_.SignInName.Replace(",",".")}) -Join ";"
        $labUsers = ($userRoles | Where-Object {$_.RoleDefinitionName -eq "DevTest Labs User"} | ForEach-Object {$_.SignInName.Replace(",",".")}) -Join ";"
        $labContributors = ($userRoles | Where-Object {$_.RoleDefinitionName -eq "Contributor"} | ForEach-Object {$_.SignInName.Replace(",",".")}) -Join ";"

        Write-Output "Get Owners, contributors and DevTest Labs Groups for $labName"
        $groupRoles = Get-AzureRmRoleAssignment -ResourceName $devTestLab.Name -ResourceType $devTestLab.ResourceType -ResourceGroupName $devTestLab.ResourceGroupName | Where-Object {$_.Scope -eq $devTestLab.ResourceId} | Where-Object {$_.ObjectType -eq 'Group'}
        $groupLabOwners = ($groupRoles | Where-Object {$_.RoleDefinitionName -eq "Owner"} | ForEach-Object {$_.DisplayName}) -Join ";"
        $groupLabUsers = ($groupRoles | Where-Object {$_.RoleDefinitionName -eq "DevTest Labs User"} | ForEach-Object {$_.DisplayName}) -Join ";"
        $groupLabContributors = ($groupRoles | Where-Object {$_.RoleDefinitionName -eq "Contributor"} | ForEach-Object {$_.DisplayName}) -Join ";"

        $allLabOwners = ($labOwners + ";" + $groupLabOwners).TrimEnd(";")
        $allLabUsers = ($labUsers + ";" + $groupLabUsers).TrimEnd(";")
        $allLabContributors = ($labContributors + ";" + $groupLabContributors).TrimEnd(";")
        
        Write-Output "Getting VMs in lab: $labname"
        # Get the virutal machines in the lab
        $virtualMachines = Get-AzureRmResource -ResourceGroupName $labresource.ResourceGroupName -Name $labResource.Name -ResourceType "Microsoft.DevTestLab/labs/virtualmachines" -ApiVersion 2016-05-15

        $vmCount = 0
        if ($virtualMachines -ne $null) {
            if ($virtualMachines.Count -gt 0) {
                $vmCount = $virtualMachines.Count   
            }
            else {
                $vmCount = 1
            }
        }
        $labData.Add("TotalVMs", $vmCount)

        Write-Output "Write $labname data to file"
        # "SubscriptionId,SubscriptionName,LabName,LabResourceId,LabUId,TotalVMs,AutoStart,AutoShutdown,MarketplaceImages,APEXId,Owners,Contributors,DevTestLabsUsers"
        Add-Content -Path $fileLabInfo -Value ($labdata.SubscriptionId + "," + $labdata.SubscriptionName + "," + $labData.DevTestLabName + "," + $labData.ResourceId + "," + $labData.uniqueID + "," + $labData.TotalVMs + "," + $labData.AutoStart + "," + $labData.AutoShutDown + "," + $labData.MarketplaceImages + "," + $allLabOwners + "," + $allLabContributors + "," + $allLabUsers)

        Write-Output "Checking if the VM info exists"

        $vms = @()

        # iterate through the vms to get:
        if ($virtualMachines -ne $null) {
            foreach ($virtualmachine in $virtualMachines) {
                $vm = @{}
                $vm.name = $virtualmachine.Name.Replace(",", " ")
                $vm.AutoShutDown = "Disabled"
                $vm.AutoStart = "Disabled"
                $vm.uniqueID = $virtualmachine.Properties.uniqueIdentifier
                if ($virtualmachine.Properties.ownerUserPrincipalName -ne $null) {
                    $vm.OwnerName = $virtualmachine.Properties.ownerUserPrincipalName.Replace(",", " ")
                }
                $vm.CreatedBy = $virtualmachine.Properties.createdByUser.Replace(",", " ")
                $vm.OsType = $virtualmachine.Properties.osType
                if ($virtualmachine.Properties.notes -ne $null) {
                    $vm.Notes = $virtualmachine.Properties.notes.Replace(",", " ")
                }
                else {
                    $vm.Notes = "";
                }
                $vm.StorageType = $virtualMachine.Properties.storageType
                $vm.allowClaim = $virtualmachine.Properties.allowClaim
                $vm.Size = $virtualmachine.Properties.Size
                # Sometimes have special case since some VMs were created before 'claim' feature was available
                if (($vm.allowClaim -eq $false) -and ($vm.OwnerName -eq $null)) {
                    $vm.OwnerName = $vm.CreatedBy
                }
                
                $scheds = Invoke-AzureRMResourceAction -Action "listApplicableSchedules" -ResourceId "$labResourceId/virtualmachines/$($vm.name)" -ApiVersion 2018-10-15-preview -Force  | ForEach-Object {

                    if ($_.Properties -match "LabVMsShutdown") {
                        $vm.AutoShutDown = $_.properties.labVmsShutdown.properties.Status
                    }

                    if ($_.Properties -match "LabVMsStartup") {
                        $vm.AutoStart = $_.properties.labVmsStartup.properties.Status
                    }
                }

                # Try to get the compute object, put in a try catch block so we don't get any red errors to the econsole when we can't find the resource
                try {
                    $computeObject = Get-AzureRMResource -ResourceId $virtualMachine.Properties.computeId
                }
                catch {
                }

                if ($computeObject -ne $null) {
                    $computeRG = $computeObject.ResourceGroupName
                    Get-AzureRmNetworkInterface -ResourceGroupName $computeRG | ForEach { 
                        $Interface = $_.Name
                        $IPs = $_ | Get-AzureRmNetworkInterfaceIpConfig | Select PrivateIPAddress
                        $vm.PrivateIp = $IPs.PrivateIPAddress 
                    }
                    $pubIp = Get-AzureRMPublicIPAddress -ResourceGroupName $computeRG
                    $vm.PublicIp = $pubip.IpAddress
                    $vm.FQDN = $pubIp.DnsSettings.Fqdn
                }
                else {
                    # The Compute node is missing, means it was deleted the Azure VM under DevTest Labs, but still has a "DevTest Labs VM".  This is an erorr state, let's write it in the csv file
                    $vm.FQDN = "ERROR:  COMPUTE NODE MISSING"
                }

                Write-Output "Write VM info for $($virtualmachine.Name) in $labname"

                # "SubscriptionId,LabName,LabResourceId,LabUId,VMUId, VirtualMachineName,OwnerName,StorageType,OsType,Size,Notes,allowClaim,AutoStart,AutoShutdown,PrivateIP,PublicIP,FQDN"
                Add-Content -Path $fileVmInfo -Value ($labdata.SubscriptionId + "," + $labdata.SubscriptionName + "," + $labData.DevTestLabName + "," + $labData.ResourceId + "," + $labData.uniqueID + "," + $vm.uniqueID + "," + $vm.name + "," + $vm.OwnerName + "," + $vm.CreatedBy + "," + $vm.StorageType + "," + $vm.OsType + "," + $vm.Size + "," + $vm.Notes + "," + $vm.allowClaim + "," + $vm.AutoStart + "," + $vm.AutoShutDown + "," + $vm.PrivateIp + "," + $vm.PublicIp + "," + $vm.FQDN)

            }
        }

    }
}

$totalScriptDuration = ((Get-Date) - $startTime)
Write-Output ("Total Script Duration was " + [math]::Round($totalScriptDuration.TotalMinutes,2) + " minutes (or " + [math]::Round($totalScriptDuration.TotalSeconds) + " seconds)")