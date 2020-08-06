

<# 
    .SYNOPSIS
    Work with corrupted files indentified by the Dedup scrubbing Job

    .DESCRIPTION
    This script will get the paths of all files identified as corrupted by the Dedup Scrubbing Job. You can either export the result to a txt file or delete the files.

    Script to filter Dedup Events on 12800 Events and get back all paths no matter what the path-string is or if it contains special characters like $
    30 July 2020: Josef Holzer 
    04 August 2020 small additions made by Joel Palheira

    .PARAMETER LogPath
    Path to export the Result - Note if a file already exists witht the specified name it will be delete
    If we are running in Delete Mode it will log the activity and any error it finds to a CSV file

    .PARAMETER DoDelete
    Default is False. If you want to delete the files this needs to be set to True

    .PARAMETER ByPassNotFound
    Default is False. This will not log an error to the Log File when in Delete Mode and the file is not found. Usefull on second pass to delete some remaining files that were not deleted due to some error.

    
#>


  [CmdletBinding()]
  Param(
        [Bool]$DoDelete = $false, 
        [String]$LogPath = "$env:SystemDrive\MS_DATA\",
        [Bool]$ByPassNotFound = $false)


$DedupFolderPathsToBeDeleted= @() # Define an empty array to carry each relevant event

function GetDedupPathToBeDeleted{  #function name
    param(
        $EventId # could be 12800 e.g.
    )
       
    $date = GetLastScrubbRun
    $Evts= Get-WinEvent -LogName Microsoft-Windows-Deduplication/Scrubbing -FilterXPath "*[System[TimeCreated[@SystemTime>'$date']][EventID=$eventid]]" # Filter System EventLog on EventID´s = 12800 - -FilterPath is the fastest way to do this

    foreach($Evt in $Evts){                               # Walk through each Event
        $Evt.Message -match '"(?<Path>.:.*)"' | Out-Null  # Use regular expression with Named Captured Groups to filter out the string between the quotation marks "C:\Xyz\Thumbnail.db"
        $Path= @($Matches.Path)                           # Directly get the Path without Quotation Marks; 
                                                          # Using Array subexpression operator @( ) to make sure the path is not interpreted as an array of chars, but always as a element of a string array.
                                                          # even if only 1 path is delivered the string e.g. E:\Folder\xyz\Thumbs.db is interpreted as 1 element of a string array - Important stuff
        $DedupFolderPathsToBeDeleted+= $Path              # Add the current Path to the Array
    }
    Return $DedupFolderPathsToBeDeleted                   # Return the Array back to global scope
}

function GetLastScrubbRun{

    #This is an helper funtion to get the date of the last time the Scrubb Dedup Job as run and that it detected any error
    #We should only check the last run that contains the up to date information

    $evt = Get-WinEvent -LogName Microsoft-Windows-Deduplication/Scrubbing -FilterXPath Event[System[EventID=12817]] -MaxEvents 1
    $date = $evt.TimeCreated.ToUniversalTime().ToString('s')
    return $date
}

function ExportData{
    param($data)
    
    if (!(Test-Path $LogPath))
    {
        New-Item -Path $LogPath -ItemType Directory
    }
    
    if ($DoDelete)
    {
        $filepath = $LogPath + "DedupDeleteFiles" + (Get-Date -Format 'yyMMdd-HHmmss') + ".csv"
        $data | Export-Csv -Path $filepath -NoTypeInformation
        Write-Host "Log file created on " $filepath -ForegroundColor Green
    }
    else 
    {
        $filepath = $LogPath + "DedupCorruptedFiles" + (Get-Date -Format 'yyMMdd-HHmmss') + ".txt"
        $data | Out-File -FilePath $filepath
        Write-Host "Log file created on " $filepath -ForegroundColor Green

    }
}


function LogError{
    
    param($type,$filepath,$cmdlet,$error)

    $Geterror = New-Object -TypeName PsObject
    $GetError | Add-Member -MemberType NoteProperty -Name "Type" -Value $type
    $GetError | Add-Member -MemberType NoteProperty -Name "FilePath" -Value $filepath
    $GetError | Add-Member -MemberType NoteProperty -Name "Cmdlet" -Value $cmdlet
    $Geterror | Add-Member -MemberType NoteProperty -Name "Error" -Value $error  
    Return $Geterror

}


function DeleteFiles{
    param($files)

    $Errors = @()
    foreach($file in $files)
    {
        try{
            Get-ChildItem -Path $file -Force -ErrorAction Stop | Remove-Item -Force -ErrorAction Stop            
            $Errors += LogError -type "Info" -filepath $file -cmdlet "Remove-Item" -error "Success"

        }
        Catch{

            If(!($_.CategoryInfo.Category -eq "ObjectNotFound" -and $ByPassNotFound -eq $true))
            {
                $Errors += LogError -type "Error" -filepath $_.CategoryInfo.TargetName -cmdlet $_.CategoryInfo.Activity -error $_
            }
        }
        
    }
    return $errors

}


$Paths= GetDedupPathToBeDeleted -EventId 12800
Write-Host "Found" $Paths.Count "corrupted files." -ForegroundColor Green

if ($DoDelete -eq $true)
{
    $title    = "Data Loss May Occur"
    $question = "You're running this script with the option to delete the files that the last Dedup Scrubbing Job detected as corrupted. This will permantly delete those files identified, are you sure you want to continue?"
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    
    if ($decision -eq 0) {
        $Results = Deletefiles $Paths
        if ($results -eq $null)
        {
            $results = LogError -type "Info" -filepath "No Files found to be deleted" -cmdlet "" -error "Success"

        }
     
     $Errorscount = $Results | Where Type -eq "Error" | Measure-Object

     If($Errorscount.Count -gt 0)
     {
        Write-Host "Found" $Errorscount.Count "errors during the execution, please check the log file for more information." -ForegroundColor Red
     }
     
     
     ExportData -data $Results
    }
     else {
        Write-Host "Execution was canceled by the user"
    }
}

Else {ExportData -data $Paths}

