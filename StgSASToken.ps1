param(
    [parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)] 
    [string]$StgAccName

)

<# These are for local tetsing

$ResourceGroupName = 'DemoADFRG'
$StgAccName = 'stgadfarmtemplate'

#>

$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StgAccName).Context

$StartTime = Get-Date
$EndTime = $startTime.AddHours(1)

Write-Host "Start Time:- " $StartTime
Write-host "end Time:- " $EndTime

$SASToKen = New-AzStorageAccountSASToken -Context $ctx -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission "racwdlup" -Protocol "HttpsOnly" -StartTime $StartTime -ExpiryTime $EndTime

Write-Host $SASToKen

#populating devops variable for further use
Write-Host "##vso[task.setvariable variable=StorageSASToken;]$SASToKen"