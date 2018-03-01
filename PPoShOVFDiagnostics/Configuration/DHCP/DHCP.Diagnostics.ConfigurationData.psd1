@{
  Simple = @(
    @{
      DiagnosticFile = "DHCP.Simple.Node.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag = @('Operational')
    },
    @{
      DiagnosticFile = "DHCP.Simple.General.Operational.Tests.ps1"
      Parameters = @('POVFCredential')
      Configuration = 'NonNodeData'
      Tag = @('Operational')
    }
  )
  Comprehensive = @(
    @{
      DiagnosticFile = "DHCP.Comprehensive.Node.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Operational')
    }
  )
}