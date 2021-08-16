This artifact joins the virtual machine to the corporate domain.  After execution of the artifact it will be rebooted automatically and then you will be able to login with your user account directly on the virtual machine.

To generate the salted password - use the following powershell:
$pass = "MyNewPass!!"
$sec = ConvertTo-SecureString -String $pass -AsPlainText -Force
$key = (82,84,27,76,141,213,89,157,89,129,210,23,90,99,44,226,40,209,230,121,214,40,207,211)
$secstr = ConvertFrom-SecureString -SecureString $sec -Key $key
$secstr