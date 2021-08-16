if ($PSVersionTable.PSVersion.Major -lt 3) {
	Write-Error "The current version of PowerShell is $($PSVersionTable.PSVersion.Major). Prior to running this artifact, ensure you have PowerShell 3 or higher installed."
}
else {

    $key = (82,84,27,76,141,213,89,157,89,129,210,23,90,99,44,226,40,209,230,121,214,40,207,211)
    $encryptedStr = "76492d1116743f0423413b16050a5345MgB8ADcAeQByAEcAVQBPAE0AbgBGAGcAegBEAFcARwBMAGkAOQBvAGoARgBWAGcAPQA9AHwAMgA3AGQAZQA3ADAANwA4ADgAMQA2AGQAZgBjADUAZABiADQAMgAzADYAZQBlADMAMAAwADAAYQBlAGYAZQAyADMANAA2AGMAYQBkADYAZAA1ADYANgA3AGEAZAA2ADEAMgAxADEAMQBkADYAYwBkAGEANQA="
    $credential = New-Object System.Management.Automation.PSCredential('DOMAIN\SERVICEACCOUNT', (ConvertTo-SecureString -String $encryptedStr -Key $key))

    Write-Output "Attempting to join the domain..."
    [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -ComputerName $env:COMPUTERNAME -DomainName "US.DOMAIN.com" -Credential $credential -OUPath "OU=DTL,OU=Servers,OU=CLOUD,DC=US,DC=DOMAIN,DC=com" -Force -PassThru

    if ($computerChangeInfo.HasSucceeded) {
        Write-Output "Successfully joined the domain"

        Write-Output "Member of local VM Administrators Group:"
        $results = Invoke-Expression -Command "net localgroup administrators"
        Write-Output "Result: $results"

        # Last step, reboot the machine
        Write-Output "Restarting the virtual machine..."
        Restart-Computer -Force
    }
    else {
        Write-Error "Failed to join $env:COMPUTERNAME to US.DOMAIN.com domain"
    }
}
