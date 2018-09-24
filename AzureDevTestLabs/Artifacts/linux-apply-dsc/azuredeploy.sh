#!/bin/bash

# Setup logging
LOGCMD='logger -i -t AZDEVTST_APPLYDSC --'
which logger
if [ $? -ne 0 ] ; then
    LOGCMD='echo [AZDEVTST_APPLYDSC] '
fi

$LOGCMD "------ Parameters: ------"
PARAM_OMI_RPM_LOCATION=${1}
PARAM_OMI_DEB_LOCATION=${2}
$LOGCMD "PARAM_OMI_RPM_LOCATION: $PARAM_OMI_RPM_LOCATION"
$LOGCMD "PARAM_OMI_DEB_LOCATION: $PARAM_OMI_DEB_LOCATION"

# See which package installer we have
apt=`command -v apt-get`
yum=`command -v yum`

# Setup Microsoft repository for packages
# Details here: https://docs.microsoft.com/en-us/windows-server/administration/Linux-Package-Repository-for-Microsoft-Software
$LOGCMD "------ Setup Microsoft repositories for RPM/DPKG ------"
SystemInfo=`uname -a`
if [$SystemInfo = *"RedHat7"*]; then
    sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
elif [$SystemInfo = *"RedHat6"*]; then
    sudo rpm -Uvh https://packages.microsoft.com/config/rhel/6/packages-microsoft-prod.rpm
elif [$SystemInfo = *"Ubuntu14"*]; then
    wget https://packages.microsoft.com/config/ubuntu/14.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
elif [$SystemInfo = *"Ubuntu16.04"*]; then
    wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get updateelse
elif [$SystemInfo = *"Ubuntu16.10"*]; then
    wget https://packages.microsoft.com/config/ubuntu/16.10/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
elif [$SystemInfo = *"SUSE12"*]; then
    sudo rpm -Uvh https://packages.microsoft.com/config/sles/12/packages-microsoft-prod.rpm
else
    $LOGCMD "This version of Linux is not supported for this artifact:  : "$SystemInfo
    exit 1;
fi

$LOGCMD "------ Installing OMI ------"
if [ -n "$apt" ]; then
    sudo apt-get install omi
elif [ -n "$yum" ]; then
    sudo yum install omi -y
else
    $LOGCMD "Unable to find either apt-get or yum, cannot proceed.."
    exit 1;
fi

$LOGCMD "------ Installing Linux DSC ------"
# Version of SSL available:
SSL=`openssl version`

# DSC package, info from here:  https://docs.microsoft.com/en-us/powershell/dsc/lnxgettingstarted
if [$SystemInfo = *"RedHat"*] || [$SystemInfo = *"SUSE"*]; then
    # RPM packages are appropriate for CentOS, Red Hat Enterprise Linux, SUSE Linux Enterprise Server, and Oracle Linux. 
    if [$SSL = "OpenSSL 1.0"*]; then
        curl -L -o "dsc_package.rpm" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm"
    elif [$SSL = "OpenSSL 0.9.8"*]; then
        curl -L -o "dsc_package.rpm" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_098.x64.rpm"
    else
        $LOGCMD "Version of Open SSL is not supported:  "$SSL
        exit 1;
    fi
elif [$SystemInfo = *"Ubuntu"*]; then
    # DEB packages are appropriate for Debian GNU/Linux and Ubuntu Server
    if [$SSL = "OpenSSL 1.0"*]; then
        curl -L -o "dsc_package.deb" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.deb"
    elif [$SSL = "OpenSSL 0.9.8"*]; then
        curl -L -o "dsc_package.deb" "https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_098.x64.deb"
    else
        $LOGCMD "Version of Open SSL is not supported:  "$SSL
        exit 1;
    fi
else
    $LOGCMD "Must have RedHat, SUSE, or Ubuntu Linux distribution, cannot proceed.."
    exit 1;
fi

$LOGCMD "All Prerequisites for Linux DSC are installed!"