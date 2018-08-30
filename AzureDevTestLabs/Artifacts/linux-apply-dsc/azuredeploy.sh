#!/bin/bash

PARAM_OMI_RPM_LOCATION=${1}
PARAM_OMI_DEB_LOCATION=${2}

LOGCMD='logger -i -t AZDEVTST_LINUXDSC --'

$LOGCMD "Parameters:"
$LOGCMD "PARAM_OMI_RPM_LOCATION: $PARAM_OMI_RPM_LOCATION"
$LOGCMD "PARAM_OMI_DEB_LOCATION: $PARAM_OMI_DEB_LOCATION"

# $LOGCMD "Installing OMI"

# sudo yum install omi

# For RPM based systems (RedHat, Oracle, CentOS, SuSE):
# sudo rpm -Uvh omi-1.3.0-2.ssl_100.ulinux.x64.rpm
# For DPKG based systems (Debian, Ubuntu, etc.):
# sudo dpkg -i omi-1.3.0-2.ssl_100.ulinux.x64.deb

#rpm --version
#installationStatus=$(echo $?)

# $LOGCMD "Installing DSC"

