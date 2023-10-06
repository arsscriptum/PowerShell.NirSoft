
 
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  
#>


function Get-NirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, HelpMessage="max")]
        [int]$Max=0
    )

    [string]$Url = "https://www.nirsoft.net/utils/index.html"
    
    $prevProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    $WebResponse = Invoke-WebRequest  $Url
    $global:ProgressPreference = $prevProgressPreference
        
    
    $StatusCode = $WebResponse.StatusCode
    if($StatusCode -ne 200){
        throw "Invalid request response ($StatusCode)"
    }

    $PreParsedLinks = [System.Collections.ArrayList]::new()
    $PostParsedLinks = [System.Collections.ArrayList]::new()
    $Links = $WebResponse.Links | Select href
    ForEach($l in $Links.href){
        if(($l -match 'html')-And($l -notmatch '\.\.')-And($l -notmatch '/')){
            $Null = $PreParsedLinks.Add($l)
            if($Max -gt 0){
                if(($PreParsedLinks.Count) -ge $Max){
                    break;
                }
            }
        }
    } 
    return $PreParsedLinks
}
