Param
(
	[Parameter(Mandatory=$true)]
    [string] $JDKVersion
)

Write-Output "Version of JDK to install: $JDKVersion"

if ($JDKVersion -eq "jdk10") {
    # Instal wix with chocolatey installer
    Write-Output "Installing via chocolatey package 'jdk10'"
    InstallChocoPackages jdk10
}
elseif ($JDKVersion -eq "jdk8") {
    # Instal wix with chocolatey installer
    Write-Output "Installing via chocolatey package 'jdk8'"
    InstallChocoPackages jdk8
}
elseif ($JDKVersion -eq "jdk7") {
    Write-Error "TODO!"
}
elseif ($JDKVersion -eq "jdk6") {
    # Instal wix with chocolatey installer
    Write-Output "Installing via chocolatey package 'java.jdk'"
    InstallChocoPackages java.jdk 
}
else {
    Write-Error "Invalid option, unable to install $JDKVersion"
}
