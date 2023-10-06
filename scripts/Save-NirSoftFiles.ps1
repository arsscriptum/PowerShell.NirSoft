 
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  
#>


[CmdletBinding(SupportsShouldProcess)]
param()



[Bool]$Script:OperationCancelled = $False

function Invoke-CancelUpdate{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try{
        $Script:labelProgress.Content = "Cancelling..."
        $Null = [System.Windows.Forms.Application]::DoEvents()  | Out-Null
        $Script:OperationCancelled = $True
    
        Start-Sleep 1
        $Script:Window.Close()
    }catch{
        Write-Error "$_"
    }
}




function Show-MsgBoxProgress{
    [CmdletBinding(SupportsShouldProcess)]
    Param()


    [void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
    [void][System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')
    [void][System.Reflection.Assembly]::LoadWithPartialName('WindowsBase')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Xml')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows')

    [xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Please Wait" Height="176" Width="488.932"
    WindowStartupLocation="CenterOwner"
    x:Name="Window" ResizeMode="NoResize" FontFamily="Verdana" FontSize="14"
    xmlns:wf="clr-namespace:System.Windows.Forms;assembly=System.Windows.Forms">
    <Window.Background>
        <LinearGradientBrush EndPoint="0.5,1" MappingMode="RelativeToBoundingBox" StartPoint="0.5,0">
            <GradientStop Color="{DynamicResource {x:Static SystemColors.HotTrackColorKey}}" Offset="0.869"/>
            <GradientStop Color="White" Offset="0.109"/>
        </LinearGradientBrush>
    </Window.Background>
    <Grid Margin="40,20,40,16">
        <ProgressBar Height="20" Margin="34,36,46,0" VerticalAlignment="Top" Minimum="0" Maximum="100" Name="pbStatus"/>
        <Button x:Name="buttonCancel" Content="Cancel" HorizontalAlignment="Left" Margin="163,73,0,0" VerticalAlignment="Top" Width="75" RenderTransformOrigin="0.52,-0.857" Height="23"/>
        <Label x:Name="labelProgress" Content="Operation in progress..." HorizontalAlignment="Left" Margin="34,0,0,0" VerticalAlignment="Top" Width="321" Height="31"/>
    </Grid>
</Window>
"@



    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $Window=[Windows.Markup.XamlReader]::Load( $reader )
    

    #AutoFind all controls 
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {  
        New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force -Scope Script
        Write-Verbose "Variable named: Name $($_.Name)"
    }

   
    $pbStatus = Get-Variable -Name "pbStatus" -ValueOnly -Scope Script
    $labelProgress = Get-Variable -Name "labelProgress" -ValueOnly -Scope Script
    $buttonCancel = Get-Variable -Name "buttonCancel" -ValueOnly -Scope Script


    $pbStatus.Value = 0

    $buttonCancel.Add_Click({
        Invoke-CancelUpdate
    })
    ## -- Show the Progress-Bar and Start The PowerShell Script
    $Window.Show() | Out-Null
    $Window.Focus() | Out-NUll
}



function Receive-JobList{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
        [System.Collections.ArrayList]$JobsIds
    )
    
    ForEach($id in $JobsIds){
        Get-Job -Id $id | Receive-Job
    } 
}

function Receive-AllJobs{
    [CmdletBinding(SupportsShouldProcess)]
    param(
    )
    
    ForEach($id in ($(Get-job).Id)){
        Get-Job -Id $id | Receive-Job
    } 
}


function Test-NirsoftDownloadLink{
        [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Url")]
        [Alias("u")]
        [string]$Url
    )
    $Ret = $true
    try{
        $prevProgressPreference = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'
        $webreq = Invoke-WebRequest  $Url -ErrorAction Stop
        $global:ProgressPreference = $prevProgressPreference
        
        $StatusCode = $webreq.StatusCode
        if($StatusCode -ne 200){
            throw "Invalid request response ($StatusCode)"
        }
    }catch {
        $Ret = $false 
    }
    return $Ret
}

[System.Collections.ArrayList]$Script:AllJobs = [System.Collections.ArrayList]::new()

function Save-NirsoftFile{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
        [Alias("u")]
        [string]$Url,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
        [Alias("d")]
        [string]$DestinationPath
    )


  try{

    [Uri]$Val = $Url;
    $HttpHost = $Val.Host
    $HttpPathAndQuery = $Val.PathAndQuery
    $FullPathAndQuery = $HttpHost +$HttpPathAndQuery
    $Name = $Val.Segments[$Val.Segments.Count-1]
    $DestinationFilePath = Join-Path $DestinationPath $Name
    $HttpReferrer = $HttpHost
    
    Write-verbose "Downloading to $DestinationFilePath"
    $Script:ProgressTitle = 'STATE: DOWNLOAD'
    $uri = New-Object "System.Uri" "$Url"
    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.PreAuthenticate = $false
    $request.Method = 'GET'

    $request.Headers.Add('sec-ch-ua', '" Not A;Brand";v="99", "Chromium";v="99", "Google Chrome";v="99"')
    $request.Headers.Add('sec-ch-ua-mobile', '?0')
    $request.Headers.Add('sec-ch-ua-platform', "Windows")
    $request.Headers.Add('Sec-Fetch-Site', 'same-site')
    $request.Headers.Add('Sec-Fetch-Mode' ,'navigate')
    $request.Headers.Add('Sec-Fetch-Dest','document')
    $request.Headers.Add('Upgrade-Insecure-Requests', '1')
    $request.Headers.Add('User-Agent','Automated PowerShell Script')

    $request.Referer = $HttpReferrer
    $request.Headers.Add('Referer' , $HttpReferrer)

    $request.Headers.Add('Accept-Encoding', 'gzip, deflate, br')
    $request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'

    $request.KeepAlive = $true
    $request.Timeout = ($TimeoutSec * 1000)

    $request.set_Timeout(15000) #15 second timeout

    $response = $request.GetResponse()

    $totalLengthKb = [System.Math]::Floor($response.get_ContentLength()/1024)
    $totalLengthMb = [System.Math]::Floor($response.get_ContentLength()/1024/1024)
    $totalLengthBytes = [System.Math]::Floor($response.get_ContentLength())
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $DestinationFilePath, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $dlkb = 0
    $downloadedBytes = $count
    $script:steps = $totalLengthKb
    while ($count -gt 0){
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
       $dlkb = $([System.Math]::Floor($downloadedBytes/1024))
       $dlmb = $([System.Math]::Floor($downloadedBytes/1024/1024))
       $msg = "Downloaded $dlmb MB of $totalLengthMb MB"
       $perc = (($downloadedBytes / $totalLengthBytes)*100)
       #if(($perc -gt 0)-And($perc -lt 100)){
        # Write-Progress -Activity $Script:ProgressTitle -Status $msg -PercentComplete $perc 
       #}
    }

    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
  }catch{
    throw $_

  }finally{
    #Write-Progress -Activity $Script:ProgressTitle -Completed
    Write-verbose "Downloaded $Url"
  }
}




