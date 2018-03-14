@{
  Simple = @(
    @{
      DiagnosticFile = "S2D.Simple.Cluster.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'NonNodeData'
      Tag = @('Operational')
    }
  )
  Comprehensive = @(
    @{
      DiagnosticFile = "S2D.Comprehensive.Nodes.Operational.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Operational')
    },
    @{
      DiagnosticFile = "S2D.Comprehensive.Nodes.Configuration.Tests.ps1"
      Parameters = @('POVFConfiguration','POVFCredential')
      Configuration = 'AllNodes'
      Tag =@('Configuration','Basic','Registry','NetQoS','Teaming','VMSwitch','Roles','Hyper-V')
    }
  )
}