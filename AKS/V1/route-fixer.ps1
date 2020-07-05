Param(
  [Parameter(Mandatory=$false)]
  [boolean]$routeChanging  = $false,
  [Parameter(Mandatory=$false)]
  [string]$routeFilePath= "./", 
  [Parameter(Mandatory=$false)]
  [string]$routeFileFilter= "*.cs", 
  [Parameter(Mandatory=$false)]
  [hashtable]$routeReplacingHashTable =  @{ '\[Route\(\"api' = '[Route("tst1/finance/api'  }
  
)

"######### Start of Rout Fixer ###########_#"


if ( $routeChanging -eq $true){
  "Parameters :"
  "routeChanging  :  " + $routeChanging
  "routeFilePath  :  " + $routeFilePath
  "routeFileFilter  :  " + $routeFileFilter
  "routeReplacingHashTable  :  " + $routeReplacingHashTable
   
""
"######### Rout fixing files : #########"

  Get-ChildItem -Path $routeFilePath -Filter $routeFileFilter -Recurse  | ForEach-Object {

    $fullFileName =  $_.FullName
    
    "Full file name of the  Controller: " + $_.FullName 

    foreach ($key in $routeReplacingHashTable.getenumerator()) {

      $oldvalue = $key.name
      $newvalue = $key.value

      (get-content $fullFileName) -replace [regex]::escape($oldvalue)  , $newvalue   # | set-content $fullFileName
      (get-content $fullFileName) -replace [regex]::escape($oldvalue)  , $newvalue    | set-content $fullFileName
    } 
  }
}
