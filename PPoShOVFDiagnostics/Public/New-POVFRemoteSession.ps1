function New-POVFRemoteSession {
    param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline,ValueFromPipelineByPropertyName)]
        $ComputerName,

        [Parameter(Mandatory=$false,
    ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [System.Management.Automation.Credential()][System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory=$false,
    ValueFromPipeline,ValueFromPipelineByPropertyName)]
         $ConfigurationName
    )
    process { 
    $sessionParams = @{ 
        ComputerName = $ComputerName
      }
    #if($PSBoundParameters.ContainsKey('ConfigurationName')){
        #$sessionParams.ConfigurationName = $ConfigurationName
    #}
      if($PSBoundParameters.ContainsKey('Credential')){
        $sessionParams.Credential = $Credential
        Write-Log -Info -Message "Will use {$($Credential.UserName)} to create PSSession to computer {$($sessionParams.ComputerName)}"
      }
      else{
        Write-Log -Info -Message "Will use current user Credential {$($ENV:USERNAME)} to create PSSession to computer {$($sessionParams.ComputerName)}"
      }
      $Session = New-PSSession @sessionParams -ErrorAction SilentlyContinue
      if ($Session) { 
        Write-Log -Info -Message "Created PSSession to computer {$($Session.ComputerName)}"
      }
      else {
        Write-Log -Error -Message "Unable to create PSSession to computer {$(Session.ComputerName)}. Aborting!"
        break
      }
      $Session
    } 
}