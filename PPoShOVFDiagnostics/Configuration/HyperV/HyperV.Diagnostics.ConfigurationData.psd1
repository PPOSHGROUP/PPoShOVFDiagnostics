@{
  Simple = @(
    @{
      DiagnosticFile = "HyperV.Simple.Node.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag = @('Operational')
    }
  )
  Comprehensive = @(
    @{
      DiagnosticFile = "HyperV.Comprehensive.Node.Configuration.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Configuration','Basic','Registry','NetQoS','Teaming','VMSwitch','Roles','Hyper-V')
    }
  )
}