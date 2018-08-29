#!/bin/bash

PARAM_OMI_RPM_LOCATION=${1}
PARAM_OMI_DEB_LOCATION=${2}

trace() {
    TRACE_DATE=$(date '+%F %T.%N')
    echo ">>> $TRACE_DATE: $@" && echo ">>> $TRACE_DATE: $@" 1>&2
}

trace "Parameters:"
trace "PARAM_OMI_RPM_LOCATION: $PARAM_OMI_RPM_LOCATION"
trace "PARAM_OMI_DEB_LOCATION: $PARAM_OMI_DEB_LOCATION"

# trace "Installing OMI"

# sudo yum install omi

# For RPM based systems (RedHat, Oracle, CentOS, SuSE):
# sudo rpm -Uvh omi-1.3.0-2.ssl_100.ulinux.x64.rpm
# For DPKG based systems (Debian, Ubuntu, etc.):
# sudo dpkg -i omi-1.3.0-2.ssl_100.ulinux.x64.deb

#rpm --version
#installationStatus=$(echo $?)

# trace "Installing DSC"

