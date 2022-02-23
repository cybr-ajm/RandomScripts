Import-Module ActiveDirectory
#Target Computer Account OU
    $targetOU = "CN=Computers,DC=CYBR,DC=COM"
#Get this computer's DN
    $computerObject = Get-ADComputer -Identity $env:COMPUTERNAME
    $computerDN = $computerObject.DistinguishedName

#Compare Membership with Target Groups(s).
if ($computerDN -match $targetOU) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1000 -EntryType Information -Message "CONDITION MATCHED - $computerHostName is in $targetOU" -Category 1 -RawData 10,20
exit 0;
}
else
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "CONDITION NOT MATCHED -$computerHostName is not in $targetOU" -Category 1 -RawData 10,20
exit 1;
}
