function New-POVFBaselineHyperVSingleNode {
    [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,HelpMessage='Node to test')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$true)]
    [System.String]
    [ValidateScript({Test-Path -Path $PSItem -IsValid})]
    $POVFBaselineHyperVSingleNodeFile
  )

  begin{
    $POVFPSSession = New-PSSessionCustom -ComputerName $ComputerName -Credential $Credential -SessionName "POVF-$ComputerName"
  }
  process{ 
    $NodeConfiguration = @{
        ComputerName = $node
        ClusterName = ''
        Domain = ''
        NIC = @()
        Registry= @()
        Team = @()
        VmSwitch=@()
        Roles = @{
          Present = @()
          Absent = @()
        }
        HyperVConfiguration = @{}
    }
      
      #region NIC
      $NodeConfiguration.NIC += foreach ($netAdapter in (Get-NetAdapter -Physical)){
        Get-POVFNetAdapterConfiguration -InterfaceAlias $netAdapter.Name
      }
      #endregion

      #region
      $NodeConfiguration.NetQoS += Get-POVFNetQosConfiguration -ComputerName $node
      #endregion

      #$NodeConfiguration.Registry += 

      $NodeConfiguration.Team += ''

      $NodeConfiguration.VmSwitch += ''

      $NodeConfiguration.Roles = @{
          Present = @()
          Absent = @()
      }
 

  }
  end{
    Get-PSSession -Name "POVF-$ComputerName" | Remove-PSSession -ErrorAction SilentlyContinue 
  }
}