
# ------------------------------------------------------------------------
# "./CostPoint Service Tool"
# Author: Michael Dennis M. Cresido, 06/06/2023
#
# This PowerShell script is created to stop, start and check CP services.
# There are 2 parameters files.
# a. params.JSON 
#    ACTION Parameter:
#    CHECK - Checks the current status of the service inside the server.
#    START - Starts the service inside the server. If the service is already started, no action will be executed.
#    STOP - Stops the service inside the server. If the service is already started, no action will be executed.
#  b. Service name is to be provided. What needs to be check, start or stop.
# ------------------------------------------------------------------------
# Version 1.0 - Script is completed


#Main function that calls service function and retrieves parameters from the
#CSV File and JSON file

function fnMain(){

    #Retrieving Parameters from CSV file and JSON file
    $mainFolderPath = $script:PSScriptRoot
    $mainServerList = (Import-Csv -path "$mainFolderPath\servers.csv")
    $mainJsonContent = (Get-Content "$mainFolderPath\params.json" | ConvertFrom-Json)
    $mainAction = $mainJsonContent.Parameters.Action
    $mainServices = $mainJsonContent.Parameters.ServiceName -split ","
    
    #Setting parameters for the log name and log path
    $logDate = Get-Date -Format "yyyyMMdd"
    $logFileName = "$logDate-costpoint-service-log"
    $logPath = "$mainFolderPath\Logs\$logFileName.log"

    #Creation of Log files
    if(Test-Path -Path $logPath){
        write-host "Log Path has already been created"
    }
    else{
        New-Item $logPath

    }


    #Looping the server list that was retrieved from CSV file
    foreach($mainServerName in $mainServerList){ 
        $mainServer = $mainServerName.Name
        $mainLog = fnService -servName $mainServices -servAction $mainAction -servServerName $mainServer

        #Log every action executed in the log file.
        Add-Content $logPath $mainLog


    }


}

#Service Function that reads which action will be taken.
#CHECK - Checks the current status of the service inside the server.
#START - Starts the service inside the server. If the service is already started, no action will be executed.
#STOP - Stops the service inside the server. If the service is already started, no action will be executed.

function fnService($servNames, $servAction, $servServerName){
    
    #Setting parameters
    $arrayLogs = @()
    $servDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    #Loop all service that inputted in the JSOn file
    foreach($servName in $servNames){
        try{
        
            #Retrieve the current status of the service
            $servStatus = (Get-Service -Name $servName -ComputerName $servServerName -ErrorAction Stop).Status 
            
            #SWitch statement that determines which action item will be executed.
            switch ($servAction){

                #CHECK - Checks the current status of the service inside the server.
                "CHECK"{
                    $servLogs = "[$servDate]: Service name: $servName CURRENT status is $servStatus. Server name: $servServerName"
                 }

                 #STOP - Stops the service inside the server. If the service is already started, no action will be executed.
                 "STOP"{
                    if($servStatus -eq "Stopped"){
                        $servLogs = "[$servDate]: Service name: $servName is already STOPPED in this server: $servServerName. No action item is required."

                        }
                    else{

                        
                        (Get-Service -Name $servName -ComputerName $servServerName -ErrorAction Stop).Stop()
                        Start-Sleep -Seconds 3
                        $newStatus = (Get-Service -Name $servName -ComputerName $servServerName -ErrorAction Stop).Status
                        $servLogs = "[$servDate]: Service name: $servName is STOPPED successfully in this server: $servServerName. Current STATUS: $newStatus"

                        }


                    }
                    #START - Starts the service inside the server. If the service is already started, no action will be executed.
                  "START"{
                    if($servStatus -eq "Stopped"){
                        (Get-Service -Name $servName -ComputerName $servServerName -ErrorAction Stop).Start()
                        Start-Sleep -Seconds 3
                        $newStatus = (Get-Service -Name $servName -ComputerName $servServerName -ErrorAction Stop).Status
                        $servLogs = "[$servDate]: Service name: $servName is STARTED successfully in this server: $servServerName. Current STATUS: $newStatus"


                    }
                    else{
                        $servLogs = "[$servDate]: Service name: $servName is already STARTED in this server: $servServerName. No action item is required."

                    }


                  }

            }
            $arrayLogs += $servLogs

        
        }

        catch{
            $errorMessage = $PSItem.Exception.Message
            $arrayLogs = "[$servDate]: There is an issue with this service: $servName. Please verify and check by logging into this server: $servServerName. Error Message: $errorMessage"

        }
    }
    return $arrayLogs
}


fnMain