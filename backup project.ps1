# Mustafa Mohamed Ali 2206019
# Eslam Mahmoud 2206044

# Get the current timestamp
$currentTimestamp = Get-Date

# Prompt the user to enter the source and destination paths
$sourcePath = Read-Host "Enter the source folder path"
$destinationPath = Read-Host "Enter the destination folder path"

# Path to store the timestamp of the last backup
$backupTimestampFile = "$destinationPath\backup_timestamp.txt"  

# Define the log file path for error logging
$logFilePath = "$destinationPath\backup_errors.log"
$summaryFilePath = "$destinationPath\backup_summary.txt" # Path to store backup summary

# Prompt the user to provide a list of files or folders to exclude
$excludeList = Read-Host "Enter a comma-separated list of files or folders to exclude (e.g., file1.txt, folder2)"

# Convert the comma-separated list into an array
$excludeArray = $excludeList.Split(',')

# Trim whitespace around the names in the array
$excludeArray = $excludeArray.Trim()

# Initialize variables to store summary results
$filesCopied = 0
$filesSkipped = 0
$filesFailed = 0
$validationMismatches = @()

# Check if the source path exists
try {
    if (Test-Path $sourcePath) {
        # Check if the destination path exists
        try {
            if (-not (Test-Path $destinationPath)) {
                # Create the destination folder if it doesn't exist
                New-Item -Path $destinationPath -ItemType Directory
            }
        } catch {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "$timestamp - ERROR: Failed to create the destination folder: $_"
            Write-Host "==================================================================================================="
            Write-Host $logMessage
            Add-Content -Path $logFilePath -Value $logMessage
            throw "Unable to create the destination folder."
        }

        # Get all items (files and folders) in the source directory recursively
        $items = Get-ChildItem -Path $sourcePath -Recurse
   
        # Loop through each item in the source folder
        foreach ($item in $items) {
            if ($excludeArray -notcontains $item.Name) {
                # Construct the destination path for the item
                $destinationItem = $item.FullName.Replace($sourcePath, $destinationPath)

                try {
                    if ($item.PSIsContainer) {
                        # Create the directory in the destination if it's a folder
                        if (-not (Test-Path $destinationItem)) {
                            New-Item -Path $destinationItem -ItemType Directory -Force
                        }
                    } else {
                        # If it's a file, check if it needs to be copied (by comparing hashes)
                        if (Test-Path $destinationItem) {
                            # Get hashes for both source and destination files
                            $sourceHash = Get-FileHash -Path $item.FullName
                            $destinationHash = Get-FileHash -Path $destinationItem

                            # Compare the hashes
                            if ($sourceHash.Hash -eq $destinationHash.Hash) {
                                # If hashes are the same, skip the file
                                $filesSkipped++
                                Write-Host "File $($item.Name) already exists in backup and is up to date."
                                Add-Content -Path $summaryFilePath -Value "$($currentTimestamp) - Skipped: $($item.Name) - Hashes are the same."
                            } else {
                                # If hashes are different, copy the file
                                Copy-Item -Path $item.FullName -Destination $destinationItem -Force
                                $filesCopied++
                                Write-Host "File $($item.Name) copied to backup."
                                Add-Content -Path $summaryFilePath -Value "$($currentTimestamp) - Mismatch: $($item.Name) - Hashes differ, file copied."
                                $validationMismatches += $item.Name
                            }
                        } else {
                            # If the file doesn't exist in the backup, copy it
                            Copy-Item -Path $item.FullName -Destination $destinationItem -Force
                            $filesCopied++
                            Write-Host "File $($item.Name) copied to backup."
                            Add-Content -Path $summaryFilePath -Value "$($currentTimestamp) - New: $($item.Name) - File was not found in backup."
                        }
                    }
                } catch {
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $logMessage = "$timestamp - ERROR: Failed to copy item $($item.FullName) to destination: $_"
                    Write-Host $logMessage
                    Add-Content -Path $logFilePath -Value $logMessage
                    Write-Host "Skipping item: $($item.FullName)"
                    $filesFailed++
                    Add-Content -Path $summaryFilePath -Value "$($currentTimestamp) - ERROR: $($item.Name) - $_"
                }
            }
        }

        # Files to exclude from deletion
        $excludeFiles = @("backup_timestamp.txt", "backup_errors.log", "backup_summary.txt")

        # Loop through items in the backup folder to identify items not in the source
        $backupItems = Get-ChildItem -Path $destinationPath -Recurse
        foreach ($backupItem in $backupItems) {
            # Construct the corresponding source path for the backup item
            $sourceItem = $backupItem.FullName.Replace($destinationPath, $sourcePath)

            # Check if the item exists in the source or is in the exclusion list
            if (-not (Test-Path $sourceItem) -and ($backupItem.Name -notin $excludeFiles)) {
                try {
                    # Attempt to delete the item from the backup
                    Remove-Item -Path $backupItem.FullName -Recurse -Force
                    Write-Host "Deleted: $($backupItem.FullName)"
                } catch {
                    # Log or display an error if deletion fails
                    Write-Host "Error: Failed to delete $($backupItem.FullName). Exception: $_"
                }
            }
        }

        # Update the backup timestamp
        try {
            Set-Content -Path $backupTimestampFile -Value $currentTimestamp.ToString('yyyy-MM-dd HH:mm:ss')
        } catch {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "$timestamp - ERROR: Failed to update backup timestamp: $_"
            Write-Host $logMessage
            Add-Content -Path $logFilePath -Value $logMessage
            Write-Host "Unable to update the backup timestamp."
        }

        # Summary of the backup process
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $summaryMessage = "$timestamp - Backup completed with the following results:`n"
        $summaryMessage += "Files copied: $filesCopied`n"
        $summaryMessage += "Files skipped (hashes same): $filesSkipped`n"
        $summaryMessage += "Files failed: $filesFailed`n"
        $summaryMessage += "==================================================================================================="

        if ($validationMismatches.Count -gt 0) {
            $summaryMessage += "`nFiles with mismatches (copied due to different hashes):`n"
            $validationMismatches | ForEach-Object { $summaryMessage += "$_`n" }
        }

        Write-Host "==================================================================================================="
        # Display the final summary to the user
        Write-Host $summaryMessage
        # Write the final summary to the summary file
        Add-Content -Path $summaryFilePath -Value $summaryMessage

    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp - ERROR: The source folder path does not exist. Please check the path and try again."
        Write-Host $logMessage
        Add-Content -Path $logFilePath -Value $logMessage
        Write-Host "The source folder path does not exist. Please check the path and try again."
    }

    # Ask the user if they want to automate the backup process
    $automationChoice = Read-Host "Do you want to schedule automated backups? (yes/no)"

    if ($automationChoice -eq "yes") {
        # Ask the user for the schedule interval
        $scheduleInterval = Read-Host "Enter the schedule interval (e.g., daily, weekly)"

        # Create a new task trigger based on the interval
        if ($scheduleInterval -eq "daily") {
            $trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"  # Set your preferred time
        } elseif ($scheduleInterval -eq "weekly") {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "3:00AM"
        } 
        # elseif ($scheduleInterval -eq "monthly") {
        #     # For monthly, specify the day of the month
        #     $trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date -Day 1).AddMonths(1).AddHours(3))
        # } elseif ($scheduleInterval -eq "yearly") {
        #     # For yearly, specify the month and day
        #     $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date -Year (Get-Date).Year -Month 1 -Day 1 -Hour 3 -Minute 0)
        #     Write-Host "Note: Yearly tasks are scheduled for January 1st at 3:00 AM."
        # } 
        else {
            Write-Host "Invalid interval specified. Defaulting to daily."
            $trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
        }

        # Define the action to run the PowerShell script
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "./backup project.ps1"

        # Register the scheduled task
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Automated Backup Task" -Description "Scheduled backup task" 

        Write-Host "Automated backup has been scheduled."
    } else {
        Write-Host "No automation scheduled. Run the script manually to back up your files."
    }

} catch {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - ERROR: An error occurred during the backup process: $_"
    Write-Host "==================================================================================================="
    Write-Host $logMessage
    Add-Content -Path $logFilePath -Value $logMessage
    Write-Host "Backup failed due to an error. Please check the error log for details."
}