function Get-POVFDHCPNodeScopeConfiguration {
  [CmdletBinding()]
  param (

    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ScopeID,

    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [string]
    $ConfigurationName,

    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession


  )
  process{
    #region Variables set
    if($PSBoundParameters.ContainsKey('ComputerName')) {
      $sessionParams = @{
        ComputerName = $ComputerName
        SessionName = "POVF-$ComputerName"
      }
      if($PSBoundParameters.ContainsKey('ConfigurationName')){
        $sessionParams.ConfigurationName = $ConfigurationName
      }
      if($PSBoundParameters.ContainsKey('Credential')){
        $sessionParams.Credential = $Credential
      }
      $POVFPSSession = New-PSSessionCustom @SessionParams
    }
    if($PSBoundParameters.ContainsKey('PSSession')){
      $POVFPSSession = $PSSession
    }
    if($PSBoundParameters.ContainsKey('ScopeID')){
      $dhcpServerV4Scope = Invoke-Command -Session $POVFPSSession -ScriptBlock {
        Get-DhcpServerv4Scope -ScopeId $ScopeID
      }
    }
    else {
      $dhcpServerV4Scope = Invoke-Command -Session $POVFPSSession -ScriptBlock {
        Get-DhcpServerv4Scope
      }
    }
    #endregion
    if($dhcpServerV4Scope){
        foreach($scope in $dhcpServerV4Scope) {
          $exclusionRange = Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-DhcpServerv4ExclusionRange -ScopeId $USING:scope.ScopeID
          }
          $exlusionsResults = @()
          if($exclusionRange){
            $exlusionsResults += foreach ($eRange in $exclusionRange) {
              @{
                StartRange = $eRange.StartRange.IPAddressToString
                EndRange = $eRange.EndRange.IPAddressToString
              }
            }
          }
          $scopeOptions = Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-DhcpServerv4OptionValue -ScopeId $USING:scope.ScopeID
          }
          $optionsResults =@()
          $optionsResults += foreach ($sOption in $scopeOptions) {
            [ordered]@{
              Name = $sOption.Name
              OptionID = $sOption.OptionID
              Value = $sOption.Value
            }
          }
          [ordered]@{
            ScopeID = $scope.ScopeID.IPAddressToString
            Name = $scope.Name
            Description = $scope.Description
            State = $scope.State
            SuperScopeName = $scope.SuperScopeName
            SubnetMask = $scope.SubnetMask.IPAddressToString
            StartRange = $scope.StartRange.IPAddressToString
            EndRange = $scope.EndRange.IPAddressToString
            LeaseDuration = $scope.LeaseDuration.ToString()
            ScopeOptions = $optionsResults
            ExclusionRange = $exlusionsResults
            NapEnable = $scope.NapEnable
            NapProfile = $scope.NapProfile
          }
        }
      }
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue
    }
  }
}