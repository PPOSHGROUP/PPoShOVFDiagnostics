@{
    Name = 'DHCP'
    Diagnostics = @{
        Simple = @(
            @{
                TestName = 'POVF.DHCP.Simple.Tests.ps1'
                Parameters = @('POVFConfiguration','POVFCredential')
            }
        )
        Comprehensive = @(
            @{
                TestName = 'POVF.DHCP.Comprehensive.Tests.ps1'
                Parameters = @('POVFConfiguration','POVFCredential')
            },
            @{
                TestName = 'POVF.DHCP.Scope.Comprehensive.Tests.ps1'
                Parameters = @('POVFPSSession','POVFConfigurationScope')
            },
            @{
                TestName = 'POVF.DHCP.Reservations.Comprehensive.Tests.ps1'
                Parameters = @('POVFPSSession','POVFConfigurationReservations','POVFCurrentReservations')
            }      
        )
    }
}