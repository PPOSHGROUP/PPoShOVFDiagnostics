function Get-POVFNetAdapterConfiguration {
    [CmdletBinding()]
    param (
        
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [System.String[]]
      $InterfaceAlias
    
    
      
    )
    begin{
    }
    process {
      foreach ($interface in $InterfaceAlias){
        $netAdapter = Get-NetAdapter -InterfaceAlias $interface
        if($netAdapter){ 
          $netLBFO = Get-NetLbfoTeam -ErrorAction SilentlyContinue 
          $NetAdapterVMQ = Get-NetAdapterVMQ -Name $netAdapter.Name -ErrorAction SilentlyContinue 
          $NetAdapterQoS = Get-NetAdapterQoS -Name $netAdapter.Name -ErrorAction SilentlyContinue
          $NetAdapterRSS = Get-NetAdapterRSS -Name $netAdapter.Name -ErrorAction SilentlyContinue 
          $NetAdapterRDMA = Get-NetAdapterRDMA -Name $netAdapter.Name -ErrorAction SilentlyContinue 
          $NetAdapterAdvancedProperty = Get-NetAdapterAdvancedProperty -Name $netadapter.Name
          $interfaceProperties = @{}  
          $interfaceProperties = [ordered]@{
            MACAddress = $netadapter.LinkLayerAddress
            Name = $netAdapter.Name    
            DHCP = $false
            NetLBFOTeam = $null
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
              DriverFileName = $netAdapter.DriverFileName
              DriverDate = $netAdapter.DriverDate
              DriverDescription = $netAdapter.DriverDescription
              DriverMajorNdisVersion = $netAdapter.DriverMajorNdisVersion
              DriverMinorNdisVersion = $netAdapter.DriverMinorNdisVersion
              DriverName = $netAdapter.DriverName
              DriverProvider = $netAdapter.DriverProvider
              DriverVersionString = $netAdapter.DriverVersionString
            }
          }
          if ($netLBFO) {
            $netLBFOTeam = $netLBFO | Where-Object {$PSItem.Members -match $netAdapter.Name} | Select-Object -ExpandProperty Name
          }
          if($netLBFOTeam) {
            $interfaceProperties.NetLBFOTeam= $netLBFOTeam
          }
          $interfaceProperties.IPConfiguration =  Get-POVFNetIPConfiguration -InterfaceAlias $netadapter.Name
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
            $interfaceProperties.NetAdapterAdvancedProps += foreach ($rKey in $RegistryKeywords){
              $output = @{}
              $entry = $NetAdapterAdvancedProperty |Where-Object {$PSItem.RegistryKeyword -eq $rKey}
              $output.RegistryKeyword = $entry.RegistryKeyword
              $output.RegistryValue =  $entry.RegistryValue
              $output
            }
           
          }
          $interfaceProperties
        } 
      }
    }
  }