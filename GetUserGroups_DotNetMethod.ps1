﻿Function Get-LoggedOnUser {
 
    param (
     [parameter(Mandatory=$False)]
     [ValidateNotNullOrEmpty()]$ComputerName
    )
     
    if($ComputerName -eq $Null) {
        $username = (Get-Process Explorer -IncludeUsername | Where-Object { $_.username -notlike "*SYSTEM" }).username
    }
    else {
 
        $username = (Invoke-Command {Get-Process Explorer -IncludeUsername | Where-Object { $_.username -notlike "*SYSTEM" }} -ComputerName $ComputerName).username
    }
    return $username
}

#EPM Path
$startTime = date
$epmPath = "C:\Program Files\CyberArk\Endpoint Privilege Manager\Agent\tmp\scripts\"

#Load the Account Managment .Net Assembly
$am = Add-Type -AssemblyName System.DirectoryServices.AccountManagement

#Get sAMAccount of current active user
$loggedOnUser = Get-LoggedOnUser localhost

if($loggedOnUser -ne $null){

    $domain, $user = $loggedOnUser -split '\\'

    #Create principal context object (current domain/user)
    $pc = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain,$domain)

    #Load the user details from AD
    $userDetails = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($pc,$user)

    #Get list of group members
    $groupList = $userDetails.getGroups() | Select-Object -ExpandProperty SamAccountName
    $cacheFilePath = "$epmPath$user" + "_$domain" +"_groupCache.csv"
    Clear-Content $cacheFilePath

    foreach($grp in $groupList){
        $fullGrpName = "$domain\$grp"
        $fullGrpName | out-file $cacheFilePath -Append
        }

    #Cache Results to protected file
    $endTime = date
    $elapsedTime = ($endTime - $startTime).TotalSeconds

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM group caching for user $user complete. `n$cacheFilePath updated.`nElapsed Time: $elapsedTime seconds" -Category 1 -RawData 10,20
    exit 0;
} else{

    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM group caching did not complete, could not identify logged on user" -Category 1 -RawData 10,20
    exit 0;
}