$ParallelScript = {
  param($Url,$DestinationPath)
    
  try{
    [Uri]$Val = $Url;
    $HttpHost = $Val.Host
    $HttpPathAndQuery = $Val.PathAndQuery
    $FullPathAndQuery = $HttpHost +$HttpPathAndQuery
    $Name = $Val.Segments[$Val.Segments.Count-1]
    $DestinationFilePath = Join-Path $DestinationPath $Name
    $HttpReferrer = $HttpHost
    
    Write-verbose "Downloading to $DestinationFilePath"
    $Script:ProgressTitle = 'STATE: DOWNLOAD'
    $uri = New-Object "System.Uri" "$Url"
    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.PreAuthenticate = $false
    $request.Method = 'GET'

    $request.Headers.Add('sec-ch-ua', '" Not A;Brand";v="99", "Chromium";v="99", "Google Chrome";v="99"')
    $request.Headers.Add('sec-ch-ua-mobile', '?0')
    $request.Headers.Add('sec-ch-ua-platform', "Windows")
    $request.Headers.Add('Sec-Fetch-Site', 'same-site')
    $request.Headers.Add('Sec-Fetch-Mode' ,'navigate')
    $request.Headers.Add('Sec-Fetch-Dest','document')
    $request.Headers.Add('Upgrade-Insecure-Requests', '1')
    $request.Headers.Add('User-Agent','Automated PowerShell Script')

    $request.Referer = $HttpReferrer
    $request.Headers.Add('Referer' , $HttpReferrer)

    $request.Headers.Add('Accept-Encoding', 'gzip, deflate, br')
    $request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'

    $request.KeepAlive = $true
    $request.Timeout = ($TimeoutSec * 1000)

    $request.set_Timeout(15000) #15 second timeout

    $response = $request.GetResponse()

    $totalLengthKb = [System.Math]::Floor($response.get_ContentLength()/1024)
    $totalLengthMb = [System.Math]::Floor($response.get_ContentLength()/1024/1024)
    $totalLengthBytes = [System.Math]::Floor($response.get_ContentLength())
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $DestinationFilePath, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $dlkb = 0
    $downloadedBytes = $count
    $script:steps = $totalLengthKb
    while ($count -gt 0){
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
    }

    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
    
  }catch{
    Write-Error $_
    return $false
  }
}.GetNewClosure()
[scriptblock]$ParallelDownloadSb = [scriptblock]::create($ParallelScript) 


