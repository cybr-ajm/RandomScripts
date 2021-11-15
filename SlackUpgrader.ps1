#Variables
$slackExePath = 'C:\Program Files\Slack\slack.exe'
$slackRSSFeed = 'https://slack.com/release-notes/windows/rss'
$slackMSIPath = 'https://slack.com/ssb/download-win64-msi'
$slackDownloadPath = "$env:UserProfile\Downloads\slack.msi"
$latestSlackVersion = $null
$installedSlackVersion = $null
$logFile = 'c:\temp\slackUpdater.log'

#Get most recent version of Slack from RSS feed
function Get-LatestSlackVersion {

    try{
        $slackVersions = invoke-restmethod -Uri $slackRSSFeed
        $latestVersionTitle = $slackVersions[0].title
        $latestVersion = $latestVersionTitle -match '(Slack\s)(\d+[.]\d+[.]\d+)'
        return $Matches[2]
    }
    catch{
        "Could not retrieve latest Slack version. Check RSS feed and internet connectivity and try again." *>> $logFile
    }

}

function Get-InstalledSlackVersion {
    try{
        return (Get-Item $slackExePath).VersionInfo.FileVersion
    }
    catch {
        "Unable to get current Slack version, Slack is probably not installed or is installed in a non-standard path." *>> $logFile
    }

}

function Retrieve-LatestSlackVersion {
    try{
        Invoke-WebRequest -Uri $slackMSIPath -OutFile $slackDownloadPath
    }
    catch {
    "Could not download latest Slack version. Check internet connectivity and try again." *>> $logFile
    }

}

function Install-Slack {

    msiexec /i $slackDownloadPath /qn /norestart

}

"`r`r*****************************" *>> $logFile
"*****EPM + Slack Updater*****" *>> $logFile
"**** " + (date -Format "MM/dd/yyy HH:mm:ss") + " ****" *>> $logFile
"*****************************" *>> $logFile

$latestSlackVersion = Get-LatestSlackVersion
$installedSlackVersion = Get-InstalledSlackVersion

"Current Slack Version: $installedSlackVersion" *>> $logFile
"Latest Available Slack Version: $latestSlackVersion" *>> $logFile

if([System.Version]$latestSlackVersion -gt [System.Version]$installedSlackVersion){
    
    "Newer version of Slack available, installing" *>> $logFile

    Retrieve-LatestSlackVersion
    Install-Slack

    "Version " + (Get-InstalledSlackVersion) + " is now installed." *>> $logFile
}
else {

"Current version of Slack is the latest, no upgrade necessary" *>> $logFile

}



