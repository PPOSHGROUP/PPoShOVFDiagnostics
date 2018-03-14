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
      Configuration = 'AllNodes'
      Tag = @('Operational')
    }
  )
  Comprehensive = @(
    @{
      DiagnosticFile = "DHCP.Comprehensive.Node.Configuration.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Service','Scope','Configuration')
    },
    @{
      DiagnosticFile = "DHCP.Comprehensive.Node.Reservations.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Reservation','Configuration')
    }
  )
}