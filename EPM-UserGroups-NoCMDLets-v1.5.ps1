#Target Group(s)
    #Member of at least one
        $TargetGroup1 = "Developers"
        $TargetGroup2 = "DevOps"
        $TargetGroup3 = "EPM Team"
    #Member of ALL groups
        $TargetGroup4 = "HelpDesk"
        $TargetGroup5 = "Developer Support"
    #NOT a Member of these groups
        $TargetGroupX = "Alpha"
        $TargetGroupY = "Beta"

#Get Group Membership for Logged on User
$user = query session | select-string Active | foreach { -split $_ } | select -index 1
$userDN = dsquery user -samid $user
$grouplist = dsget user $userDN -memberof -expand
$groups = $grouplist -join " "


#Compare Membership with Target Groups(s).
if ($groups -match $TargetGroupX -or $groups -match $TargetGroupY ) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "CONDITION MATCHED - Policy Blocked, $user is a member of at least one of the following prohibited groups $TargetGroupX, $TargetGroupY." -Category 1 -RawData 10,20
exit 1;
}
elseif ($groups -match $TargetGroup1 -or $groups -match $TargetGroup2 -or $groups -match $TargetGroup3 ) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1000 -EntryType Information -Message "CONDITION MATCHED - $user is a member of at least one of the following groups $TargetGroup1, $TargetGroup2, $TargetGroup3 ." -Category 1 -RawData 10,20
exit 0;
}
elseif ($groups -match $TargetGroup4 -and $groups -match $TargetGroup5) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1000 -EntryType Information -Message "CONDITION MATCHED - $user is a member of $TargetGroup3 and $TargetGroup4." -Category 1 -RawData 10,20
exit 0;
}
else
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "CONDITION NOT MATCHED - $user is not a member of the Target Groups, or a Domain Controller can not be reached" -Category 1 -RawData 10,20
exit 1;
}
