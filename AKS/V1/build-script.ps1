Param(
  [Parameter(Mandatory=$true)]
  [string]$branch, #$(Build.SourceBranch)
  [Parameter(Mandatory=$true)]
  [string]$repo,  #$(Build.Repository.Name)
  [Parameter(Mandatory=$true)]
  [string]$id,   #$(Build.BuildId)
  [Parameter(Mandatory=$false)]
  [string]$warm_up_path = '' ,
  [Parameter(Mandatory=$true)]
  [string]$dockerPath,
  [Parameter(Mandatory=$true)]
  [string]$app,
  [Parameter(Mandatory=$false)]
  [string]$replica = 2
)


$branchName= $branch.Substring(11)

$aspnetEnvName= "Local"
$envTag= "local"
###$envDestination = "Local"

If ($branchName -like "master")
{$aspnetEnvName="Production"}

If ($branchName -like "deploy/dev*")
{$aspnetEnvName="Development"}

If ($branchName -like "aks-poc/dev*")
{$aspnetEnvName="Development"}

If ($branchName -like "deploy/tst*")
{$aspnetEnvName="Test"}

If ($branchName -like "aks-poc/tst*")
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



$deployUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/deployment.yaml'
$serviceUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/service.yaml'


$deploy='PipelineScripts/k8s/deployment-v1.yaml'
$service='PipelineScripts/k8s/service-v1.yaml'


Invoke-WebRequest $deployUri  -OutFile $deploy
Invoke-WebRequest $serviceUri  -OutFile $service


$deploy='PipelineScripts/k8s/deployment-v1.yaml'
$service='PipelineScripts/k8s/service-v1.yaml'

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

#BlueGreenDeployment
$publicPodsSlots = @{
    1='green'
    2='green'
    3='green' #(public=>green)
    4='blue'
    5='blue'
    6='blue' #(public=>green)
    7='green'
    8='green'
}

$slots = @{
    1='green'
    2='green'
    3='public'
    4='blue'
    5='blue'
    6='public'
    7='green'
    8='green'
}


 ##$theAppName = $repo.Substring($repo.lastIndexOf('.')+1).ToLower()

 $image =  $repo.ToLower()

for ($i=1; $i -le 8; $i++)
{
    $hashTable = @{
        '#{the_app}#'      = $app
        '#{environment}#'  = $envTag.ToLower() 
        '#{slot}#'         = $slots[$i]
        '#{public-slot}#'  = $publicPodsSlots[$i]
        '#{image}#'        = $image
        '#{tag}#'          = $id + '-' + $envTag
        '#{warm_up_path}#' = $warm_up_path
    }


    $fullPathYaml = 'PipelineScripts/k8s/step' + $i+ '.yaml'

    foreach ($key in $hashTable.GetEnumerator()) {
        ### "step$($i)  replace $($key.Name) => $($key.Value)  "+ $BlueGreenDeploymentSlots[$i] 
        $i
        "keyName  = " + $key.Name 
        "keyValue = " + $key.Value
        "deployment slot : " + $slots[$i]
        "public service point to: " + $publicPodsSlots[$i]
        "  "

        $oldValue = $key.Name
        $newValue = $key.Value

        (Get-Content $fullPathYaml) -replace $oldValue  , $newValue    | Set-Content $fullPathYaml
    } 
}


"###changing the environment variable in docker file### " + $aspnetEnvName 

$oldValue = 'ENV ASPNETCORE_ENVIRONMENT=Local'
$newValue = 'ENV ASPNETCORE_ENVIRONMENT=' +  $aspnetEnvName

(Get-Content $dockerPath) -replace $oldValue  , $newValue    | Set-Content $dockerPath

