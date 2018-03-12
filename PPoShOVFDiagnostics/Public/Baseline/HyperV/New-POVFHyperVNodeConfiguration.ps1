function New-POVFHyperVNodeConfiguration {
  [CmdletBinding()]
  param (
      
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    $ComputerName,
  
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [string]
    $ConfigurationName,
      
    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession,
  
    [Parameter(Mandatory=$true)]
    [System.String]
    [ValidateScript({Test-Path -Path $PSItem -IsValid})]
    $POVFConfigurationFolderHyperV
    
  )
  process{
    
    if(-not (Test-Path $POVFConfigurationFolderHyperV)        ) {
      [void](New-Item -Path $POVFConfigurationFolderHyperV -ItemType Directory)
    }
     
    #Get Nodes configuration
    foreach ($computer in $ComputerName) {
      if($PSBoundParameters.ContainsKey('ComputerName')) { 
        $sessionParams = @{
          ComputerName = $computer
          SessionName = "POVF-$computer"
        }
        if($PSBoundParameters.ContainsKey('ConfigurationName')){
          $sessionParams.ConfigurationName = $ConfigurationName
        }
        if($PSBoundParameters.ContainsKey('Credential')){
          $sessionParams.Credential = $Credential
        }
        $POVFPSSession = New-PSSessionCustom @SessionParams
      }
      if($PSBoundParameters.ContainsKey('PSSession')){
        $POVFPSSession = $PSSession
      }
      $computerConfig = Get-POVFHyperVNodeConfiguration -PSSession $POVFPSSession 
      $computerFile = Join-Path -Path $POVFConfigurationFolderHyperV -childPath ('{0}.Configuration.json' -f $computer)
      $computerConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $computerFile
    }
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}