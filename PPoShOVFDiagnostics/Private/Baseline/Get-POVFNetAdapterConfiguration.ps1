function Get-POVFNetAdapterConfiguration {
  [CmdletBinding()]
  param (
        
    [Parameter(Mandatory=$false)]
    [string[]]
    $InterfaceAlias,
    
    [Parameter(Mandatory=$false)]
    [switch]
    $Physical,
    
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,
      
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [System.Management.Automation.PSCredential]
    $Credential,
      
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [string]
    $ConfigurationName,
    
    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession
    
  )
  process{
    #region Variables set
    if($PSBoundParameters.ContainsKey('ComputerName')) { 
      $sessionParams = @{
        ComputerName = $ComputerName
        SessionName = "POVF-$ComputerName"
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
    $interfaceParams = @{
      InterfaceAlias = '*'
    } 
    if($PSBoundParameters.ContainsKey('InterfaceAlias')){
      $interfaceParams.InterfaceAlias = $InterfaceAlias
    }
    if($PSBoundParameters.ContainsKey('Physical')){
      $interfaceParams.Physical = $Physical
    }
    #endregion
    $netAdapters = @()
    $netAdapters += Invoke-Command -session $POVFPSSession -ScriptBlock {
      Get-NetAdapter @USING:interfaceParams -ErrorAction SilentlyContinue
    }
    
    if($netAdapters) {
      foreach ($interface in $netAdapters){
        $netLBFO = Invoke-Command -session $POVFPSSession -ScriptBlock{ 
          Get-NetLbfoTeam -ErrorAction SilentlyContinue 
        }
        $NetAdapterVMQ = Invoke-Command -session $POVFPSSession -ScriptBlock { 
          Get-NetAdapterVMQ -Name $USING:interface.Name -ErrorAction SilentlyContinue 
        }
        $NetAdapterQoS = Invoke-Command -session $POVFPSSession -ScriptBlock {
          Get-NetAdapterQoS -Name $USING:interface.Name -ErrorAction SilentlyContinue
        }
        $NetAdapterRSS = Invoke-Command -session $POVFPSSession -ScriptBlock { 
          Get-NetAdapterRSS -Name $USING:interface.Name -ErrorAction SilentlyContinue 
        }
        $NetAdapterRDMA = Invoke-Command -session $POVFPSSession -ScriptBlock {
          Get-NetAdapterRDMA -Name $USING:interface.Name -ErrorAction SilentlyContinue 
        }
        $NetAdapterAdvancedProperty = Invoke-Command -session $POVFPSSession -ScriptBlock { 
          Get-NetAdapterAdvancedProperty -Name $USING:interface.Name 
        }
        $interfaceProperties = [ordered]@{
          Name = $interface.Name  
          MACAddress = $interface.LinkLayerAddress
          DHCP = $false
          NetLBFOTeam = $null 
          IPConfiguration = @{}
          NetAdapterVMQ=@{
            Enabled = $false
          }
          NetAdapterQoS = @{
            Enabled = $false
          }
          NetAdapterRSS = @{
            Enabled = $false
          }
          NetAdapterRDMA = @{
            Enabled = $false
          }
          NetAdapterAdvancedProperty = @()
          Driver = @{
            DriverFileName = $interface.DriverFileName
            DriverDate = $interface.DriverDate
            DriverDescription = $interface.DriverDescription
            DriverMajorNdisVersion = $interface.DriverMajorNdisVersion
            DriverMinorNdisVersion = $interface.DriverMinorNdisVersion
            DriverName = $interface.DriverName
            DriverProvider = $interface.DriverProvider
            DriverVersionString = $interface.DriverVersionString
          }
        }
        if ($netLBFO) {
          $netLBFOTeam = $netLBFO | Where-Object {$PSItem.Members -match $interface.Name} | Select-Object -ExpandProperty Name
          if($netLBFOTeam) {
            $interfaceProperties.NetLBFOTeam = $netLBFOTeam
          }
        }
        $interfaceProperties.IPConfiguration = Get-POVFNetIPConfiguration -PSSession $POVFPSSession -InterfaceAlias $interface.Name
        
        if($NetAdapterVMQ) {
          $interfaceProperties.NetAdapterVMQ =@{
            Enabled = $NetAdapterVMQ.Enabled
            BaseProcessorNumber = $NetAdapterVMQ.BaseProcessorNumber
            MaxProcessors = $NetAdapterVMQ.MaxProcessors
          }
        }
        if($NetAdapterQoS) {
          $interfaceProperties.NetAdapterQoS =@{
            Enabled = $NetAdapterQoS.Enabled
          }
        }
        if($NetAdapterRSS.Enabled) {
          $interfaceProperties.NetAdapterRSS =@{
            Enabled = $NetAdapterRSS.Enabled
            Profile = ($NetAdapterRSS.Profile).ToString()
            BaseProcessorNumber =  $NetAdapterRSS.BaseProcessorNumber
            MaxProcessors =  $NetAdapterRSS.MaxProcessors
          }
        }
        if($NetAdapterRDMA) {
          $interfaceProperties.NetAdapterRDMA.Enabled = $NetAdapterRSS.Enabled
        }
        if($NetAdapterAdvancedProperty) {
          $RegistryKeywords = @('*FlowControl','*JumboPacket')
          $interfaceProperties.NetAdapterAdvancedProperty += foreach ($rKey in $RegistryKeywords){
            $output = @{}
            $entry = $NetAdapterAdvancedProperty | Where-Object {$PSItem.RegistryKeyword -eq $rKey}
            $output.RegistryKeyword = $entry.RegistryKeyword
            $output.RegistryValue =  $entry.RegistryValue
            $output
          }
           
        }
        $interfaceProperties
      }
    } 
    #> 
    
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue| Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}