function Save-NirSoftLinksParallel{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
        [string]$Url,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
        [string]$DestinationPath,
        [Parameter(Mandatory=$false)]
        [switch]$Test
    )
    $a = @("$Url","$DestinationPath")
    $JobId = (Start-Job -ScriptBlock $ParallelDownloadSb -ArgumentList $a).Id 
    [void]$Script:AllJobs.Add($JobId)
}


function Get-OnlineNirsoftFile{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
        [Alias("u")]
        [string]$Url,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
        [Alias("d")]
        [string]$DestinationPath,
        [Parameter(Mandatory=$false)]
        [switch]$Parallel
    )
    try{
      if($Parallel -eq $True){
        Save-NirSoftLinksParallel -Url $link -DestinationPath $newpath
      }else{
        Save-NirsoftFile -Url $link -DestinationPath $newpath
      }
    }catch{
      Write-Warning "Error Downloading `"$Url`""
    }
}

function Save-AllNirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Parallel
    )

    $RootFolder         = (Resolve-Path -Path "$PSScriptRoot\..").Path
    $DbPath             = Join-Path $RootFolder 'db'
    $ScriptsPath        = Join-Path $RootFolder 'scripts'
    $SavedDataPath      = Join-Path $RootFolder 'saved'
    $DownloadLinksJson  = Join-Path $DbPath 'download_links.json'


    $Null = Remove-Item -Path $SavedDataPath -Recurse -Force -ErrorAction Ignore
    $Null = New-Item -Path $SavedDataPath -ItemType Directory -Force -ErrorAction Ignore
        
    Show-MsgBoxProgress

    $Data = Get-Content -Path $DownloadLinksJson | ConvertFrom-Json
    [uint32]$DataCount = $Data.Count
    [uint32]$count = 0
    ForEach($item in $Data){

      if($Script:OperationCancelled -eq $True){ 
        $Script:Window.Close()
        return
      }

      $count++
      $name = $item.Name
      $link = $item.Url
      $type = $item.Type
      
      $newpath = Join-Path $SavedDataPath $name
      $newpath = Join-Path $newpath $type
      
      $Null = New-Item -Path $newpath -ItemType Directory -Force -ErrorAction Ignore
      
      [uri]$u = $link
      $Filename = $u.Segments[$u.Segments.Count-1]
    
      $msg = "Processed $count out of $DataCount links"
      $perc = [math]::Round( (($count / $DataCount)*100))
            
      if($perc -le 1){ $perc = 1 }
      if($perc -ge 99){ $perc = 100 } 
            
      $Script:labelProgress.Content = $msg 
      $Script:pbStatus.Value = $perc
      $Null = [System.Windows.Forms.Application]::DoEvents()  | Out-Null
            

      Get-OnlineNirsoftFile -Url $link -DestinationPath $newpath -Parallel:$Parallel
  
    }
    $Script:Window.Close()
        
    if($Parallel -eq $True){
      ForEach($job_id in $Script:AllJobs){
          Start-Sleep -Milliseconds 20
          $job_data = Get-Job -Id $job_id
          $status = $job_data.State
          if($status -eq 'Completed'){
            Write-Host "Job $job_id completed!"
            get-job -Id $job_id | Remove-Job -Force
          }
        }
    }
}

