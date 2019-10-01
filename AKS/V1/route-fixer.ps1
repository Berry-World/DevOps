Param(
  [Parameter(Mandatory=$false)]
  [boolean]$routeChanging  = $false,
  [Parameter(Mandatory=$false)]
  [string]$routrFilePath= "./", 
  [Parameter(Mandatory=$false)]
  [string]$RoutFilefilter= "*.cs", 
  [Parameter(Mandatory=$false)]
  [hashtable]$routeReplacingHashTable =  @{ '\[Route\(\"api' = '[Route("tst1/finance/api'  }
  
)

if ( $routeChanging -eq $true){

  Get-ChildItem -Path $routrFilePath -Filter $RoutFilefilter -Recurse  | ForEach-Object {

    $fullFileName =  $_.FullName

    foreach ($key in $replacinghashtable.getenumerator()) {

      $oldvalue = $key.name
      $newvalue = $key.value

      (get-content $fullFileName) -replace $oldvalue  , $newvalue     | set-content $fullFileName
    } 
  }
}
