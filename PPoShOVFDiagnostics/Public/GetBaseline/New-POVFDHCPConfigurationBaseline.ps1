function New-POVFDHCPConfigurationBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,HelpMessage='Folder for baseline Configuration folder structure',
            ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [ValidateScript({Test-Path -Path $_ -PathType Container -IsValid})]
        [System.String]
        $POVFConfigurationFolder,

        [Parameter(Mandatory=$false,
            ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Credential()][System.Management.Automation.PSCredential]
        $Credential
    )
    process{
        New-Item -Path $POVFConfigurationFolder -ItemType Directory -ErrorAction SilentlyContinue
        $serviceConfigurationFile = 'DHCP.ServiceConfiguration.psd1'
        




        #region Get data for $serviceConfiguration
        $dhcpFromAD = @(Get-DhcpServerInDC | Select-Object -ExpandProperty DNSName)
        if($dhcpFromAD) {
            $serviceConfiguration = @"
@{
    DHCPServers = @($($dhcpFromAD -join ','))
}
"@
        }
        $serviceConfiguration | Out-File (Join-Path -Path $POVFConfigurationFolder -ChildPath $serviceConfigurationFile )
        #endregion
        foreach ($node in $dhcpFromAD) {
            $nodePSSession = New-POVFRemoteSession -ComputerName $node -Credential $Credential
            $nodeConfig = Invoke-Command -Session $nodePSSession -ScriptBlock {
                $dhcpServerDatabase = Get-DhcpServerDatabase
                $dhcpserverDNSCredential =  Get-DhcpServerDnsCredential
                $dhcpserverDNSCredentialString = "{0}\{1}" -f $dhcpserverDNSCredential.DomainName, $dhcpserverDNSCredential.Username
                @{
                    DHCPServerDNSCredentials = $dhcpserverDNSCredentialString
                    Binding = (Get-DhcpServerv4Binding).IPAddress.IPAddressToString
                    ServerSettings = @{
                        BackupInterval = $dhcpServerDatabase.BackupInterval
                        CleanupInterval = $dhcpServerDatabase.CleanupInterval
                        LoggingEnabled = $dhcpServerDatabase.LoggingEnabled
                    }
                    AuditLog = ('${0}' -f (Get-DhcpServerAuditLog).Enable)
                }      
            }
            $nodeFolderName = (($node).Split('.') | Select-Object -First 1).ToString().ToUpper()
            $nodeFolder = New-Item -Path $POVFConfigurationFolder -Name $nodeFolderName -ItemType Directory
            $nodeConfig
            $nodeConfiguration = @"
@{
    ComputerName = $node
    DHCPServerDNSCredentials = $($nodeConfig.DHCPServerDNSCredentials)
    Binding = $($nodeConfig.Binding)
    ServerSettings = @{
        BackupInterval = $($nodeConfig.ServerSettings.BackupInterval)
        CleanupInterval = $($nodeConfig.ServerSettings.CleanupInterval)
        LoggingEnabled = $$($nodeConfig.ServerSettings.LoggingEnabled)
    }
    AuditLog = $$($nodeConfig.AuditLog)
}            
"@
            $nodeConfiguration | Out-File (Join-Path -Path $nodeFolder -ChildPath $serviceConfigurationFile )


            $reservationFolder = New-Item -Path $nodeFolder -Name 'Reservations' -ItemType Directory


            $scopeFolder = New-Item -Path $nodeFolder -Name 'Scopes' -ItemType Directory
        }


    }
}