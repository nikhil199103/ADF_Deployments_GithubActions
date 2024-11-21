param(
    [parameter(Mandatory = $true)]
    [AllowEmptyString()] 
    [string]$activeTriggerList="",

    [parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)] 
    [string]$DataFactoryName

)

<# These are for local tetsing

$activeTriggerList = 'demo1_EveryHour demo2_6pmCST demo3_0800UTC' #demo1_EveryHour demo2_6pmCST demo3_0800UTC
$ResourceGroupName = 'PPZHIDF'
$DataFactoryName = 'ppzhihubdf'

#>

#Write-Host "parameter values for active ones:- " $activeTriggerList

$ErrorActionPreference = 'Stop'

if([string]::IsNullOrWhiteSpace($activeTriggerList))
{
    Write-Host "No Active triggers avilable to start."
}
else {
    $activeTriggerList = $activeTriggerList.TrimEnd()
    $activeTriggerList = $activeTriggerList.Replace(" ", ";")
    Write-Host $activeTriggerList

    $stopTriggerList = $activeTriggerList.Split(";")

    foreach($triggerName in $stopTriggerList)
    {
        Write-Host "Checking trigger:- " $triggerName

        try {
        
            $triggerObject = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $triggerName

            if($triggerObject.Properties.Pipelines.Count -eq 0)
            {
                 Write-Host $triggerName " trigger doesn't have any pipeline refferences. Unable to start"
            }
            else
            {
                Write-Host "Trigger found and starting"

                Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -TriggerName $triggerName -Force
            }
        }
        catch { 
            Write-Host $triggerName "not found. Unable to start"
        }
    }

    #putting some delay to have correct state
    Start-Sleep -Seconds 15

    #Checking whether de-active trigger started or not
    $ADF_Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
    $activeNowTriggerNames = $ADF_Triggers | Where-Object { $_.runtimeState -eq "Started" }
    Write-Host "Enabled triggers after stopping:- " $activeNowTriggerNames.Name
}