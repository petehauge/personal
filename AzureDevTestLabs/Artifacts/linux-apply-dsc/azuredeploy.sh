#!/bin/bash

# Setup logging
LOGCMD='logger -i -t AZDEVTST_APPLYDSC --'
which logger
if [ $? -ne 0 ] ; then
    LOGCMD='echo [[AZDEVTST_APPLYDSC] '
fi

# Setup directory for working
mkdir AZDEVTEST_APPLYDSC
cd AZDEVTEST_APPLYDSC
currentDir=`pwd`
$LOGCMD "Current working directory: $currentDir"

ID=""
VERSION_ID=""

# Determine the distribution of Linux
if [ -f /etc/os-release ]; then
    # Load in variables for distribution
    . /etc/os-release
    $LOGCMD "Found standard linux distribution variable file"
elif [ -f /etc/redhat-release ]; then
    # For some RedHat, we have a special case because /etc/os-release file isn't present
    ID="rhel"
    RedHatRelease=`cat /etc/redhat-release`
    VERSION_ID=$(echo $RedHatRelease | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/')
    $LOGCMD "Found RedHat linux distribution variable file"
fi

$LOGCMD "Linux Distribution: $ID:$VERSION_ID"

if [[ -n $ID && -n $VERSION_ID ]]; then

    $LOGCMD "------ Parameters: ------"
    PARAM_DSC_CONFIGURATION=${1}
    $LOGCMD "PARAM_DSC_CONFIGURATION: $PARAM_DSC_CONFIGURATION"
    $LOGCMD "Linux Distribution: $ID:$VERSION_ID"
    $LOGCMD "Current working directory: $currentDir"

    curl -L -o "dscscript.ps1" "$PARAM_DSC_CONFIGURATION"
    if [ -f ./dscscript.ps1 ]; then

        # See which package installer we have
        apt=`command -v apt-get`
        yum=`command -v yum`

        # Setup Microsoft repository for packages
        # Details here: https://docs.microsoft.com/en-us/windows-server/administration/Linux-Package-Repository-for-Microsoft-Software
        $LOGCMD "------ Setup Microsoft repositories for RPM/DPKG ------"

        case "$ID:$VERSION_ID" in
        "ubuntu:14.04")
            curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
            curl https://packages.microsoft.com/config/ubuntu/14.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
            wget https://packages.microsoft.com/config/ubuntu/14.04/packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt-get update
            ;;
        "ubuntu:16.04")
            curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
            curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
            wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt-get update
            ;;
        "ubuntu:16.10")
            curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
            curl https://packages.microsoft.com/config/ubuntu/16.10/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
            wget https://packages.microsoft.com/config/ubuntu/16.10/packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt-get update
            ;;
        "rhel:7.2" | "rhel:7.3" | "rhel:7.4" | "rhel:7.5")
            sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
            ;;
        *)
            $LOGCMD "Distribution not supported: $ID:$VERSION_ID"
            exit 1
            ;;
        esac

        $LOGCMD "------ Installing OMI ------"
        if [[ -n "$apt" ]]; then
            sudo apt-get install omi
        elif [[ -n "$yum" ]]; then
            sudo yum install omi -y
        else
            $LOGCMD "Unable to find either apt-get or yum, cannot proceed.."
            exit 1;
        fi

        $LOGCMD "------ Installing Linux DSC ------"
        # Version of SSL available:
        SSL=`openssl version`

        # DSC package, info from here:  https://docs.microsoft.com/en-us/powershell/dsc/lnxgettingstarted

        case "$ID" in
        "ubuntu")
            # Install Powershell
            sudo apt-get install -y powershell

            # DEB packages are appropriate for Debian GNU/Linux and Ubuntu Server
            if [[ $SSL == "OpenSSL 1.0"* ]]; then
                curl -L -o "dsc_package.deb" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.deb"
            elif [[ $SSL == "OpenSSL 0.9.8"* ]]; then
                curl -L -o "dsc_package.deb" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_098.x64.deb"
            else
                $LOGCMD "Version of Open SSL is not supported:  "$SSL
                exit 1;
            fi

            sudo dpkg -i dsc_package.deb
            ;;
        "rhel")
            # Install Powershell
            sudo yum install -y powershell

            # RPM packages are appropriate for CentOS, Red Hat Enterprise Linux, SUSE Linux Enterprise Server, and Oracle Linux.
            if [[ $SSL == "OpenSSL 1.0"* ]]; then
                curl -L -o "dsc_package.rpm" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm"
            elif [[ $SSL == "OpenSSL 0.9.8"* ]]; then
                curl -L -o "dsc_package.rpm" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_098.x64.rpm"
            else
                $LOGCMD "Version of Open SSL is not supported:  "$SSL
                exit 1;
            fi
            
            sudo rpm -Uvh dsc_package.rpm
            ;;
        *)
            $LOGCMD "Distribution not supported for DSC package: $ID:$VERSION_ID"
            exit 1
            ;;
        esac

        $LOGCMD "All Prerequisites for Linux DSC are installed!"

        # Path to DSC python scripts
        PATH=$PATH:/opt/microsoft/dsc/Scripts

        # Copy the DSC modules over to the powershell directory so we can run the script
        sudo pwsh -Command "Copy-Item -Path /opt/microsoft/dsc/modules/* -Recurse -Destination \$PSHOME\Modules -Container -Force"

        $LOGCMD "Generating MOF file from powershell script"
        # Change to correct directory and run the powershell script
        sudo pwsh -Command "cd '$currentDir' ; . ./dscscript.ps1"

        $LOGCMD "Applying the DSC Configurations..."
        # Apply the MOF file and Log an error if we don't have any mof files
        foundMOF=false
        for filename in $(find $currentDir -name "*.mof" 2> /dev/null); do
            foundMOF=true
            $LOGCMD "MOF FILE: $filename"
            sudo /opt/microsoft/dsc/Scripts/StartDscConfiguration.py -configurationmof $filename
        done

        if [[ $foundMOF = true ]]; then
            $LOGCMD "Completed applying DSC Configuration!"
        else
            $LOGCMD "Unable to find MOF file, could not apply DSC configuration"
            exit 1
        fi

    else
        $LOGCMD "Unable to download DSC configuration, please check URL"
        exit 1
    fi
else
    $LOGCMD "Could not discover linux distribution...  Cannot proceed"
    exit 1
fi
