function Invoke-POVFADDiagnostics {
  
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,HelpMessage='Folder with Service Configuration')]
    [System.String]
    $ServiceConfiguration,

    [Parameter(Mandatory=$false,HelpMessage='Service to test')]
    [System.String]
    $ServiceName,

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
    
    #endregion
    #region Gather Full Configuration
    $paramPOVFConfiguration = Get-POVFConfiguration -POVFServiceConfiguration $ServiceConfiguration -POVFDiagnosticsFolder $POVFDiagnosticsFolder
    $paramPOVFDiagnosticsConfiguration = Get-ConfigurationData -ConfigurationPath $POVFDiagnosticsConfigurationData
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
          #TODO - generate different parameters like Credentials/Sessions if needed
          $pOVFTestParams.POVFTestFileParameters =@{ 
            POVFConfiguration = $paramPOVFConfiguration.Configuration.NonNodeData
            POVFCredential = $Credential
          }

          if($pOVFTestParams.OutputFolder){
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
            $fileNameTemp = (split-Path $testParams.DiagnosticFile -Leaf).replace('.ps1','')
            $outputFileName = "{0}_{1}_{2}_PesterResults.xml" -f $ReportFilePrefix ,$timestamp , $fileNameTemp 
            $pOVFTestParams.OutputFile = $outputFileName
          }
          #Invoke Pester tests    
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $diagnostic

        }
        #iterate through AllNodes - each node configuration 
        elseif($testParams.Configuration -eq 'AllNodes'){ 
          foreach ($node in $paramPOVFConfiguration.Configuration.AllNodes) {
            #TODO - generate different parameters like Credentials/Sessions if needed
            $pOVFTestParams.POVFTestFileParameters =@{ 
              POVFConfiguration = $node
              POVFCredential = $Credential
            }

            if($pOVFTestParams.OutputFolder){
              $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
              $fileNameTemp = 
              $outputFileName = "{0}_{1}_{2}_PesterResults.xml" -f $ReportFilePrefix, $timestamp, $fileNameTemp 
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
    #Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue   
  }
}