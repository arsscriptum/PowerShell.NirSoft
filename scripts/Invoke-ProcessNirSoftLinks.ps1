
 
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


function Invoke-ProcessNirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0, HelpMessage="exp")]
        [System.Collections.ArrayList]$Links,
        [Parameter(Mandatory=$true, Position = 1, HelpMessage="OutFile")]
        [String]$OutFile
    )
    try{

        $Null = Remove-Item -Path $OutFile -Force -ErrorAction Ignore
        $Null = New-Item -Path $OutFile -ItemType File -Force -ErrorAction Ignore
        
        [System.Collections.ArrayList]$AllLinks = [System.Collections.ArrayList]::new()

        Show-MsgBoxProgress
        $CurrId=0
        $LinksCount = $Links.Count
        [string]$BaseUrl = "https://www.nirsoft.net/utils/"
        [string]$RequestedUrl = ""
       
        [int]$Counter = 1
        ForEach($l in $Links){
            $Counter++
           
            if($Script:OperationCancelled -eq $True){ 
                $JsonData = $AllLinks | ConvertTo-Json
                Set-Content -PAth $OutFile -Value $JsonData
                return $OutFile
            }
            [string]$RequestedUrl = "https://www.nirsoft.net/utils/" + $l
            Write-Verbose "Getting links from $RequestedUrl " 
            

            $prevProgressPreference = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            $LinksRequestResponse = Invoke-WebRequest  $RequestedUrl -ErrorAction Stop
            $global:ProgressPreference = $prevProgressPreference
                        
            
            $StatusCode = $LinksRequestResponse.StatusCode
            $msg = "Processed $Counter out of $LinksCount links"
            $perc = [math]::Round( (($Counter / $LinksCount)*100))
            
            if($perc -le 1){ $perc = 1 }
            if($perc -ge 99){ $perc = 100 } 
            
            $Script:labelProgress.Content = $msg 
            $Script:pbStatus.Value = $perc
            $Null = [System.Windows.Forms.Application]::DoEvents()  | Out-Null
            
            if($StatusCode -ne 200){
                throw "Invalid request response ($StatusCode)"
            }
            $htmldata = $LinksRequestResponse.Content
            $InnerLinks = $LinksRequestResponse.Links | Select href
            

            ForEach($l in $InnerLinks.href){
                if(($l -match '\.zip')-Or($l -match '\.exe')){
                    $firstChar = $l[0]
                    $fullLink = $BaseUrl + $l
                    if($firstChar -eq '/'){
                        $fullLink =  "https://www.nirsoft.net" + $l
                    }
                    # $r = Test-NirsoftUrl -Url $fullLink
                    if($fullLink -notmatch 'trans'){
                        Write-Verbose "ProcessLinks => Adding $fullLink "
                      
                        $Type = 'x86'
                        if($fulllink -match 'x64') { $Type = 'x64' }
                        [uri]$u = $RequestedUrl
                        $Filename = $u.Segments[$u.Segments.Count-1]
                        $Filename = $Filename.substring(0,($Filename.IndexOf('.')))
                        $o = [PsCustomObject]@{
                            Name = $Filename
                            Type = $Type 
                            Url  = $fullLink
                        }
                        [void]$AllLinks.Add($o)
                    }

                }
            } 
            
        } 

        $Script:Window.Close()
        
        $JsonData = $AllLinks | ConvertTo-Json
        Set-Content -PAth $OutFile -Value $JsonData
        $OutFile
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

