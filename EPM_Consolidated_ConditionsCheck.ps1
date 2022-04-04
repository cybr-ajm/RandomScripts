<#
.SYNOPSIS
    An example of a multiple condition checking script, intended to allow for advanced
    targeting of CyberArk EPM Policies.

.DESCRIPTION
    This script checks for a series of conditions in order to determine if the current
    machine and user context should result in the application of certain CyberArk EPM Policies.
    These conditions are specific user group memberships, the Organizational Unit of the computer
    account, and a specific value in a property of a WMI class.  If all of the conditions evaluate
    to TRUE, the script will return and exit code of 0 (policy applies).  If any are FALSE, or fail to look up
    properly, it will return an exit code of 1 (policy does not apply).

.EXAMPLE
    There are currently no parameters for this class. It is intended to be used as an advanced
    policy script in CyberArk EPM.  For more information and instructions on using a policy targeting script:
    https://docs.cyberark.com/Product-Doc/OnlineHelp/EPM/Latest/en/Content/EPM/Server%20User%20Guide/AdvancedPolicyTargetingConditions.htm
    PS C:\> EPM_Consolidated_ConditionsCheck.ps1

.NOTES
    Filename: EPM_Consolidated_ConditionsCheck.ps1
    Author: adam.markert@cyberark.com
    Modified date: 2022-04-01
    Version 1.0 - Initial release
    Version 1.1 - Added additional flexibility to allow selection of any combination of conditions, set group checking to $false by default.
#>


### Variables for WMI Check, use $performWMICheck to toggle this condition check ###
$performWMICheck = $true
$WMIClassName = "Win32_ComputerSystem"
$WMIPropertyName = "Name"
$requiredWMIPropertyValue = "EPMWKS01"

### Variables for Computer OU Check ###
$performOUCheck = $true
$requiredOU = "OU=EPM Workstations,OU=CyberArk,DC=CYBR,DC=COM"

### Variables for Group Membership Check ###
$performGroupCheck = $false
$epmPath = "C:\Program Files\CyberArk\Endpoint Privilege Manager\Agent\tmp\scripts\"
#Target Group(s)
    #COLLECTION 1 - Member of at least one
        $TargetGroup1 = "CYBR\Domain Users"
        $TargetGroup2 = "CYBR\DevOps"
  #OR
    #COLLECTION 2 - Member of ALL groups
        $TargetGroup3 = "CYBR\CyberArk Endpoint Privilege Manager"
        $TargetGroup4 = "CYBR\CyberArk Vault Users"
  #AND
    #COLLECTION 3 - Member of ALL groups
        $TargetGroup5 = "CYBR\Windows Admins Nested"
  #AND
    #NOT a Member of this groups
        $TargetGroupX = "CYBR\EPM Pilot Users"


function Get-OUStatus(){
$machineDN = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\DataStore\Machine\0" -Name "DNName"

if([string]::IsNullOrWhiteSpace($machineDN)){
    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM Condition Check - EPM OU targeting condition not met, could not retrieve machine DN from registry" -Category 1 -RawData 10,20
    return $false;
    
}elseif([string]::IsNullOrWhiteSpace($requiredOU)){
    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM Condition Check - EPM OU targeting condition not met, no target OU specified" -Category 1 -RawData 10,20
    return $false;
    
}elseif($machineDN -notmatch $requiredOU){
    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM Condition Check - EPM OU targeting condition not met, $machineDN is not in $requiredOU" -Category 1 -RawData 10,20
    return $false;
    
}else{
    Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM Condition Check - EPM OU targeting condition is met, $machineDN is in $requiredOU" -Category 1 -RawData 10,20
    return $true;
}
}


function Get-WMIStatus(){
    $WMIPropertyValue

    try{
        $WMIPropertyValue = (Get-CimInstance -ClassName $WMIClassName -ErrorAction Stop).$WMIPropertyName
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "EPM Condition Check - $WMIClassName.$WMIPropertyName is $WMIPropertyValue." -Category 1 -RawData 10,20
    }
    catch{
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1003 -EntryType Information -Message "EPM Condition Check - Error checking WMI Property. Class may not exist." -Category 1 -RawData 10,20
        return $false
    }

    if($WMIPropertyValue -eq $requiredWMIPropertyValue){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1002 -EntryType Information -Message "EPM Condition Check - WMI Property Value of $WMIPropertyValue matches required value of $requiredWMIPropertyValue." -Category 1 -RawData 10,20
        return $true
    }else{
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1003 -EntryType Information -Message "EPM Condition Check - WMI Property Value of $WMIPropertyValue does not match required value of $requiredWMIPropertyValue." -Category 1 -RawData 10,20
        return $false
    }
}

