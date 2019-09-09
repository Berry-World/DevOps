Param(
  [Parameter(Mandatory=$true)]
  [string]$branch,
  [Parameter(Mandatory=$true)]
  [string]$repo, 
  [Parameter(Mandatory=$true)]
  [string]$id,  
  [Parameter(Mandatory=$false)]
  [string]$warm_up_path = '' ,
  [Parameter(Mandatory=$true)]
  [string]$dockerPath,
  [Parameter(Mandatory=$true)]
  [string]$app,
  [Parameter(Mandatory=$false)]
  [Int]$replica = 1,
  [Parameter(Mandatory=$false)]
  [boolean]$dockerReplace = $false,
  [Parameter(Mandatory=$false)]
  [string]$dockerBase = 'mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim',
  [Parameter(Mandatory=$false)]
  [decimal]$dockerBaseKey = 0,  #2.1,
  [Parameter(Mandatory=$false)]
  [string]$dockerEntrypoint = ""
  
)
# example of .netcore images
#microsoft/dotnet:2.1-aspnetcore-runtime
#mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim

if ($dockerEntrypoint -eq "" )
{
  $dockerEntrypoint = $repo + ".Api.dll"
}

$branchName= $branch.Substring(11)

$aspnetEnvName= "Local"
$envTag= "local"
$namespace= ""
###$envDestination = "Local"


If ($branchName -like "master")
{$aspnetEnvName="Production"}

If ($branchName -like "deploy/dev*")
{
$aspnetEnvName="Development"
$namespace= $branchName  -replace "(deploy)\/(dev[a-z0-9]+)\/(.*)",'$2'
}

If ($branchName -like "aks-poc/dev*")
{
$aspnetEnvName="Development"
$namespace= $branchName  -replace "(aks-poc)\/(dev[a-z0-9]+)\/(.*)",'$2'
}

If ($branchName -like "deploy/tst*")
{
$aspnetEnvName="Test"
$namespace= $branchName  -replace "(deploy)\/(tst[a-z0-9]+)\/(.*)",'$2'
}

If ($branchName -like "aks-poc/tst*")
{
$aspnetEnvName="Test"
$namespace= $branchName  -replace "(aks-poc)\/(tst[a-z0-9]+)\/(.*)",'$2'
}
 
 
If ($branchName -like "deploy/feature*")
{$aspnetEnvName="Feature"}

If ($branchName -like "deploy/hotfix*")
{$aspnetEnvName="Hotfix"}

If ($branchName -like "deploy/poc*")
{$aspnetEnvName="Poc"}

$envTag= $aspnetEnvName.ToLower()


Write-Host  "##vso[task.setvariable variable=aspnetEnvName;isOutput=true;]$aspnetEnvName" 
Write-Host  "##vso[task.setvariable variable=envTag;isOutput=true;]$envTag" 



$namespaceUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/namespace.yaml'
$deployUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/deployment.yaml'
$serviceUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/service.yaml'
$dockerUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/Dockerfile'


$namespaceFile='PipelineScripts/k8s/namespace-v1.yaml'
$deploy='PipelineScripts/k8s/deployment-v1.yaml'
$service='PipelineScripts/k8s/service-v1.yaml'


Invoke-WebRequest $namespaceUri  -OutFile $namespaceFile
Invoke-WebRequest $deployUri  -OutFile $deploy
Invoke-WebRequest $serviceUri  -OutFile $service


$deploy='PipelineScripts/k8s/deployment-v1.yaml'
$service='PipelineScripts/k8s/service-v1.yaml'

" #### Copy yaml files"
Copy-Item $namespaceFile -Destination 'PipelineScripts/k8s/step0.yaml'
Copy-Item $deploy        -Destination 'PipelineScripts/k8s/step1.yaml'
Copy-Item $service       -Destination 'PipelineScripts/k8s/step2.yaml'
Copy-Item $service       -Destination 'PipelineScripts/k8s/step3.yaml'
Copy-Item $deploy        -Destination 'PipelineScripts/k8s/step4.yaml'
Copy-Item $service       -Destination 'PipelineScripts/k8s/step5.yaml'
Copy-Item $service       -Destination 'PipelineScripts/k8s/step6.yaml'
Copy-Item $service       -Destination 'PipelineScripts/k8s/step7.yaml'
Copy-Item $deploy -Destination 'PipelineScripts/k8s/step8.yaml'
####


" #### Copy Dockerfile"
Copy-Item $dockerUri -Destination 'PipelineScripts/k8s/Dockerfile'
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

$serviceType = @{
    1='ClusterIP'
    2='ClusterIP'
    3='ClusterIP'
    4='LoadBalancer' #Blue deployment would be testable
    5='LoadBalancer' #Blue deployment would be testable
    6='ClusterIP'
    7='ClusterIP'
    8='ClusterIP'
}

 ##$theAppName = $repo.Substring($repo.lastIndexOf('.')+1).ToLower()

 $image =  $repo.ToLower()

for ($i=0; $i -le 8; $i++)
{
    $hashTable = @{
        '#{the_app}#'      = $app
        '#{namespace}#'    = $namespace 
        '#{environment}#'  = $envTag.ToLower() 
        '#{slot}#'         = $slots[$i]
        '#{public-slot}#'  = $publicPodsSlots[$i]
        '#{image}#'        = $image
        '#{tag}#'          = $id + '-' + $envTag
        '#{buidId}#'       = $id
        '#{warm_up_path}#' = $warm_up_path
        '#{replica}#'      = $replica
        '#{serviceType}#'  = $serviceType[$i]
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
if ( $dockerReplace -eq $false)
{
"################### modifing the existing docker file  ##########################"
  $oldValue = 'ENV ASPNETCORE_ENVIRONMENT=Local'
  $newValue = 'ENV ASPNETCORE_ENVIRONMENT=' +  $aspnetEnvName

  (Get-Content $dockerPath) -replace $oldValue  , $newValue    | Set-Content $dockerPath
}
else
{
 " ####################### replace the docker file to $dockerPath #############" 
  Copy-Item 'PipelineScripts/k8s/Dockerfile' -Destination $dockerPath  -Force
  
  $hashTableDocker = @{
    '#{entrypoint}#'  = $dockerEntrypoint
    '#{environment}#' = $envTag.ToLower() 
    '#{dockerImage}#' = $slots[$i]
  }
  

  foreach ($key in $hashTableDocker.GetEnumerator()) {
    "Docker keyName  = " + $key.Name 
    "Docker keyValue = " + $key.Value
    "  "

    $oldValue = $key.Name
    $newValue = $key.Value

    (Get-Content $fullPathYaml) -replace $oldValue  , $newValue    | Set-Content $dockerPath
  } 
}

