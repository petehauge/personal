###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Hide any progress bars, due to downloads and installs of remote components.
$ProgressPreference = "SilentlyContinue"

$functionUrl = "https://grant-ownership.azurewebsites.net/api"

# Ensure we force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Discard any collected errors from a previous execution.
$Error.Clear()

# Allow certian operations, like downloading files, to execute.
Set-ExecutionPolicy Bypass -Scope Process -Force

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe artifact failed to apply.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Main execution block.
#

try
{
    Write-Host 'Getting the underlying Compute resource ID'

    Try {
        $metadata = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -ErrorAction SilentlyContinue
        $resourceId = $metadata.compute.resourceId
    
        if ($resourceId) {
            Write-Host "ResourceId: $resourceId"
        }
        else {
            Write-Error "Unable to get the underlying compute Resource ID for this virtual machine from the metadata endpoint..."
        }
    
    } 
    Catch {
        Write-Error "This computer doesn't appear to be an Azure Virtual Machine..."
    }

    Write-Host "With the resource ID, call the endpoint in Azure to update permissions..."

    $url = $functionUrl + $resourceId

    try {
        $result = Invoke-RestMethod -Method Post -Uri $url -ErrorAction SilentlyContinue

        if ($result) {
            Write-Host "Successfully updated permissions Compute VM"
        }

    }
    catch {
        Write-Error "Unable to call azure webhook at [$url]"
    }

    Write-Host "`nThe artifact was applied successfully.`n"
}
finally
{
    Pop-Location
}