function Get-GroupStatus(){
    $loggedOnUser = try{
        Get-LoggedOnUser localhost -ErrorAction Stop
        } catch {
            Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1003 -EntryType Information -Message "EPM Condition Check - Could not retrieve non-system interactive user, Group check aborting." -Category 1 -RawData 10,20
            return $false
        }

    $domain, $user = $loggedOnUser -split '\\'
    $groupCacheFile = "$epmPath$user" + "_$domain" +"_groupCache.csv"

    $groupCache = try{ Get-Content $groupCacheFile
        }catch{
               Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1003 -EntryType Information -Message "EPM Condition Check - Could not open group cache file $groupCacheFile. Validate the group cache exists." -Category 1 -RawData 10,20
               return $false;
        }

    #If domain is present on target group, trim off as we don't need it to compare to the cache

    $isGroupMember = @{}
    $isGroupMember[$TargetGroup1] = ($groupCache -contains $TargetGroup1)
    $isGroupMember[$TargetGroup2] = ($groupCache -contains $TargetGroup2)
    $isGroupMember[$TargetGroup3] = ($groupCache -contains $TargetGroup3)
    $isGroupMember[$TargetGroup4] = ($groupCache -contains $TargetGroup4)
    $isGroupMember[$TargetGroup5] = ($groupCache -contains $TargetGroup5)
    $isGroupMember[$TargetGroupX] = ($groupCache -contains $TargetGroupX)

    if($isGroupMember[$TargetGroupX]){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1010 -EntryType Information -Message "EPM Group Membership Check - DENIED - User is a member of $TargetGroupX, policy excluded." -Category 1 -RawData 10,20
        return $false;
    }

    if(($isGroupMember[$TargetGroup1] -or $isGroupMember[$TargetGroup2]) -and $isGroupMember[$TargetGroup5]){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1010 -EntryType Information -Message "EPM Group Membership Check - PASSED - User is a member of $TargetGroup1 or $TargetGroup2, and $TargetGroup5." -Category 1 -RawData 10,20
        return $true;
    }elseif($isGroupMember[$TargetGroup3] -and $isGroupMember[$TargetGroup4] -and $isGroupMember[$TargetGroup5]){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1010 -EntryType Information -Message "EPM Group Membership Check - PASSED - User is a member of $TargetGroup3, $TargetGroup4, and $TargetGroup5." -Category 1 -RawData 10,20
        return $true;
    }else{
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1010 -EntryType Information -Message "EPM Group Membership Check - DENIED - User is a not a member of the required groups." -Category 1 -RawData 10,20
        return $false;
    }
}

function Get-LoggedOnUser {
 
    param (
     [parameter(Mandatory=$False)]
     [ValidateNotNullOrEmpty()]$ComputerName
    )
     
    if($ComputerName -eq $Null) {
        $username = (Get-Process Explorer -IncludeUsername | Where-Object { $_.username -notlike "*SYSTEM" }).username
    }
    else {
 
        $username = (Get-Process Explorer -IncludeUsername | Where-Object { $_.username -notlike "*SYSTEM" }).username
    }
    return $username
}


if($performWMICheck){
    if(!(Get-WMIStatus)){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1020 -EntryType Information -Message "EPM Policy Checks Complete - WMI check Failed - Exiting 1" -Category 1 -RawData 10,20
        exit 1;
    }
}

if($performOUCheck){
    if(!(Get-OUStatus)){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1020 -EntryType Information -Message "EPM Policy Checks Complete - OU check Failed - Exiting 1" -Category 1 -RawData 10,20
        exit 1;
    }
}

if($performGroupCheck){
    if(!(Get-GroupStatus)){
        Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1020 -EntryType Information -Message "EPM Policy Checks Complete - Group check Failed - Exiting 1" -Category 1 -RawData 10,20
        exit 1;
    }
}

#If none of the enabled checks above fails, then exit 0.
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1020 -EntryType Information -Message "EPM Policy Checks Complete - All checks passed - Exiting 0" -Category 1 -RawData 10,20
exit 0;