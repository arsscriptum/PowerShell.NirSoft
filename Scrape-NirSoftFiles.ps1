
 
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false, HelpMessage="max")]
    [switch]$Force
)

$RootFolder         = (Resolve-Path -Path "$PSScriptRoot").Path
$DbPath             = Join-Path $RootFolder 'db'
$ScriptsPath        = Join-Path $RootFolder 'scripts'
$DepsImporter       = Join-Path $RootFolder 'Import-Dependencies.ps1'
$DownloadLinksJson  = Join-Path $DbPath 'download_links.json'

. "$DepsImporter" -Path $ScriptsPath



function Test-JsonLinksFile{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try{
        $Ret = $True
        if(-not(Test-Path -Path "$DownloadLinksJson" -PathType Leaf)) { return $False }
        $JsonData = Get-Content "$DownloadLinksJson" | ConvertFrom-Json
        $NumItems = $JsonData.Count
        Write-Verbose "$NumItems item in link file"
        if($NumItems -lt 100){ return $False }
    }catch{
        $Ret = $False
    }
    return $Ret
}

if($Force -eq $True){
    Remove-Item -Path $DownloadLinksJson -Force -ErrorAction Ignore
}
if(-not(Test-JsonLinksFile)){
    Write-Host "updating nirsoft downoad links..." -f DarkCyan
    Update-NirSoftLinks
}else{
    Write-Host "using links file `"$DownloadLinksJson`". Delete it, or use -Force to refresh" -f DarkYellow
}


Save-AllNirSoftLinks
