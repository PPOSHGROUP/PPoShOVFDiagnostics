function Invoke-POVFADDiagnostics {
    <#
      .SYNOPSIS
      Invoke OVF ActiveDirectory Diagnostics tests
  
      .DESCRIPTION
      Will run Pester tests from Diagnostics folder. If configuration variable is needed, save it to POVFConfiguration parameter.
  
      .PARAMETER POVFConfiguration
      PSCustom Object with configuration details needed for pester tests. If not provided will use default from module's Configuration folder.
  
      .PARAMETER DiagnosticsFolder
      Location where Simple and Comprehensive tests are located. If not provided will use default from module's Diagnostic folder.
  
      .PARAMETER WriteToEventLog
      If enabled will write resultes to EventLog.
  
      .PARAMETER EventSource
      EventSource to be used when event log entries are generated.
  
      .PARAMETER EventIDBase
      Base ID to pass to Write-pOVFPesterEventLog
      Success tests will be written to EventLog Application with MySource as source and EventIDBase +1.
      Errors tests will be written to EventLog Application with MySource as source and EventIDBase +2.
  
      .PARAMETER OutputFolder
      Location where NUnit xml with Pester results will be stored
  
      .EXAMPLE
      $configuration  = Get-ConfigurationData -ConfigurationPath c:\someconfig.json -OutputType PSObject
      Invoke-POVFADDiagnostics -POVFConfiguration $configuration -DiagnosticsFolder c:\DiagnosticTests -WriteToEventLog -EventSource MyTests -EventIDBase 1000 -OutputFolder c:\DiagnosticResults
      
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
      $EventIDBase,
  
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
        $pOVFTestsParams.EventIDBase = $EventIDBase
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