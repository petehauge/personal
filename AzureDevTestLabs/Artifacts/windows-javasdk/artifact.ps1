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
else if ($JDKVersion -eq "jdk8") {
    # Instal wix with chocolatey installer
    Write-Output "Installing via chocolatey package 'jdk8'"
    InstallChocoPackages jdk8
}
else if ($JDKVersion -eq "jdk7") {
    Write-Output "TODO!"
}
else if ($JDKVersion -eq "jdk6") {
    # Instal wix with chocolatey installer
    Write-Output "Installing via chocolatey package 'java.jdk'"
    InstallChocoPackages java.jdk 
}

