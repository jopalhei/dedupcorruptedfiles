# Work with Windows data Deduplication Corrupted Files detected by Scrubbing Job
This script will help to identify and if needed to delete corrupted files detected by the Windows Dedup Scrubbing Jobs

SYNOPSIS
    Work with corrupted files indentified by the Dedup scrubbing Job
    
    
SYNTAX
    G:\Work\Scripts\DedupCorruptedFiles.ps1 [[-DoDelete] <Boolean>] [[-LogPath] <String>] [[-ByPassNotFound] <Boolean>] [<CommonParameters>]
    
    
DESCRIPTION
    This script will get the paths of all files identified as corrupted by the Dedup Scrubbing Job. You can either export the result to a txt file or 
    delete the files.
    
    Script to filter Dedup Events on 12800 Events and get back all paths no matter what the path-string is or if it contains special characters like $
    30 July 2020: Josef Holzer 
    04 August 2020 small additions made by Joel Palheira
    

PARAMETERS
    -DoDelete <Boolean>
        Default is False. If you want to delete the files this needs to be set to True
        
        Required?                    false
        Position?                    1
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -LogPath <String>
        Path to export the Result - Note if a file already exists witht the specified name it will be delete
        If we are running in Delete Mode it will log the activity and any error it finds to a CSV file
        
        Required?                    false
        Position?                    2
        Default value                "$env:SystemDrive\MS_DATA\"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ByPassNotFound <Boolean>
        Default is False. This will not log an error to the Log File when in Delete Mode and the file is not found. Usefull on second pass to delete 
        some remaining files that were not deleted due to some error.
        
        Required?                    false
        Position?                    3
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
