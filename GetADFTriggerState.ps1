param(
    [parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)] 
    [string]$DataFactoryName

)

<# These are for local tetsing

$ResourceGroupName = 'PPZHIDF'
$DataFactoryName = 'ppzhihubdf'

#>

$ADF_Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
#Write-Host $ADF_Triggers.Name

$activeTriggerNames = $ADF_Triggers | Where-Object { $_.runtimeState -eq "Started" }
Write-Host "Active triggers for current deploying environment:- " $activeTriggerNames.Name

$triggerlist =""

#Colleting all active triggers in a string
foreach($trigger in $activeTriggerNames)
{
    $triggerlist = $triggerlist + $trigger.name + " "
}

#populating devops variable for further use
Write-Host "##vso[task.setvariable variable=activeTriggerList;]$triggerlist"
