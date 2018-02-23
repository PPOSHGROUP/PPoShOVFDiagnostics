function Invoke-POVFS2DDiagnostics {
  
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
    [ValidateSet('Operational','Configuration','Basic','Registry','NetQoS','Teaming','VMSwitch','Roles','Hyper-V')]
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
      $paramDiagnosticFolder = "$PSScriptRoot\..\Diagnostics\S2D"
    }
    #endregion
    #region param POVFConfiguration
    if($PSBoundParameters.ContainsKey('POVFConfigurationFolder')){
      $pOVFConfigurationFolderFinal = $POVFConfigurationFolder
    }
    else {
      $pOVFConfigurationFolderFinal = "$PSScriptRoot\..\ConfigurationExample\S2D"
    }
    Write-Log -Info -Message "Will read service configuration from {$pOVFConfigurationFolderFinal}"
    #endregion
    #region Global Service Configuration
    $serviceConfigurationFile = Join-Path -Path $pOVFConfigurationFolderFinal -ChildPath 'OBJPLWHVCL0.ServiceConfiguration.psd1'
    if ($serviceConfigurationFile){
      $serviceConfiguration = Get-ConfigurationData -ConfigurationPath $serviceConfigurationFile -OutputType PSObject
    }
    #endregion
    #region Nodes configuration 
    $nodes = Get-ChildItem -Path $pOVFConfigurationFolderFinal -Directory
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
    #endregion
    #endregion
    #region Invoke tests
    switch ($TestType) {
      'Simple' {
        Write-Log -Info -Message 'Performing {Simple Tests}'
        $testDirectory = Join-Path -Path $paramDiagnosticFolder -ChildPath 'Simple'
        #region POVF.ClusterOperationalStatus.Simple.Tests.ps1
        $ClusterPSSession = New-PSSessionCustom -ComputerName $serviceConfiguration.ClusterName -Credential $Credential
        $pOVFTestParams.POVFTestFileParameters =@{ 
          POVFConfiguration = $serviceConfiguration
          POVFPSSession = $ClusterPSSession
        }
        $testFile = Get-ChildItem -Path (Join-Path -Path $testDirectory -ChildPath 'POVF.ClusterOperationalStatus.Simple.Tests.ps1')
        if ($testFile) { 
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $testFile.FullName
        }
        #endregion
      }
      'Comprehensive' { 
        Write-Log -Info -Message 'Performing {Comprehensive Tests}'
        $testDirectory = Join-Path -Path $paramDiagnosticFolder -ChildPath 'Comprehensive'
        #region POVF.ClusterNodesConfiguration.Comprehensive.Tests
        foreach ($nodeConfig in $nodesConfiguration) {
          Write-Log -Info -Message "Processing node: {$($nodeConfig.ComputerName)}"
          $nodePSSession = New-PSSessionCustom -ComputerName $nodeConfig.ComputerName -Credential $Credential
          $pOVFTestParams.POVFTestFileParameters =@{ 
            POVFConfiguration = $nodeConfig
            POVFPSSession = $nodePSSession
          }
          $testFile = Get-ChildItem -Path (Join-Path -Path $testDirectory -ChildPath 'POVF.ClusterNodesConfiguration.Comprehensive.Tests.ps1')
          if ($testFile) { 
            Write-Log -Info -Message "Processing: $testFile"
            $tempOutputfile = "POVF.DHCP.{0}.Node.Comprehensive.Tests" -f $nodeConfig.ComputerName
            $pOVFTestParams.OutputFile = $tempOutputfile
            Invoke-POVFTest @pOVFTestParams -POVFTestFile $testFile.FullName
          }
        }
        #>
        #endregion
      }
    }
    #endregion
  }
  end{
    Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue   
  }
}