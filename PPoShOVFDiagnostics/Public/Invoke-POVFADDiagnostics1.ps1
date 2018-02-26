function Invoke-POVFADDiagnostics1 {
  
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,HelpMessage='Folder with Service Configuration')]
    [System.String]
    $ServiceConfiguration,

    [Parameter(Mandatory=$false,HelpMessage='Configuration of Pester tests')]
    [System.String]
    $POVFDiagnosticsConfigurationData,
  
    [Parameter(Mandatory=$false, HelpMessage='Folder with Pester tests')]    
      [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [System.String]
    $POVFDiagnosticsFolder,
  
    [Parameter(Mandatory=$false)]
    [switch]
    $WriteToEventLog,
  
    [Parameter(Mandatory=$false)]
    [string]
    $EventSource,
  
    [Parameter(Mandatory=$false)]
    [int32]
    $EventIDBase,
  
    [Parameter(Mandatory=$false,HelpMessage='Destination folder for reports')]
      [ValidateScript({Test-Path -Path $_ -PathType Container -IsValid})]
    [String]
    $OutputFolder,

    [Parameter(Mandatory=$false,HelpMessage='Report File prefix')]
      [ValidateNotNullOrEmpty()]
    [String]
    $ReportFilePrefix,

    [Parameter(Mandatory=$false,HelpMessage='Show Pester Tests on console')]
    [ValidateSet('All','Context','Default','Describe','Failed','Fails','Header','Inconclusive','None','Passed','Pending','Skipped','Summary')]
    [String]
    $Show,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,HelpMessage='test type for Pester')]
      [ValidateSet('Simple','Comprehensive')]
    [string[]]
    $TestType = @('Simple','Comprehensive'),

    [Parameter(Mandatory=$false,HelpMessage='Tag for Pester')]
      [ValidateSet('Operational','Configuration')]
    [string[]]
    $Tag
    
    #$JEAEndpoint
  )
  process{
    #region parameters Initialize 
    #region param regular 
    $pOVFTestParams = @{}
    if($PSBoundParameters.ContainsKey('WriteToEventLog')){
      $pOVFTestParams.WriteToEventLog = $true
      $pOVFTestParams.EventSource = $EventSource
      $pOVFTestParams.EventIDBase = $EventIDBase
    }
    if($PSBoundParameters.ContainsKey('OutputFolder')){
      $pOVFTestParams.OutputFolder = $OutputFolder
    }
    if($PSBoundParameters.ContainsKey('Show')){
      $pOVFTestParams.Show = $Show
    }
    if($PSBoundParameters.ContainsKey('Tag')){
      $pOVFTestParams.Tag = $Tag
    }
    #endregion
    #region Configuration File matching Diagnostics Tests to AllNodes and NonNodeData
    if($PSBoundParameters.ContainsKey('POVFDiagnosticsConfigurationData')){
      $paramPOVFDiagnosticsConfigurationData = $POVFDiagnosticsConfigurationData
    }
    else {
      $paramPOVFDiagnosticsConfigurationData = "$PSScriptRoot\..\Configuration\AD"
    }
    Write-Log -Info -Message "Will read Diagnostics Configuration from {$paramPOVFDiagnosticsConfigurationData}"
    #endregion
    #region select folder with Pester tests
    if($PSBoundParameters.ContainsKey('POVFDiagnosticsFolder')){
      $paramPOVFDiagnosticFolder = $POVFDiagnosticsFolder
    }
    else {
      $paramPOVFDiagnosticFolder = "$PSScriptRoot\..\Diagnostics\AD"
    }
    Write-Log -Info -Message "Will read Diagnostics Tests from {$paramPOVFDiagnosticFolder}"
    #endregion
    #region Service Configuration (i.e. DHCP, AD)
    if($PSBoundParameters.ContainsKey('ServiceConfiguration')){
      $paramServiceConfiguration = $ServiceConfiguration
    }
    else {
      $paramServiceConfiguration = "$PSScriptRoot\..\ConfigurationExample\AD"
    }
    Write-Log -Info -Message "Will read service configuration from {$paramServiceConfiguration}"
    #endregion
    #region Gather Full Configuration
    $paramPOVFConfiguration = Get-POVFConfiguration -POVFServiceConfiguration $paramServiceConfiguration -POVFDiagnosticsFolder $paramPOVFDiagnosticFolder
    $paramPOVFDiagnosticsConfiguration = Get-ConfigurationData -ConfigurationPath $paramPOVFDiagnosticsConfigurationData
    #endregion

    
    ###################################
    #region Tests

    foreach ($test in $TestType) {
      Write-Log -Info -Message "Performing {$test} Tests"
      foreach ($diagnostic in $paramPOVFConfiguration.Diagnostics.$test) { 
        #Get Test parameters from Diagnostics Configuration
        $testName =  Split-Path -Path $diagnostic -Leaf
        $testParams = $paramPOVFDiagnosticsConfiguration.$test | Where-Object {$PSItem.DiagnosticFile -eq $testName}
        if($testParams.Configuration -eq 'NonNodeData') {
          write-host 'bla'
          $pOVFTestParams.POVFTestFileParameters =@{ 
            $POVFConfiguration = $paramPOVFConfiguration.Configuration.NonNodeData
            $POVCredential = $Credential
          }

          if($pOVFTestParams.OutputFolder){
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
            $fileNameTemp = ($testParams.DiagnosticFile).Trim('.ps1')
            $outputFileName = "{0}_{1}_{2}." -f $ReportFilePrefix, $fileNameTemp ,$timestamp
            $pOVFTestParams.OutputFile = $outputFileName
          }
              
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $diagnostic

      }
        elseif($testParams.Configuration -eq 'AllNodes'){ 
          write-host 'bla2'
            foreach ($node in $paramPOVFConfiguration.Configuration.AllNodes) {
              $pOVFTestParams.POVFTestFileParameters =@{ 
                $POVFConfiguration = $node
                $POVCredential = $Credential
              }

              if($pOVFTestParams.OutputFolder){
                $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
                $fileNameTemp = ($testParams.DiagnosticFile).Trim('.ps1')
                $outputFileName = "{0}_{1}_{2}." -f $ReportFilePrefix, $fileNameTemp ,$timestamp
                $pOVFTestParams.OutputFile = $outputFileName
              }
                
              Invoke-POVFTest @pOVFTestParams -POVFTestFile $diagnostic
            }

          }
        }


      }
    }
    
    
    #endregion
  }
  end{
    #Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue   
  }
}