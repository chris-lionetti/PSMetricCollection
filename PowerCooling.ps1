$taskname       = 'PowerCooling'
$CurrentFilePath= $MyInvocation.MyCommand.path
$TaskPath       = 'PowerShell'
$TaskPathL      = '\PowerShell'
$WorkDir        = split-path -Parent ($MyInvocation.MyCommand.Path)
$ExecutePWSH    = 'C:\Program Files\PowerShell\7\PWSH.exe'
$DateString     = get-date -format 'yyyy-dd-MM hh-mm-ss'
$ListOfServers  = @( '192.168.100.38','192.168.100.33')

# Create The Schedualed Task 
    $ScheduleObject = New-Object -ComObject schedule.Service
    $ScheduleObject.Connect()
    try     {   $ScheduleObject.GetFolder($TaskPathL) 
                $RootFolderSO = $ScheduleObject.GetFolder("\")
                $RootFolderSO.CreateFolder($TaskPath)
            }
    catch   {   write-host "The TaskPath already exists."
            }
    $taskTrigger    = New-ScheduledTaskTrigger -once -at (Get-Date) -RepetitionDuration (New-Timespan -Days 12) -RepetitionInterval (New-TimeSpan -Minutes 2 )
    $taskAction     = New-ScheduledTaskAction -Execute $ExecutePWSH -argument '-NoProfile -ExecutionPolicy Bypass -File C:\Users\chris\Desktop\PowerShell\CollectionAgent\MasterCollectionAgent\PowerCooling.ps1' -WorkingDirectory $WorkDir
    $taskPrinciple  = New-ScheduledTaskPrincipal -userID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $taskSetting    = New-ScheduledTaskSettingsSet -StartWhenAvailable
    $task           = New-ScheduledTask -Action $taskAction -Principal $TaskPrinciple -Trigger $taskTrigger -Settings $taskSetting 
    $exists         = ( @(Get-ScheduledTask $taskName -ErrorAction SilentlyContinue).Count -ne 0 )
    if(!$exists)    {   Write-host "Creating new scheduled task $taskName ..." 
                        Register-ScheduledTask $taskName -InputObject $task -TaskPath $TaskPathL
                    } 
    else            {   Write-host "Scheduled task $taskName already exists, updating it..."
                        Set-ScheduledTask -TaskName $taskName -Action $taskAction -Principal $TaskPrinciple -Trigger $taskTrigger -Settings $taskSetting -TaskPath $TaskpathL       
                    }

################################################################################################################################################################################
Import-Module "$WorkDir\SNIASwordfish\SNIASwordfish.psd1" -force
foreach ( $Redfishtarget in $ListOfServers)
    {   Write-host "Attempting to Connect to $Redfishtarget"
        $ReturnData = Connect-RedfishTarget -Target $RedfishTarget
        # Just in Case we should try and log in to get the token
        $ReturnData = Get-RedfishSessionToken -username 'RedfishMonitor' -password 'Passw0rd' -erroraction SilentlyContinue
        # Get Chassis Fundamentals
        $ReturnData = Get-RedfishChassis
        $MyChassisType = $ReturnData.Model
        $MyChassisSerial = $ReturnData.SerialNumber
        ######################################
        # Get the Temps
        ######################################
        $ReturnData = (Get-RedfishChassisThermal).Temperatures
        foreach ( $Temp in $ReturnData)
            {   if ( $Temp.PhysicalContext -like 'Intake' -and $ReturnData )
                    {   if ( -not (Test-Path "$WorkDir\Temp.csv" -PathType leaf) )
                            {   write-warning "No Data Files Found. Adding new empty files now."
                                New-Item -Path $WorkDir -Name "Temp.csv" -ItemType 'file' -Value "Date, Model, SerialNumber, Intake`n"
                            }
                        $WorkFile = $WorkDir + '\Temp.csv'
                        Add-Content -path $WorkFile -value "$DateString, $MyChassisType, $MyChassisSerial, $($Temp.ReadingCelsius)"
                    }
            }
        #######################################
        # Get the Power
        #######################################
        $ReturnData = Get-RedfishChassisPower
        if ( -not (Test-Path "$WorkDir\Power.csv" -PathType leaf) -and $ReturnData )
            {   New-Item -Path $WorkDir -Name "Power.csv" -ItemType 'file' -Value "Date, Model, SerialNumber, PowerCapacity(Watts)`n"
            }
        if ( $ReturnData )
            {   $WorkFile = $WorkDir + '\Power.csv'
                Add-Content -path $WorkFile -Value "$DateString, $MyChassisType, $MyChassisSerial, $($ReturnData.PowerConsumedWatts)"
            }
    }
return