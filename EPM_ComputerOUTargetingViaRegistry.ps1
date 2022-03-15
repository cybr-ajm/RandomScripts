#Define OU to target
$targetOU = ""

#Retrieve full DN of this machine from registray
$machineDN = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\DataStore\Machine\0" -Name "DNName"

if([string]::IsNullOrWhiteSpace($machineDN)){

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM OU targeting condition not met, could not retrieve machine DN from registry" -Category 1 -RawData 10,20
    exit 1;
    
}elseif([string]::IsNullOrWhiteSpace($targetOU)){

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM OU targeting condition not met, no target OU specified" -Category 1 -RawData 10,20
    exit 1;
    
}elseif($machineDN -notmatch $targetOU){

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM OU targeting condition not met, $machineDN is not in $targetOU" -Category 1 -RawData 10,20
    exit 1;
    
}else{

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM OU targeting condition is met, $machineDN is in $targetOU" -Category 1 -RawData 10,20
    exit 0;
}
