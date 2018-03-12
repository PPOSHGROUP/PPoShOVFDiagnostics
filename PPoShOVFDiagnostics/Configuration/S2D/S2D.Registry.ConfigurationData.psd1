@{
    $ClusterRegistryEntries = @(
        
    )
    $NoderegistryEntries = @(
      @{ 
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\spaceport\Parameters'
        Name ='HwTimeout'
        Value = '0x00002710'
      }
    )
}