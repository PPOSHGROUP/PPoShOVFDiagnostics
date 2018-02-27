@{
  Simple = @(
    @{
      DiagnosticFile = "AD.Simple.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'NonNodeData'
      Tag = @('Operational')
    },
    @{
      DiagnosticFile = "AD.Simple.Configuration.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'NonNodeData'
      Tag = @('Configuration')
    }
  )
  Comprehensive = @(
    @{
      DiagnosticFile = "AD.Comprehensive.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Operational')
    }
  )
}