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
  [Int]$minReplicas = 1,
  [Parameter(Mandatory=$false)]
  [Int]$maxReplicas = 10,
  [Parameter(Mandatory=$false)]
  [boolean]$dockerReplace = $false,
  [Parameter(Mandatory=$false)]
  [string]$dockerBase = 'mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim',
  [Parameter(Mandatory=$false)]
  [string]$dockerEntrypoint = "",
  [Parameter(Mandatory=$false)]
  [boolean]$showModifiedFiles = $true,
  [Parameter(Mandatory=$true)]
  [string]$operationDirectory,
  [Parameter(Mandatory=$false)]
  [string]$publicServiceType = "ClusterIP",
  [Parameter(Mandatory=$false)]
  [boolean]$addSSL = $false,
  [Parameter(Mandatory=$false)]
  [string]$memoryLimits = "4096M",
  [Parameter(Mandatory=$false)]
  [string]$memoryRequest = "100M",
  [Parameter(Mandatory=$false)]
  [string]$cpuLimits = "1",
  [Parameter(Mandatory=$false)]
  [string]$cpuRequest = ".001",
  [Parameter(Mandatory=$false)]
  [boolean]$routeChanging  = $false,
  [Parameter(Mandatory=$false)]
  [string]$routeFilePath= "./", 
  [Parameter(Mandatory=$false)]
  [string]$routeFilefilter= "*.cs", 
  [Parameter(Mandatory=$false)]
  [hashtable]$routeReplacingHashTable =  @{ '\[Route\(\"api' = '[Route("tst1/finance/api'  },
  [Parameter(Mandatory=$false)]
  [string]$osType= "linux" , 
  [Parameter(Mandatory=$false)]
  [hashtable]$branchNameMap2EnvName=  @{ 'master'='Production' ;  'deploy/dev1/*'='Development' ; 'deploy/tst1/*'='Test' ;  'deploy/tst2/*'='Test2'  ;  'deploy/tst3/*'='Test3' ; 'deploy/tst4/*'='Test4'; 'deploy/tst5/*'='Test5'   }
)
# example of .netcore images
#microsoft/dotnet:2.1-aspnetcore-runtime
#mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim

"#########################  PS Script begin with artifact tagging based on branch name. #########################"

