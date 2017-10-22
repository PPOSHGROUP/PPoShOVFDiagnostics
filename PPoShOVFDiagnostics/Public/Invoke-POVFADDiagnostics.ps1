function Invoke-POVFADDiagnostics {
    <#
      .SYNOPSIS
      Describe purpose of "Invoke-POVFADDiagnostics" in 1-2 sentences.
  
      .DESCRIPTION
      Add a more complete description of what the function does.
  
      .PARAMETER POVFConfiguration
      Describe parameter -POVFConfiguration.
  
      .PARAMETER DiagnosticsFolder
      Describe parameter -DiagnosticsFolder.
  
      .PARAMETER WriteToEventLog
      Describe parameter -WriteToEventLog.
  
      .PARAMETER EventSource
      Describe parameter -EventSource.
  
      .PARAMETER EventBaseID
      Describe parameter -EventBaseID.
  
      .PARAMETER OutputFolder
      Describe parameter -OutputFolder.
  
      .EXAMPLE
      Invoke-POVFADDiagnostics -POVFConfiguration Value -DiagnosticsFolder Value -WriteToEventLog -EventSource Value -EventBaseID Value -OutputFolder Value
      Describe what this call does
  
      .NOTES
      Place additional notes here.
  
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Invoke-POVFADDiagnostics
  
      .INPUTS
      List of input types that are accepted by this function.
  
      .OUTPUTS
      List of output types produced by this function.
    #>
   
    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$false,HelpMessage='Configuration as PSCustomObject',
      ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
      [PSCustomObject]
      $POVFConfiguration,
  
      [Parameter(Mandatory=$false, HelpMessage='Folder with Pester tests',
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [ValidateScript({Test-Path -Path $_ -PathType Container})]
      [System.String]
      $DiagnosticsFolder,
  
      [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [switch]
      $WriteToEventLog,
  
      [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [string]
      $EventSource,
  
      [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [int32]
      $EventBaseID,
  
      [Parameter(Mandatory=$false,HelpMessage='Destination folder for reports',
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [ValidateScript({Test-Path -Path $_ -PathType Container -IsValid})]
      [String]
      $OutputFolder,

      [Parameter(Mandatory=$false,HelpMessage='Show Pester Tests on console',
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [ValidateSet('All','Context','Default','Describe','Failed','Fails','Header','Inconclusive','None','Passed','Pending','Skipped','Summary')]
      [String]
      $Show
    )
    process{
      $pOVFTestsParams = @{}
      if($PSBoundParameters.ContainsKey('POVFConfiguration')){
        $pOVFTestsParams.POVFConfiguration = $POVFConfiguration
      }
      else {
        $configurationModulePath = "$PSScriptRoot\..\Configuration\AD\AD.ServiceConfiguration.json"
        $pOVFTestsParams.POVFConfiguration = Get-ConfigurationData -ConfigurationPath $configurationModulePath -OutputType PSObject
      }
      if($PSBoundParameters.ContainsKey('DiagnosticsFolder')){
        $pOVFTestsParams.DiagnosticsFolder = $DiagnosticsFolder
      }
      else {
        $pOVFTestsParams.DiagnosticsFolder = "$PSScriptRoot\..\Diagnostics\AD"
      }
      if($PSBoundParameters.ContainsKey('WriteToEventLog')){
        $pOVFTestsParams.WriteToEventLog = $true
        $pOVFTestsParams.EventSource = $EventSource
        $pOVFTestsParams.EventBaseID = $EventBaseID
      }
      if($PSBoundParameters.ContainsKey('OutputFolder')){
        $pOVFTestsParams.OutputFolder = $OutputFolder
      }
      if($PSBoundParameters.ContainsKey('Show')){
        $pOVFTestsParams.Show = $Show
      }
      Invoke-POVFTests @pOVFTestsParams
    }
  }