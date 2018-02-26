@{
    Simple = @(
        @{
            DiagnosticFile = "$PSScriptRoot\..\Diagnostics\AD\Simple\AD.Simple.Operational.Tests.ps1"
            Parameters = @('POVFConfiguration','POVFCredential')
            Configuration = 'NonNodeData'
            Tag = @('Operational')
         },
         @{
            DiagnosticFile = "$PSScriptRoot\..\Diagnostics\AD\Simple\AD.Simple.Configuration.Tests.ps1"
            Parameters = @('POVFConfiguration','POVFCredential')
            Configuration = 'NonNodeData'
            Tag = @('Configuration')
         }
    )
    Comprehensive = @(
        @{
            DiagnosticFile = "$PSScriptRoot\..\Diagnostics\AD\Comprehensive\AD.Comprehensive.Operational.Tests.ps1"
            Parameters = @('POVFConfiguration','POVFCredential')
            Configuration = 'AllNodes'
            Tag =@()
         }
    )
}