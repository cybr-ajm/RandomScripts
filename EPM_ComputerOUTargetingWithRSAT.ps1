#Required RSAT feature
$RSATModuleName = 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0'

#Check if RSAT AD tools (required for dsget/dsquery) is installed, install if not present
if( (Get-WindowsCapability -Name $RSATModuleName -Online).State -ne 'Installed' ){
    #install RSAT module
    Add-WindowsCapability -Name $RSATModuleName -Online
}

#Target Computer Account OU
$targetOU = "CN=Computers,DC=CYBR,DC=COM"
#Get this computer's DN
$computerHostName = $env:COMPUTERNAME
$computerDN = dsquery computer -name $env:COMPUTERNAME


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
