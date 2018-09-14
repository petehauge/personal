Param
(
	[Parameter(Mandatory=$true)]
    [string] $Executable,

    [Parameter(Mandatory=$true)]
    [string] $Parameters
)

Write-Output "Executable Provided:"
Write-Output $Executable

Write-Output "Parameters Provided:"
Write-Output $Parameters