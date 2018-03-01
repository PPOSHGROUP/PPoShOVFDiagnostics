function Invoke-POVFDiagnostics {
  
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,HelpMessage='Folder with Service Configuration')]
    [System.String]
    $ServiceConfiguration,

    [Parameter(Mandatory=$true,HelpMessage='Service to test',
      ParameterSetName='ServiceName')]
      [ValidateSet('AD','DHCP','GPO','LAPS','S2D')]
    [System.String]
    $POVFServiceName,

    [Parameter(Mandatory=$true,HelpMessage='Configuration of Pester tests',
      ParameterSetName='POVFFolder')]
    [System.String]
    $POVFDiagnosticsConfigurationData,
  
    [Parameter(Mandatory=$true, HelpMessage='Folder with Pester tests',
      ParameterSetName='POVFFolder')]    
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
    [string[]]
    $Tag
    
    #$JEAEndpoint
  )
  process{
    #region parameters Initialize 
    #region param regular 
    $pOVFTestParams = @{
      POVFTestFileParameters=@{}
    }
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
    
    #endregion
    #region select folder with Pester tests
    if($PSBoundParameters.ContainsKey('POVFDiagnosticsFolder')){
      $paramPOVFDiagnosticsFolder = $POVFDiagnosticsFolder
    }
    
    #endregion
    #region Service Configuration (i.e. DHCP, AD)
    if($PSBoundParameters.ContainsKey('ServiceConfiguration')){
      $paramServiceConfiguration = $ServiceConfiguration
    }
       
    #endregion
    #region
    if($PSBoundParameters.ContainsKey('POVFServiceName')){
      $rootPath = Get-Item -Path "$PSScriptRoot\.." 
      $paramPOVFDiagnosticsConfigurationData = "$rootPath\Configuration\$POVFServiceName"
      $paramPOVFDiagnosticsFolder = "$rootPath\Diagnostics\$POVFServiceName"
      if(-not ($PSBoundParameters.ContainsKey('ServiceConfiguration'))){ 
        $paramServiceConfiguration = "$rootPath\ConfigurationExample\$POVFServiceName"
      }
    }
    Write-Log -Info -Message "Will read Diagnostics Configuration Data from {$paramPOVFDiagnosticsConfigurationData}"
    Write-Log -Info -Message "Will read Diagnostics Tests from {$paramPOVFDiagnosticsFolder}"
    Write-Log -Info -Message "Will read service configuration from {$paramServiceConfiguration}"
    #endregion
    #region Gather Full Configuration
    $paramPOVFDiagnosticsConfiguration = Get-ConfigurationData -ConfigurationPath $paramPOVFDiagnosticsConfigurationData
    $paramPOVFConfiguration = Get-POVFConfiguration -POVFServiceConfiguration $paramServiceConfiguration -POVFDiagnosticsFolder $paramPOVFDiagnosticsFolder
    #endregion

    
    ###################################
    #region Tests

    foreach ($test in $TestType) {
      Write-Log -Info -Message "Performing {$test} Tests"
      #iterate through *.Tests.ps1 from Diagnostics folder
      foreach ($diagnostic in $paramPOVFConfiguration.Diagnostics.$test) { 
        #Get Test parameters from Diagnostics Configuration
        $testName =  Split-Path -Path $diagnostic -Leaf
        $testParams = $paramPOVFDiagnosticsConfiguration.$test | Where-Object {$PSItem.DiagnosticFile -eq $testName}
        #iterate through NonNodeData - General configuration of service
        if($testParams.Configuration -eq 'NonNodeData') {
          $pOVFTestParams.POVFTestFileParameters =@{ 
            POVFConfiguration = $paramPOVFConfiguration.Configuration.NonNodeData
            POVFCredential = $Credential
          }
          if($pOVFTestParams.OutputFolder){
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
            $fileNameTemp = (split-Path $testParams.DiagnosticFile -Leaf).replace('.ps1','')
            if($PSBoundParameters.ContainsKey('ReportFilePrefix')){
              $outputFileName = "{0}_{1}_{2}_PesterResults.xml" -f $ReportFilePrefix ,$timestamp , $fileNameTemp 
            }
            $outputFileName = "{0}_{1}_PesterResults.xml" -f $timestamp , $fileNameTemp 
            $pOVFTestParams.OutputFile = $outputFileName
          }
          #Invoke Pester tests    
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $diagnostic

        }
        #iterate through AllNodes - each node configuration 
        elseif($testParams.Configuration -eq 'AllNodes'){ 
          foreach ($node in $paramPOVFConfiguration.Configuration.AllNodes) {
            $pOVFTestParams.POVFTestFileParameters =@{ 
              POVFConfiguration = $node
              POVFCredential = $Credential
            }

            if($pOVFTestParams.OutputFolder){
              $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
              $fileNameTemp = (split-Path $testParams.DiagnosticFile -Leaf).replace('.ps1','')
              if($PSBoundParameters.ContainsKey('ReportFilePrefix')){
                $outputFileName = "{0}_{1}_{2}_{3}_PesterResults.xml" -f $ReportFilePrefix, $node.ComputerName, $timestamp, $fileNameTemp 
              }
              $outputFileName = "{0}_{1}_{2}_PesterResults.xml" -f $node.ComputerName,$timestamp, $fileNameTemp 
              $pOVFTestParams.OutputFile = $outputFileName
            }
             #Invoke Pester tests    
            Invoke-POVFTest @pOVFTestParams -POVFTestFile $diagnostic
          }
        }
      }
    }
    #endregion
  }
  end{
  }
}