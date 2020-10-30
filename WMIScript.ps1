cls
$target = "epmsvr01.cybr.com"          # replace <address> with the address of the target system
$service = "MSSQLSERVER"         # replace <service> with the name of the service to manage IE. MSSQLSERVER, SQLSERVERAGENT,
                               #   SQLBrowser, SQLWriter, MSSQLFDLauncher, MSSQLServerADHelper, msftesql, or MSSQL
$currentpass = (read-host -Prompt "Current Password: ") # replace <currentpass> with the current password for the service account on the target service
$newpass = (read-host -Prompt "New Password: ")         # replace <newpass> with the password to set for the service account on the target service
$svcAccountName = (read-host -Prompt "Service Account Name: ")

Set-ADAccountPassword $svcAccountName -NewPassword (ConvertTo-SecureString -AsPlainText $newpass -Force) -Credential $cred

$cred = Get-Credential
$CMs = @(Get-WmiObject -Query 'SELECT * FROM __namespace WHERE Name LIKE "ComputerManagement%"' -ComputerName $target -Credential $cred -Namespace 'root\Microsoft\SqlServer')
If ($CMs.count -gt 1) {
    Write-Warning "Multiple WMI ComputerManagement Namespaces found for SqlServer: $($CMs.Count)"
}

#Loop through each namespace to query the object.
foreach ($namespace in $CMs) {
	$WMIService = Get-WmiObject -Query "SELECT * from sqlservice where ServiceName = `"$service`"" -ComputerName $target -Credential $cred -Namespace "$($namespace.__NAMESPACE)\$($namespace.Name)"

    If ($WMIService -eq $null) {
        Write-Error "$service not found in $($namespace.__NAMESPACE)\$($namespace.Name)"
    }
    Else {
        Write-Host "$service found in $($namespace.__NAMESPACE)\$($namespace.Name).  Trying to set password."

        Try {
            $result = $WMIService.SetServiceAccountPassword($currentpass,$newpass)
        }
        Catch {
            Throw ($Error[0] | Select-Object -ExpandProperty Exception | Select-Object -ExpandProperty InnerException).tostring()
        }
        
        If ($result.ReturnValue -eq 0) {
            Write-Host -Object "Password Updated Successfully" -ForegroundColor Green
        }
        Else {
            Write-Host -Object "Password NOT Updated" -ForegroundColor Red
        }
        
        break    
    }
}