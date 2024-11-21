param(
    [parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)]
    [AllowEmptyString()] 
    [string]$AlertName,

    [parameter(Mandatory = $true)] 
    [string]$TargetDatafactoryName
)

<# These are for local tetsing #>
<#
    $ResourceGroupName = 'DemoADFRG'
    $AlertName ='Alert_for_1_pp'
    $TargetDatafactoryName = 'adf-zhi-dev-southcentralus-001'
#>

#Install-Module Az.Monitor -AllowClobber -Scope CurrentUser -Confirm:$False -Force

$ErrorActionPreference = 'Stop'

$AlertResouces = 0
$AlertMetricName = ''
$AlertTimeAggregation = ''
$AlertOperatorProperty = ''
$AlertThreshold = 0
$FailureTypeDimensions = new-object System.Collections.Generic.List[System.String]

if([string]::IsNullOrWhiteSpace($AlertName))
{
    Write-Output "No Alert to update."
}
else
{
    try {

        $Alert = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroupName -Name $AlertName
    
        $ADFPipelineObject = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $TargetDatafactoryName

        foreach($criteria in $Alert.Criteria)
        {
            $AlertMetricName = $criteria.MetricName
            $AlertTimeAggregation = $criteria.TimeAggregation
            $AlertOperatorProperty = $criteria.OperatorProperty
            $AlertThreshold = $criteria.Threshold

            foreach($dim in $criteria.Dimensions)
            {
                if ($dim.Name -eq "Name")
                {
                    $AlertResouces = $dim.Values.Count

                    Write-Host "Alert mapped resources count:= " $AlertResouces
                }
                elseif($dim.Name -eq "FailureType")
                {
                    foreach($value in $dim.Values)
                    {
                        $FailureTypeDimensions.Add($value)
                    }
                }
            }
        }

        Write-Host "ADF pipelines count:= " $ADFPipelineObject.Count

        if($ADFPipelineObject.Count -ne $AlertResouces)
        {
            Write-Host "Alert resources and ADF pipeline count are different. Alert needs to be updated."

            $UpdatedCriteria = $null

            $UpdatedCriteria = New-AzMetricAlertRuleV2Criteria -MetricName $AlertMetricName -TimeAggregation $AlertTimeAggregation -Operator $AlertOperatorProperty -Threshold $AlertThreshold
            $UpdatedCriteria.Dimensions = new-object System.Collections.Generic.List[Microsoft.Azure.Management.Monitor.Models.MetricDimension]

            #Adding "name" Dimension
            $dimobjectName = new-object Microsoft.Azure.Management.Monitor.Models.MetricDimension    
            $dimobjectName.Name = "Name"
            $dimobjectName.OperatorProperty = "Include"

            $dimobjectName.Values = new-object System.Collections.Generic.List[System.String]

            foreach($pipeline in $ADFPipelineObject)
            {
                $dimobjectName.Values.Add($pipeline.Name)
            }   

            $UpdatedCriteria.Dimensions.Add($dimobjectName)

            #Adding "FailureType" Dimension
            $dimobjectFailureType = new-object Microsoft.Azure.Management.Monitor.Models.MetricDimension
            $dimobjectFailureType.Name = "FailureType"
            $dimobjectFailureType.OperatorProperty = "Include"

            $dimobjectFailureType.Values = new-object System.Collections.Generic.List[System.String]

            foreach($dimvalue in $FailureTypeDimensions)
            {
                $dimobjectFailureType.Values.Add($dimvalue)
            }

            $UpdatedCriteria.Dimensions.Add($dimobjectFailureType)

            #$UpdatedCriteria.Dimensions

            #Adding existing action groups
            $Actions = new-object 'System.Collections.Generic.List[Microsoft.Azure.Management.Monitor.Models.ActivityLogAlertActionGroup]'

            foreach($action in $Alert.Actions)
            {
                Write-host $action.ActionGroupId

                #need to use powershell 8.3.0
                $actgroup = New-AzActionGroup -ActionGroupId $action.ActionGroupId

                $Actions.Add($actgroup)
            }
        
            try {
            
                Add-AzMetricAlertRuleV2 -Name $Alert.Name -ResourceGroupName $Alert.ResourceGroup -WindowSize $Alert.WindowSize -Frequency $Alert.EvaluationFrequency -TargetResourceId $Alert.TargetResourceId -Condition $UpdatedCriteria -Severity $Alert.Severity -ActionGroup $Actions

                Write-Host $Alert.Name " has been updated Successfully."
            }
            catch { 
                Write-Host "An error occurred."
                Write-Host $_
            }
        }
        else
        {
            Write-Host "Alert resources and ADF pipeline count are same. Nothing to be update."
        }

    } catch { 
        Write-Host "An error occurred. Most likely $($AlertName) alert doesn't exists."
        Write-Host $_
    }
}




