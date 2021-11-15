$allUsersPath = 'C:\Users\Public\Desktop'
$acl = Get-Acl -Path $allUsersPath

$identity = "NT AUTHORITY\INTERACTIVE"
$fileSystemRights = "DeleteSubdirectoriesAndFiles"
$type = "Allow"
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
$acl.SetAccessRule($fileSystemAccessRule)
Set-Acl -Path $allUsersPath -AclObject $acl