if ( $operationDirectory -eq '')
{
   $operationDirectory = 'PipelineScripts/k8s/'
}
 "####################### make sure the path to  new Dockerfile does exist ######"
 if ($operationDirectory.lastIndexOf('\') -ne -1)
 {
    New-Item -ItemType Directory -Path $operationDirectory -Force
 }

 if ($operationDirectory.lastIndexOf('/') -ne -1)
 {
    New-Item -ItemType Directory -Path $operationDirectory -Force
 }
 "####################### [END OF :] make sure the path to  new Dockerfile does exist ######"





if ($dockerEntrypoint -eq "" )
{
  $dockerEntrypoint = $repo + ".Api.dll"
}

$branchName= $branch.Substring(11)
$addTag = "##vso[build.addbuildtag]"

$aspnetEnvName= "Local"
$envTag= "local"
$namespace= ""
###$envDestination = "Local"


If ($branchName -like "master")
{
  $aspnetEnvName="Production"
  #Write-Host $addTag"prod"
  $namespace="prd1"
}


If ($branchName -like "master-webapps")
{
  $aspnetEnvName="Production"
  #Write-Host $addTag"prod"
  $namespace="prd1"
}



If ($branchName -like "deploy/dev/*")
{
  $aspnetEnvName="Development"
  $namespace= $branchName  -replace "(deploy)\/(dev)\/(.*)",'$2'
  #Write-Host $addTag"dev"
}elseif ($branchName -like "deploy/dev*/*")
{
  $aspnetEnvName="Development"
  $namespace= $branchName  -replace "(deploy)\/(dev[a-z0-9]+)\/(.*)",'$2'
  #Write-Host $addTag"dev"
  
  if ($namespace -eq "dev2")
  {
    $aspnetEnvName="Development2"
  }elseif ($namespace -eq "dev3")
  {
    $aspnetEnvName="Development3"
  }elseif ($namespace -eq "dev4")
  {
    $aspnetEnvName="Development4"
  }elseif ($namespace -eq "dev5")
  {
    $aspnetEnvName="Development5"
  }
}

If ($branchName -like "aks-poc/dev*")
{
  $aspnetEnvName="Development"
  $namespace= $branchName  -replace "(aks-poc)\/(dev)\/(.*)",'$2'
  #Write-Host $addTag"poc-dev"
}elseIf ($branchName -like "aks-poc/dev*/*")
{
  $aspnetEnvName="Development"
  $namespace= $branchName  -replace "(aks-poc)\/(dev[a-z0-9]+)\/(.*)",'$2'
  #Write-Host $addTag"poc-dev"
}

If ($branchName -like "deploy/tst/*")
{
  $aspnetEnvName="Test"
  $namespace= $branchName  -replace "(deploy)\/(tst)\/(.*)",'$2'
  #Write-Host $addTag"tst"
}elseIf ($branchName -like "deploy/tst*/*")
{
  $aspnetEnvName="Test"
  $namespace= $branchName  -replace "(deploy)\/(tst[a-z0-9]+)\/(.*)",'$2'
  #Write-Host $addTag"tst"
  #Write-Host $addTag+$namespace
  
  if ($namespace -eq "tst2")
  {
    $aspnetEnvName="Test2"
  }elseif ($namespace -eq "tst3")
  {
    $aspnetEnvName="Test3"
  }elseif ($namespace -eq "tst4")
  {
    $aspnetEnvName="Test4"
  }elseif ($namespace -eq "tst5")
  {
    $aspnetEnvName="Test5"
  }
}

If ($branchName -like "aks-poc/tst/*")
{
  $aspnetEnvName="Test"
  $namespace= $branchName  -replace "(aks-poc)\/(tst\/(.*)",'$2'
  #Write-Host $addTag"poc-tst"
}elseIf ($branchName -like "aks-poc/tst*/*")
{
  $aspnetEnvName="Test"
  $namespace= $branchName  -replace "(aks-poc)\/(tst[a-z0-9]+)\/(.*)",'$2'
  #Write-Host $addTag"poc-tst"
  #Write-Host $addTag+$namespace
}
 
 
If ($branchName -like "deploy/feature*")
{
  $aspnetEnvName="Feature"
  #Write-Host $addTag"feature"
}

If ($branchName -like "deploy/hotfix*")
{
  $aspnetEnvName="Hotfix"
  #Write-Host $addTag"hotfix"
}

If ($branchName -like "deploy/poc*")
{
  $aspnetEnvName="Poc"
  #Write-Host $addTag"poc"
}

"#########################  END OF the tagging based on branch name. #########################"

"#########################  Tag the build based on the last git tag. #########################"


#$tag = git tag


# support multiple tags , as they would come as array
#if (  ($tag -is [system.array] ) -and ( $tag.Count -gt 0)) 
#{
#    # we are only interested on the last tag.
#    $tag = $tag[$tag.Count -1]
#}
#
## the previous if is suppose to convert array onto string
## however maybe you have only one single tag e.g.the first ever tag for your code
#if ( $tag -is [system.string])
#{
#    if ( $tag -like "deploy:*")
#    {
#        #$environment = $tag.ToLower().Replace("deploy:", "")
#        #$addTagCode = "##vso[build.addbuildtag]" + $environment
#        #Write-Host $addTagCode
#    } 
#}
 

"#########################  End of the git tag. #########################"




$app = $app.ToLower()
$envTag= $aspnetEnvName.ToLower()


Write-Host  "##vso[task.setvariable variable=aspnetEnvName;isOutput=true;]$aspnetEnvName" 
Write-Host  "##vso[task.setvariable variable=envTag;isOutput=true;]$envTag" 



$namespaceUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/namespace.yaml?'+ (new-guid).ToString()
$deployUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/deployment.yaml?'+ (new-guid).ToString()
$serviceUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/service.yaml?'+ (new-guid).ToString()
$dockerUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/Dockerfile?' + (new-guid).ToString()
$routefixerUri = 'https://raw.githubusercontent.com/Berry-World/DevOps/master/AKS/V1/route-fixer.ps1?' + (new-guid).ToString()


$namespaceFile   = $operationDirectory + 'template-namespace-v1.yaml'
$deploy          = $operationDirectory + 'template-deployment-v1.yaml'
$service         = $operationDirectory + 'template-service-v1.yaml'
$tempDockerPath  = $operationDirectory + 'Dockerfile'
$routeFixerPath  = $operationDirectory + 'route-fixer.ps1'


Invoke-WebRequest $namespaceUri   -OutFile $namespaceFile
Invoke-WebRequest $deployUri      -OutFile $deploy
Invoke-WebRequest $serviceUri     -OutFile $service
Invoke-WebRequest $dockerUri      -OutFile $tempDockerPath 
Invoke-WebRequest $routefixerUri  -OutFile $routeFixerPath



" #### Copy yaml files"
Copy-Item $namespaceFile -Destination $operationDirectory'step0.yaml'
Copy-Item $deploy        -Destination $operationDirectory'step1.yaml'
Copy-Item $service       -Destination $operationDirectory'step2.yaml'
Copy-Item $service       -Destination $operationDirectory'step3.yaml'
Copy-Item $deploy        -Destination $operationDirectory'step4.yaml'
Copy-Item $service       -Destination $operationDirectory'step5.yaml'
Copy-Item $service       -Destination $operationDirectory'step6.yaml'
Copy-Item $service       -Destination $operationDirectory'step7.yaml'
Copy-Item $deploy        -Destination $operationDirectory'step8.yaml'
####


"############ Remove template files "
Remove-Item  $namespaceFile 
Remove-Item  $deploy 
Remove-Item  $service 
 


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
    3=$publicServiceType   #let the public service to be set by parmeter between LoadBalancer , ClusterIP (default) 
    4='ClusterIP'  
    5='ClusterIP'  
    6=$publicServiceType   #let the public service to be set by parmeter between LoadBalancer , ClusterIP (default) 
    7='ClusterIP'
    8='ClusterIP'
}



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
        '#{minReplicas}#'  = $minReplicas
        '#{maxReplicas}#'  = $maxReplicas
        '#{serviceType}#'  = $serviceType[$i]
        '#{memoryLimits}#' = $memoryLimits
        '#{memoryRequest}#'= $memoryRequest
        '#{cpuLimits}#'    = $cpuLimits
        '#{cpuRequest}#'   = $cpuRequest
        '#{osType}#'       = $osType

    }


    $fullPathYaml = $operationDirectory + 'step' + $i+ '.yaml'

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
    
    if ($showModifiedFiles -eq $true)
    {
      "#######  $showModifiedFiles = $true #####"
            "Path : " + $showModifiedFiles
      "   "
      Get-Content $fullPathYaml
      "#######  END OF $showModifiedFiles = $true #####"
    }
    
}


