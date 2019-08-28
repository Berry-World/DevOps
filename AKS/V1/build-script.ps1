Param(
  [string]$sourceBranch
  [string]$repo  #$(Build.Repository.Name)
  [string]$buildId
  [string]$warm_up_path
  [string]$dockerPath
)


$branchName= $sourceBranch.Substring(11)

$aspnetEnvName= "Local"
$envTag= "local"
###$envDestination = "Local"

If ($branchName -like "master")
{$aspnetEnvName="Production"}

If ($branchName -like "deploy/dev*")
{$aspnetEnvName="Development"}

If ($branchName -like "deploy/tst*")
{$aspnetEnvName="Test"}
 
If ($branchName -like "deploy/feature*")
{$aspnetEnvName="Feature"}

If ($branchName -like "deploy/hotfix*")
{$aspnetEnvName="Hotfix"}

If ($branchName -like "deploy/poc*")
{$aspnetEnvName="Poc"}

$envTag= $aspnetEnvName.ToLower()


Write-Host  "##vso[task.setvariable variable=aspnetEnvName;isOutput=true;]$aspnetEnvName" 
Write-Host  "##vso[task.setvariable variable=envTag;isOutput=true;]$envTag" 






$deploy='PipelineScripts/k8s/deployment.yaml'
$service='PipelineScripts/k8s/service.yaml'

" #### Copy yaml files"
Copy-Item $deploy -Destination 'PipelineScripts/k8s/step1.yaml'
Copy-Item $service -Destination 'PipelineScripts/k8s/step2.yaml'
Copy-Item $service -Destination 'PipelineScripts/k8s/step3.yaml'
Copy-Item $deploy -Destination 'PipelineScripts/k8s/step4.yaml'
Copy-Item $service -Destination 'PipelineScripts/k8s/step5.yaml'
Copy-Item $service -Destination 'PipelineScripts/k8s/step6.yaml'
Copy-Item $service -Destination 'PipelineScripts/k8s/step7.yaml'
Copy-Item $deploy -Destination 'PipelineScripts/k8s/step8.yaml'
####


"###Changing the image tag & service name in the yaml file###  " + $envTag 


$BlueGreenDeploymentSlots = @{
    1='green'
    2='green'
    3='public'
    4='blue'
    5='blue'
    6='public'
    7='green'
    8='green'
}


 $theAppName = $repo.Substring($repo.lastIndexOf('.')+1).ToLower()

 $image =  $repo.ToLower()

for ($i=1; $i -le 8; $i++)
{
    $hashTable = @{
        '#{the_app}#'            = $theAppName
        '#{environment}#'    = $envTag.ToLower() 
        '#{slot}#'                   = $BlueGreenDeploymentSlots[$i]
        '#{image}#'               = $image
        '#{tag}#'                    = $buildId + '-' + $envTag
        '#{warm_up_path}#'  = $warm_up_path
    }


    $fullPathYaml = 'PipelineScripts/k8s/step' + $i+ '.yaml'

    foreach ($key in $hashTable.GetEnumerator()) {
        ### "step$($i)  replace $($key.Name) => $($key.Value)  "+ $BlueGreenDeploymentSlots[$i] 
        $i
        "keyName  = " + $key.Name 
        "keyValue = " + $key.Value
        $BlueGreenDeploymentSlots[$i]
        "  "

        $oldValue = $key.Name
        $newValue = $key.Value

        (Get-Content $fullPathYaml) -replace $oldValue  , $newValue    | Set-Content $fullPathYaml
    } 
}


"###changing the environment variable in docker file### " + $aspnetEnvName 
#$fullPathYaml = 'src/BerryWorld.OData.CDS/Dockerfile'


$oldValue = 'ENV ASPNETCORE_ENVIRONMENT=Local'
$newValue = 'ENV ASPNETCORE_ENVIRONMENT=' +  $aspnetEnvName

(Get-Content $dockerPath) -replace $oldValue  , $newValue    | Set-Content $dockerPath
