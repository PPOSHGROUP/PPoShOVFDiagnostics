function Invoke-POVFADDiagnostics {
  
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false,HelpMessage='Configuration as PSCustomObject',
    ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [System.String]
    $POVFConfigurationFolder,
  
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
    $Show,

    [Parameter(Mandatory=$false,
    ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [System.Management.Automation.Credential()][System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,HelpMessage='test type for Pester ',
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('Simple','Comprehensive')]
    [string[]]
    $TestType = @('Simple','Comprehensive'),

    [Parameter(Mandatory=$false,HelpMessage='Tag for Pester ',
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
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
    #region select Root folder tests
    if($PSBoundParameters.ContainsKey('DiagnosticsFolder')){
      $paramDiagnosticFolder = $DiagnosticsFolder
    }
    else {
      $paramDiagnosticFolder = "$PSScriptRoot\..\Diagnostics\AD"
    }
    #endregion
    #region param POVFConfiguration
    if($PSBoundParameters.ContainsKey('POVFConfigurationFolder')){
      $pOVFConfigurationFolderFinal = $POVFConfigurationFolder
    }
    else {
      $pOVFConfigurationFolderFinal = "$PSScriptRoot\..\ConfigurationExample\AD"
    }
    Write-Log -Info -Message "Will read service configuration from {$pOVFConfigurationFolderFinal}"
    #endregion
    #region Global Service Configuration
    $serviceConfigurationFile = Join-Path -Path $pOVFConfigurationFolderFinal -ChildPath 'AD.objectivity.ServiceConfiguration.json'
    if ($serviceConfigurationFile){
      $serviceConfiguration = Get-ConfigurationData -ConfigurationPath $serviceConfigurationFile -OutputType PSObject
    }
    #endregion
    #region Nodes configuration 
    <#$nodes = Get-ChildItem -Path $pOVFConfigurationFolderFinal -Directory
      if ($nodes) { 
        $nodesConfiguration = @()
        $nodesConfiguration = foreach ($node in $nodes) {
          $nodeConfigurationFile = Get-ChildItem -Path "$($node.FullName)\*" -include '*.psd1','*.json'
          if ($nodeConfigurationFile) {
            foreach ($file in $nodeConfigurationFile) {  
              Get-ConfigurationData -ConfigurationPath $file.FullName -OutputType PSObject
            }
          }
        }
      }
      #>
    #endregion
    #endregion
    #region Invoke tests
    switch ($TestType) {
      'Simple' {
        Write-Log -Info -Message 'Performing {Simple Tests}'
        $testDirectory = Join-Path -Path $paramDiagnosticFolder -ChildPath 'Simple'
        $testFiles = Get-ChildItem -Path $testDirectory -File -Filter '*.Tests.ps1'
        if ($testFiles) { 
          foreach ($testFile in $testFiles) { 
            $pOVFTestParams.POVFTestFileParameters =@{ 
            POVFConfiguration = $serviceConfiguration
            POVFCredential = $Credential
          }
          if($pOVFTestParams.OutputFolder){
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
            $fileNameTemp = ($testFile.Name).Trim('.ps1')
            $outputFileName = "AD_{0}_Simple_{1}_{2}." -f $serviceConfiguration.Forest.FQDN,'FileName',$timestamp
            $pOVFTestParams.OutputFile = $outputFileName
          }
            
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $testFile.FullName
          }
        }
        #endregion
      }
      'Comprehensive' { 
        Write-Log -Info -Message 'Performing {Comprehensive Tests}'
        
        #>
        #endregion
      }
    }
    #endregion
  }
  end{
    #Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue   
  }
}