"###changing the environment variable in docker file### " + $aspnetEnvName 
if ( $dockerReplace -eq $false)
{
 "##################################Removing Temp Dockerfile from : " + $tempDockerPath 
 Remove-Item   $tempDockerPath 
 
"################### modifing the existing docker file  ##########################"
  $oldValue = 'ENV ASPNETCORE_ENVIRONMENT=Local'
  $newValue = 'ENV ASPNETCORE_ENVIRONMENT=' +  $aspnetEnvName

  (Get-Content $dockerPath) -replace $oldValue  , $newValue    | Set-Content $dockerPath
  
  
    if ($showModifiedFiles -eq $true)
    {
      "#######  $showModifiedFiles = $true -- local (Original Dockerfile but after modification) docker file#####"
      "Path : " + $showModifiedFiles
      "   "
      (Get-Content $dockerPath) 
      "#######  END OF $showModifiedFiles = $true #####"
    }
    
}
else
{
 "####################### make sure the path to  new Dockerfile does exist (when you aske to replace it) ######"
 if ($dockerPath.LastIndexOf('\') -ne -1)
 {
    $createFolder4Dockerfile = $dockerPath.Substring(0 , $dockerPath.LastIndexOf('\'))
    New-Item -ItemType Directory -Path $createFolder4Dockerfile -Force
 }

 if ($dockerPath.LastIndexOf('/') -ne -1)
 {
    $createFolder4Dockerfile = $dockerPath.Substring(0 , $dockerPath.LastIndexOf('/'))
    New-Item -ItemType Directory -Path $createFolder4Dockerfile -Force
 }
 
 "####################### [END OF :] make sure the path to  new Dockerfile does exist ######"
 
 
 " ####################### replace the docker file to $dockerPath #############" 
 
 " ################################### Copy DockerFile into : "  + $dockerPath
  Copy-Item $tempDockerPath  -Destination $dockerPath  -Force
  
 "##################################Removing Temp Dockerfile from : "   +  $tempDockerPath 
 Remove-Item   $tempDockerPath 
  
  
  $hashTableDocker = @{
    '#{entrypoint}#'  = $dockerEntrypoint
    '#{environment}#' = $aspnetEnvName 
    '#{dockerImage}#' = $dockerBase 
    '#{BWG_SWAGGER_BASE_URL}#' = -join('ENV BWG_SWAGGER_BASE_URL=' ,  $namespace , '/' , $app , '/') 
    }
  
  if ( $addSSL -eq $true)
  {
  "########### SET ASPNETCORE_URLS with SSL ############"
    $hashTableDocker.Add('#{ASPNETCORE_HTTPS_PORT}#','ENV ASPNETCORE_HTTPS_PORT=443')
    $hashTableDocker.Add('#{ASPNETCORE_URLS}#','ENV ASPNETCORE_URLS="https://+443;http://+80"')
  }
  else
  {
  "########### SET ASPNETCORE_URLS Without SSL ############"
  
   #$urls=  -join( 'ENV ASPNETCORE_URLS="http://+80;http://+80/' , $namespace , '/' , $app , '"')
   #$urls=  -join( 'ENV ASPNETCORE_URLS="http://+80/' , $namespace , '/' , $app , '"')
   $urls=  -join( 'ENV ASPNETCORE_URLS="http://+80"')
   
   " ###  URLS =$($urls)"  
   
    $hashTableDocker.Add('#{ASPNETCORE_HTTPS_PORT}#','')
    $hashTableDocker.Add('#{ASPNETCORE_URLS}#',$urls)
  }

  foreach ($key in $hashTableDocker.GetEnumerator()) {
    "Docker keyName  = " + $key.Name 
    "Docker keyValue = " + $key.Value
    "Docker path = " +  $dockerPath
    "  "

    $oldValue = $key.Name
    $newValue = $key.Value

    (Get-Content $dockerPath) -replace $oldValue  , $newValue    | Set-Content $dockerPath
  } 
  
  if ($showModifiedFiles -eq $true)
    {
      "#######  $showModifiedFiles = $true -- modified docker file#####"  + $dockerPath
      "Path : " + $showModifiedFiles
      "   "
      (Get-Content $dockerPath) 
      "#######  END OF $showModifiedFiles = $true #####"
    }
  
 " ####################### [END OF :] replace the docker file to $dockerPath #############" 
  
    
}


if ($routeChanging  -eq $true) {
  
  $oldRouteValue = '[Route("api/[controller]")]'
  $newRouteValue = -join( '[Route("api/[controller]")]  [Route("'  , $namespace , '/'  , $($app) , '/api/[controller]")]' )
  $routeReplacingHashTable =  @{  $oldRouteValue = $newRouteValue  }

  "## New hashtable ###"
  $routeReplacingHashTable 

  # & ($routeFixerPath) -routeChanging $routeChanging -routeFilePath $routeFilePath -routeFilefilter $routeFilefilter -routeReplacingHashTable $routeReplacingHashTable   
  
  Remove-Item $routeFixerPath -ErrorAction Ignore


}

