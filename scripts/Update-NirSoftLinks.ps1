
 
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  
#>

[CmdletBinding(SupportsShouldProcess)]
param()

function Update-NirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RootFolder         = (Resolve-Path -Path "$PSScriptRoot\..").Path
    $DbPath             = Join-Path $RootFolder 'db'
    $ScriptsPath        = Join-Path $RootFolder 'scripts'
    $GetLinksScript     = Join-Path $ScriptsPath 'Get-NirSoftLinks.ps1'
    $ProcessLinksScript = Join-Path $ScriptsPath 'Invoke-ProcessNirSoftLinks.ps1'
    $DownloadLinksJson  = Join-Path $DbPath 'download_links.json'

    . "$GetLinksScript"
    . "$ProcessLinksScript"

    $AllLinks = Get-NirSoftLinks
    $JsonFile = Invoke-ProcessNirSoftLinks -Links $AllLinks -OutFile $DownloadLinksJson
}

