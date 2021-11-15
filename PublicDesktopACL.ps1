#Get Current ACL on All Users Desktop
$allUsersPath = 'C:\Users\Public\Desktop'
$acl = Get-Acl -Path $allUsersPath

#Set Access Rules
$identity = "NT AUTHORITY\INTERACTIVE"
$fileSystemRights = "Read,Synchronize,DeleteSubdirectoriesAndFiles"
$type = "Allow"
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
$acl.SetAccessRule($fileSystemAccessRule)

#Set Audit Rules
$AuditUser = "Everyone"
$AuditRules = "Delete,DeleteSubdirectoriesAndFiles"
$InheritType = "ContainerInherit,ObjectInherit"
$AuditType = "Success"
$auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule($AuditUser,$AuditRules,$AuditType)
$acl.SetAuditRule($auditRule)

#Appy Changes
Set-Acl -Path $allUsersPath -AclObject $acl