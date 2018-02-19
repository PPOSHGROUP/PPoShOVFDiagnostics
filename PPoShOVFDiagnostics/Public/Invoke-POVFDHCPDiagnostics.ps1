function Invoke-POVFDHCPDiagnostics {
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

      .PARAMETER Credential
      Credentials to be used in remote tests
      
      .PARAMETER Show
      If enabled will show pester results to console.

      .PARAMETER TestType
      The type of tests to execute, this may be either "Simple", "Comprehensive"
      or Both ("Simple,Comprehensive"). "Simple,Comprehensive" is the default.
  
      .EXAMPLE
      $configuration  = Get-ConfigurationData -ConfigurationPath c:\someconfig.json -OutputType PSObject
      Invoke-POVFDHCPDiagnostics -POVFConfiguration $configuration -DiagnosticsFolder c:\DiagnosticTests -WriteToEventLog -EventSource MyTests -EventIDBase 1000 -OutputFolder c:\DiagnosticResults
      #Invoke-POVFDHCPDiagnostics -POVFConfiguration $dhcpconfig -DiagnosticsFolder $dhcpDiagFolder -Show All -Credential $creds  -WriteToEventLog -EventSource POVFDHCP -EventIDBase 1000 -OutputFolder 'C:\AdminTools\Newfolder'
#Invoke-POVFDHCPDiagnostics -POVFConfiguration $dhcpconfig -DiagnosticsFolder $dhcpDiagFolder -Show All -Credential $creds  -WriteToEventLog -EventSource POVFDHCP -EventIDBase 1000 
#Invoke-POVFDHCPDiagnostics -POVFConfiguration $dhcpconfig -DiagnosticsFolder $dhcpDiagFolder -Show All -Credential $creds -TestType Comprehensive -Tag ScopeAndReservation
  #>
   
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
    [ValidateSet('Operational','ScopeAndReservation','Configuration','Reservations')]
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
      $paramDiagnosticFolder = "$PSScriptRoot\..\Diagnostics\DHCP"
    }
    #endregion
    #region param POVFConfiguration
    if($PSBoundParameters.ContainsKey('POVFConfigurationFolder')){
      $pOVFConfigurationFolderFinal = $POVFConfigurationFolder
    }
    else {
      $pOVFConfigurationFolderFinal = "$PSScriptRoot\..\ConfigurationExample\DHCP"
    }
    Write-Log -Info -Message "Will read service configuration from {$pOVFConfigurationFolderFinal}"
    #endregion
    #region Global Service Configuration
    $serviceConfigurationFile = Join-Path -Path $pOVFConfigurationFolderFinal -ChildPath 'DHCP.ServiceConfiguration.json'
    if ($serviceConfigurationFile){
      $serviceConfiguration = Get-ConfigurationData -ConfigurationPath $serviceConfigurationFile -OutputType PSObject
    }
    #endregion
    #region Nodes configuration 
      $nodes = Get-ChildItem -Path $pOVFConfigurationFolderFinal -Directory
      if ($nodes) { 
        $nodesConfiguration = @()
        foreach ($node in $nodes) {
          $tempConfig = @{
            nodeConfiguration = ''
            reservationsConfiguration = ''
            scopeConfiguration = ''
          }
          $nodeConfigurationFile = Join-Path -Path $node.FullName -ChildPath 'DHCP.ServiceConfiguration.json'
          if ($nodeConfigurationFile) { 
            $tempConfig.nodeConfiguration = Get-ConfigurationData -ConfigurationPath $nodeConfigurationFile -OutputType PSObject
          }

          $reservationFolder = Join-Path -Path $node.FullName -ChildPath 'Reservations'
          if($reservationFolder) {
            $tempConfig.reservationsConfiguration = Get-ChildItem -Path $reservationFolder | ForEach-Object { 
              Get-ConfigurationData -ConfigurationPath $PSItem.FullName -OutputType PSObject 
            }
          }
          
          $scopeFolder = Join-Path -Path $node.FullName -ChildPath 'Scopes'
          if ($scopeFolder){
            $tempConfig.scopeConfiguration = Get-ChildItem -Path $scopeFolder | ForEach-Object { 
              Get-ConfigurationData -ConfigurationPath $PSItem.FullName -OutputType PSObject 
            }
          }
          $nodesConfiguration +=$tempConfig
        }
      } 
    #endregion
    #endregion
    #region Invoke tests
    switch ($TestType) {
      'Simple' {
        Write-Log -Info -Message 'Performing {Simple Tests}'
        $testDirectory = Join-Path -Path $paramDiagnosticFolder -ChildPath 'Simple'
        #region POVF.DHCP.Simple.Tests.ps1
        $pOVFTestParams.POVFTestFileParameters =@{ 
          POVFConfiguration = $serviceConfiguration
          POVFCredential = $Credential
        }
        $testFile = Get-ChildItem -Path (Join-Path -Path $testDirectory -ChildPath 'POVF.DHCP.Simple.Tests.ps1')
        if ($testFile) { 
          Invoke-POVFTest @pOVFTestParams -POVFTestFile $testFile.FullName
        }
        #endregion
        #region POVF.DHCP.Node.Simple.Tests.ps1
        foreach ($nodeConfig in $nodesConfiguration) {
          Write-Log -Info -Message "Processing node: {$($nodeConfig.nodeConfiguration.ComputerName)}"
          $nodePSSession = New-POVFRemoteSession -ComputerName $nodeConfig.nodeConfiguration.ComputerName -Credential $Credential
          $pOVFTestParams.POVFTestFileParameters =@{ 
            POVFConfiguration = $nodeConfig.nodeConfiguration
            POVFPSSession = $nodePSSession
          }
          $testFile = Get-ChildItem -Path (Join-Path -Path $testDirectory -ChildPath 'POVF.DHCP.Node.Simple.Tests.ps1')
          if ($testFile) { 
            Write-Log -Info -Message "Processing: $testFile"
            $tempOutputfile = "POVF.DHCP.{0}.Node.Simple.Tests" -f $nodeConfig.nodeConfiguration.ComputerName
            $pOVFTestParams.OutputFile = $tempOutputfile
            Invoke-POVFTest @pOVFTestParams -POVFTestFile $testFile.FullName
          }
        }
        
        #endregion

      }
      'Comprehensive' { 
        Write-Log -Info -Message 'Performing {Comprehensive Tests}'
      }
    }
  }
  end{
    Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue   
  }
}