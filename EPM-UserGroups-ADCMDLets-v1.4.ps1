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
$groups = Get-ADPrincipalGroupMembership $user | select name


#Compare Membership with Target Groups(s).
if ($groups.name -match $TargetGroupX -or $groups.name -match $TargetGroupY ) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "CONDITION MATCHED - Policy Blocked, $user is a member of at least one of the following prohibited groups $TargetGroupX, $TargetGroupY." -Category 1 -RawData 10,20
exit 1;
}
elseif ($groups.name -match $TargetGroup1 -or $groups.name -match $TargetGroup2 -or $groups.name -match $TargetGroup3 ) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1000 -EntryType Information -Message "CONDITION MATCHED - $user is a member of at least one of the following groups $TargetGroup1, $TargetGroup2, $TargetGroup3 ." -Category 1 -RawData 10,20
exit 0;
}
elseif ($groups.name -match $TargetGroup4 -and $groups.name -match $TargetGroup5) 
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1000 -EntryType Information -Message "CONDITION MATCHED - $user is a member of $TargetGroup3 and $TargetGroup4." -Category 1 -RawData 10,20
exit 0;
}
else
{
Write-EventLog -LogName "Application" -Source "CyberArk EPM" -EventID 1001 -EntryType Information -Message "CONDITION NOT MATCHED - $user is not a member of the Target Groups, or a Domain Controller can not be reached" -Category 1 -RawData 10,20
exit 1;
}
