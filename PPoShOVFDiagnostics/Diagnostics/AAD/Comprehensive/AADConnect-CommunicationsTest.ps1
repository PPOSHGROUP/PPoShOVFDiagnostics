<#
.SYNOPSIS
Test basic connectivity and name resolution for AAD Connect.

.DESCRIPTION
Use this script to test basic network connectivity to on-premises and
online endpoints as well as name resolution.

.PARAMETER AzureCredentialCheck
Check the specified credential for Azure AD suitability (valid password, is a member
of global administrators).

.PARAMETER DCs
Use this parameter to specify DCs to test against. Required if running on-
premises network or DNS tests.  This is auto-populated from the LOGONSERVER
environment variable.  If the server is not joined to a domain, populate this
attribute with a DC for the domain/forest you will be configuration AAD Connect against.

.PARAMETER DebugLogging
Enable debug error logging to log file.

.PARAMETER Dns
Use this parameter to only run on-premises Dns tests. Requires FQDN and DCs parameters
to be specified.

.PARAMETER FixedDcRpcPort
Use this optional parameter to specify a fixed Rpc port for DC communications.  See
https://support.microsoft.com/en-us/help/224196/restricting-active-directory-rpc-traffic-to-a-specific-port
for more information.

.PARAMETER Logfile
Self-explanatory.

.PARAMETER Network
Use this parameter to only run local network tests. Requires FQDN and DCs parameters
to be specified if they are not automatically populated.  They may not be automatically 
populated if the server running this tool has not been joined to a domain.  That is a 
supported configuration; however, you will need to specify a forest FQDN and at least
one DC.

.PARAMETER OnlineEndPoints
Use this parameter to conduct communication tests against online endpoints.

.PARAMETER OnlineEndPointTarget
Use this optional parameter to select GCC, Commercial, DOD, or GCC High environments.

.PARAMETER OptionalADPortTest
Use this optional parameter to specify ports that you may not need for communications.
While the public documentation says port 88 is required for Kerberos, it may not be used
in certain circumstances (such as adding an AD connector to a remote forest after AAD
connect has been intalled).  Optional ports include:
- 88 (Kerberos)
- 636 (Secure LDAP)

You can enable secure LDAP after the AAD Connect installation has completed.

.PARAMETER SkipAzureCredentialCheck
Skip checking the Azure Credential

.PARAMETER SkipDcDnsPortCheck
If you are not using DNS services provided by the AD Site / Logon DC, then you may want
to skip checking port 53.  You must still be able to resolve _.ldap._tcp.<forestfqdn>
in order for the Active Directory Connector configuration to succeed.

.PARAMETER SystemConfiguration
Report on system configuration items, including installed Windows Features, TLS
registry entries and proxy configurations.

.EXAMPLE
.\AADConnect-CommunicationsTest.ps1
Runs all tests and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt)

.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -Dns -Network
Runs Dns and Network tests and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt).

.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -OnlineEndPoints -OnlineEndPointTarget DOD
Runs OnlineEndPoints test using the U.S. Department of Defense online endpoints list
and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt).

.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -AzureCredentialCheck -Network -DCs dc1.contoso.com -ForestFQDN contoso.com
Runs Azure Credential Check and local networking tests using DC dc1.contoso.com and 
the forest contoso.com and writes to the default log file location 
(YYYY-MM-DD_AADConnectivity.txt). 

.LINK 
https://blogs.technet.microsoft.com/undocumentedfeatures/2018/02/10/aad-connect-network-and-name-resolution-test/

.LINK
https://gallery.technet.microsoft.com/Azure-AD-Connect-Network-150c20a3

.NOTES
- 2018-02-14	Added FixedDcRpcPort, OptionalADPortTest, SystemConfiguration parameters
- 2018-02-14	Added test for servicebus.windows.net to online endpoints
- 2018-02-14	Expanded system configuration tests to capture TLS 1.2 configuration
- 2018-02-14	Expanded system configuration tests to capture required server features
- 2018-02-13	Added OnlineEndPointTarget parameter for selecting Commercial, GCC, DOD, or GCC high.
- 2018-02-13	Added proxy config checks.
- 2018-02-12	Added additional CRL/OCSP endpoints for Entrust and Verisign.
- 2018-02-12	Added additional https:// test endpoints.
- 2018-02-12	Added DebugLogging parameter and debug logging data.
- 2018-02-12	Added extended checks for online endpoints.
- 2018-02-12	Added check for Azure AD credential (valid/invalid password, is Global Admin)
- 2018-02-12	Updated parameter check when running new mixes of options.
- 2018-02-11	Added default values for ForestFQDN and DCs.
- 2018-02-11	Added SkipDcDnsPortCheck parameter.
- 2018-02-10	Resolved issue where tests would run twice under some conditions.
- 2018-02-09	Initial release.
#>

param (
	[switch]$AzureCredentialCheck,
	[Parameter(HelpMessage="Specify the azure credential to check in the form of user@domain.com or user@tenant.onmicrosoft.com")]$AzureCredential,
	[array]$DCs = (Get-ChildItem Env:\Logonserver).Value.ToString().Trim("\") + "." + (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString(),
	[switch]$DebugLogging,
	[switch]$Dns,
	[int]$FixedDcRpcPort,
	[string]$ForestFQDN = (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString(),
	[string]$Logfile = (Get-Date -Format yyyy-MM-dd) + "_AADConnectConnectivity.txt",
	[switch]$Network,
	[switch]$OnlineEndPoints,
	[ValidateSet("Commercial","DOD","GCC","GCCHigh")]
	[string]$OnlineEndPointTarget = "Commercial",
	[switch]$OptionalADPortTest,
	[switch]$SkipAzureCredentialCheck,
	[switch]$SkipDcDnsPortCheck,
	[switch]$SystemConfiguration
)

## Functions
# Logging function
function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
{
	$Message = $Message + $Input
	If (!$LogLevel) { $LogLevel = "INFO" }
	switch ($LogLevel)
	{
		SUCCESS { $Color = "Green" }
		INFO { $Color = "White" }
		WARN { $Color = "Yellow" }
		ERROR { $Color = "Red" }
		DEBUG { $Color = "Gray" }
	}
	if ($Message -ne $null -and $Message.Length -gt 0)
	{
		$TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
		if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
		{
			Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
		}
		if ($ConsoleOutput -eq $true)
		{
			Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color
		}
	}
}

# Test Office 365 Credentials
function AzureCredential
{
	If ($SkipAzureCredentialCheck) { "Skipping Azure AD Credential Check due to parameter.";  Continue}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Office 365 global administrator and credential tests."
	If (!$AzureCredential)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Credential required to validate Office 365 credentials. Enter global admin credential."
	}
	# Attempt MSOnline installation
	Try { MSOnline }
	Catch { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to proceed with MSOnline check.  Please install the Microsoft Online Services Module separately and re-run the script." -ConsoleOutput}
	
	# Attempt to log on as user
	try
	{
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting logon as $($Credential.UserName) to Azure Active Directory."
		$LogonResult = Connect-MsolService -Credential $AzureCredential -ErrorAction Stop
		If ($LogonResult -eq $null)
		{
			Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully logged on to Azure Active Directory as $($AzureCredential.UserName)." -ConsoleOutput
			## Attempt to check membership in Global Admins, which is labelled as "Company Administrator" in the tenant
			$RoleId = (Get-MsolRole -RoleName "Company Administrator").ObjectId
			If ((Get-MsolRoleMember -RoleObjectId $RoleId).EmailAddress -match "\b$($AzureCredential.UserName)")
			{
				Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "User $($AzureCredential.Username) is a member of Global Administrators." -ConsoleOutput
			}
			Else
			{
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "User $($AzureCredential.UserName) is not a member of Global Administrators.  In order for Azure Active Directory synchronization to be successful, the user must have the Global Administrators role granted in Office 365.  Grant the appropriate access or select another user account to test."	
			}
		}
		Else
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to verify logon to Azure Active Directory as $($AzureCredential.UserName)." -ConsoleOutput
		}
	}
	catch
	{
		$LogonResultError = $_.Exception
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to log on to Azure Active Directory as $($AzureCredential.UserName).  Check $($Logfile) for additional details." -ConsoleOutput
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($LogonResultError)
	}
} # End Function AzureCredential

# Test for/install MSOnline components
function MSOnline
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Checking Microsoft Online Services Module."
	If (!(Get-Module -ListAvailable MSOnline -ea silentlycontinue))
	{
		# Check if Elevated
		$wid = [system.security.principal.windowsidentity]::GetCurrent()
		$prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
		$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
		if ($prp.IsInRole($adm))
		{
			Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
		}
		else
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This application/script must be run in an elevated PowerShell window. Please launch an elevated session and try again."
			Break
		}
		
		Write-Log -LogFile $Logfile -LogLevel INFO -ConsoleOutput -Message "This requires the Microsoft Online Services Module. Attempting to download and install."
		wget https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi -OutFile $env:TEMP\msoidcli_64.msi
		If (!(Get-Command Install-Module))
		{
			wget https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi -OutFile $env:TEMP\PackageManagement_x64.msi
		}
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Sign-On Assistant." }
		msiexec /i $env:TEMP\msoidcli_64.msi /quiet /passive
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries." }
		msiexec /i $env:TEMP\PackageManagement_x64.msi /qn
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries (NuGet)." }
		Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Confirm:$false
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Microsoft Online Services Module." }
		Install-Module MSOnline -Confirm:$false -Force
		If (!(Get-Module -ListAvailable MSOnline))
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This Configuration requires the MSOnline Module. Please download from https://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185 and try again."
			Break
		}
	}
	Import-Module MSOnline -Force
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Microsoft Online Service Module check."
} # End Function MSOnline

# Test Online Networking Only
function OnlineEndPoints
{
	switch -regex ($OnlineEndPointTarget)
	{
		'commercial|gcc'
		{
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Online Endpoints tests (Commercial/GCC)."
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "See https://support.office.com/en-us/article/office-365-urls-and-ip-address-ranges-8548a211-3fe7-47cb-abb1-355ea5aa88a2"
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "for more details on Commercial/GCC endpoints."
			$CRL = @(
				"http://crl.microsoft.com/pki/crl/products/microsoftrootcert.crl",
				"http://mscrl.microsoft.com/pki/mscorp/crl/msitwww2.crl",
				"http://ocsp.verisign.com",
				"http://ocsp.entrust.net")
			$RequiredResources = @(
				"adminwebservice.microsoftonline.com",
				"login.microsoftonline.com",
				"provisioningapi.microsoftonline.com",
				"login.windows.net",
				"secure.aadcdn.microsoftonline-p.com")
			$RequiredResourcesEndpoints = @(
				"https://adminwebservice.microsoftonline.com/provisioningservice.svc",
				"https://login.microsoftonline.com",
				"https://provisioningapi.microsoftonline.com/provisioningwebservice.svc",
				"https://login.windows.net",
				"https://secure.aadcdn.microsoftonline-p.com/ests/2.1.5975.9/content/cdnbundles/jquery.1.11.min.js")
			$OptionalResources = @(
				"management.azure.com",
				"policykeyservice.dc.ad.msft.net")
			$OptionalResourcesEndpoints = @(
				"https://policykeyservice.dc.ad.msft.net/clientregistrationmanager.svc")
			# Use the AdditionalResources array to specify items that need a port test on a port other
			# than 80 or 443.
			$AdditionalResources = @(
				"watchdog.servicebus.windows.net:5671")
		}
		
		'dod|gcchigh'
		{
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Online Endpoints tests (DOD)."
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "See https://support.office.com/en-us/article/office-365-u-s-government-dod-endpoints-5d7dce60-4892-4b58-b45e-ee42fe8a907f"
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "for more details on DOD/GCCHigh endpoints."
			$CRL = @(
				"https://mscrl.microsoft.com/pki/mscorp/crl/msitwww2.crl",
				"http://crl.microsoft.com/pki/crl/products/microsoftrootcert.crl",
				"http://ocsp.verisign.com",
				"http://ocsp.entrust.net")
			$RequiredResources = @(
				"adminwebservice.gov.us.microsoftonline.com",
				"adminwebservice-s1-bn1a.microsoftonline.com",
				"adminwebservice-s1-dm2a.microsoftonline.com",
				"login.microsoftonline.us",
				"login.microsoftonline.com",
				"login.microsoftonline-p.com",
				"loginex.microsoftonline.com",
				"login-us.microsoftonline.com",
				"login.windows.net",
				"provisioningapi.gov.us.microsoftonline.com",
				"provisioningapi-s1-dm2a.microsoftonline.com",
				"provisioningapi-s1-dm2r.microsoftonline.com",
				"secure.aadcdn.microsoftonline-p.com")
			$RequiredResourcesEndpoints = @(
				"https://adminwebservice.gov.us.microsoftonline.com/provisioningservice.svc",
				"https://adminwebservice-s1-bn1a.microsoftonline.com/provisioningservice.svc",
				"https://adminwebservice-s1-dm2a.microsoftonline.com/provisioningservice.svc",
				"https://login.microsoftonline.us"
				"https://login.microsoftonline.com",
				"https://loginex.microsoftonline.com",
				"https://login-us.microsoftonline.com",
				"https://login.windows.net",
				"https://provisioningapi.gov.us.microsoftonline.com/provisioningwebservice.svc",
				"https://provisioningapi-s1-dm2a.microsoftonline.com/provisioningwebservice.svc",
				"https://provisioningapi-s1-dm2r.microsoftonline.com/provisioningwebservice.svc"
				"https://secure.aadcdn.microsoftonline-p.com/ests/2.1.5975.9/content/cdnbundles/jquery.1.11.min.js")
			<# These endpoints are not listed at this time for DOD/GCCHigh
			$OptionalResources = @(
				"management.azure.com", 
				"policykeyservice.dc.ad.msft.net")
			$OptionalResourcesEndpoints = @(
				"https://policykeyservice.dc.ad.msft.net/clientregistrationmanager.svc")
			# Use the AdditionalResources array to specify items that need a port test on a port other
			# than 80 or 443.
			$AdditionalResources = @(
				"watchdog.servicebus.windows.net:5671")
			#>
		}
	}
	foreach ($url in $CRL)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully obtained CRL from $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to obtain CRL from $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)"
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to obtain CRL from $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent.Substring(0, 400) -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
			}
		}
	} # End Foreach CRL
	
	foreach ($url in $RequiredResources)
	{
		[array]$ResourceAddresses = (Resolve-DnsName $url).IP4Address
		foreach ($ip4 in $ResourceAddresses)
		{
			try
			{
				$Result = Test-NetConnection $ip4 -Port 443 -ea stop -wa silentlycontinue
				switch ($Result.TcpTestSucceeded)
				{
					true { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful." -ConsoleOutput }
					false { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput }
				}
			}
			catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($Error)
			}
			finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		}
	} # End Foreach Resources
	
	foreach ($url in $OptionalResources)
	{
		[array]$OptionalResourceAddresses = (Resolve-DnsName $url).IP4Address
		foreach ($ip4 in $OptionalResourceAddresses)
		{
			try
			{
				$Result = Test-NetConnection $ip4 -Port 443 -ea stop -wa silentlycontinue
				switch ($Result.TcpTestSucceeded)
				{
					true { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful." -ConsoleOutput }
					false {
						Write-Log -LogFile $Logfile -LogLevel WARN -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
						If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $($Result) }
					}
				}
			}
			catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel WARN -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel WARN -Message $($ErrorMessage)
			}
			finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		}
	} # End Foreach OptionalResources
	
	foreach ($url in $RequiredResourcesEndpoints)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
				}
			}
		}
	} # End Foreach RequiredResourcesEndpoints
	
	foreach ($url in $OptionalResourcesEndpoints)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
				}
			}
		}
	} # End Foreach RequiredResourcesEndpoints
	
	If ($AdditionalResources)
	{
		foreach ($url in $AdditionalResources)
		{
			if ($url -match "\:")
			{
				$Name = $url.Split(":")[0]
				[array]$Resources = (Resolve-DnsName $Name).Ip4Address
				$ResourcesPort = $url.Split(":")[1]
			}
			Else
			{
				$Name = $url
				[array]$Resources = (Resolve-DnsName $Name).IP4Address
				$ResourcesPort = "443"
			}
			foreach ($ip4 in $Resources)
			{
				try
				{
					$Result = Test-NetConnection $ip4 -Port $ResourcesPort -ea stop -wa silentlycontinue
					switch ($Result.TcpTestSucceeded)
					{
						true { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Name) [$($ip4)]:$($ResourcesPort) successful." -ConsoleOutput }
						false {
							Write-Log -LogFile $Logfile -LogLevel WARN -Message "TCP connection to $($Name) [$($ip4)]:$($ResourcesPort) failed." -ConsoleOutput
							If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $($Result) }
						}
					}
				}
				catch
				{
					$ErrorMessage = $_
					Write-Log -LogFile $Logfile -LogLevel WARN -Message "Error resolving or connecting to $($Name) [$($ip4)]:$($ResourcesPort)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel WARN -Message $($ErrorMessage)
				}
				finally
				{
					If ($DebugLogging)
					{
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Name) [$($Result.RemoteAddress)]:443."
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Name)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
						Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
					}
				}
			}
		} # End ForEach AdditionalResources
	} # End IF AdditionalResources
	
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Online Endpoints tests."
} # End Function OnlineEndPoints

# Test Local Networking Only
function Network
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local network port tests."
	If (!$DCs)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "If testing on-premises networking, you must specify at least one on-premises domain controller." -ConsoleOutput
		Break
	}
	Foreach ($Destination in $DCs)
	{
		foreach ($Port in $Ports)
		{
			Try
			{
				$Result = (Test-NetConnection -ComputerName $Destination -Port $Port -ea Stop -wa SilentlyContinue)
				Switch ($Result.TcpTestSucceeded)
				{
					True
					{
						Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Destination):$($Port) succeeded." -ConsoleOutput
					}
					False
					{
						Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($Destination):$($Port) failed." -ConsoleOutput
						Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$Result"
					}
				} # End Switch
			}
			Catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting TCP connection to $($Destination):$($Port)." -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $ErrorMessage
			}
			Finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Destination) [$($Result.RemoteAddress)]:$($Port)."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Destination)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		} # End Foreach Port in Ports
		foreach ($Port in $OptionalADPorts)
		{
			Try
			{
				$Result = (Test-NetConnection -ComputerName $Destination -Port $Port -ea Stop -wa SilentlyContinue)
				Switch ($Result.TcpTestSucceeded)
				{
					True
					{
						Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Destination):$($Port) succeeded." -ConsoleOutput
					}
					False
					{
						Write-Log -LogFile $Logfile -LogLevel WARN -Message "TCP connection to $($Destination):$($Port) failed." -ConsoleOutput
						Write-Log -LogFile $Logfile -LogLevel WARN -Message "$Result"
					}
				} # End Switch
			}
			Catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error attempting TCP connection to $($Destination):$($Port)." -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $ErrorMessage
			}
			Finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Destination) [$($Result.RemoteAddress)]:$($Port)."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Destination)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		} # End Foreach Port in OptionalADPorts
		
	} # End Foreach Destination
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local network port tests."
} # End Function Network

# Test local DNS resolution for domain controllers
function Dns
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local DNS resolution tests."
	If (!$ForestFQDN)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local Dns resolution, you must specify for Active Directory Forest FQDN." -ConsoleOutput
		Break
	}
	
	If (!$DCs)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local DNS resolution testing requires the DCs parameter to be specified." -ConsoleOutput
		Break
	}
	# Attempt DNS Resolution
	$DnsTargets = @("_ldap._tcp.$ForestFQDN") + $DCs
	Foreach ($HostName in $DnsTargets)
	{
		Try
		{
			$DnsResult = (Resolve-DnsName -Type ANY $HostName -ea Stop -wa SilentlyContinue)
			If ($DnsResult.Name)
			{
				Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully resolved $($HostName)." -ConsoleOutput
			}
			Else
			{
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error attempting DNS resolution for $($HostName)." -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $DnsResult
			}
		}
		Catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting DNS resolution for $($HostName)." -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $ErrorMessage
		}
		Finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($HostName)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DnsResult
			}
		}
	}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local DNS resolution tests."
} # End function Dns

function SystemConfiguration
{
	## Show system configuration
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting system configuration gathering."
	# Netsh WinHTTP proxy
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "WinHTTP proxy settings (netsh winhttp show proxy):"
	$WinHTTPProxy = (netsh winhttp show proxy)
	$WinHTTPProxy = ($WinHTTPProxy -join " ").Trim()
	Write-Log -LogFile $Logfile -LogLevel INFO -Message $WinHTTPProxy
	
	# .NET Proxy
	Write-Log -LogFile $Logfile -LogLevel INFO -Message ".NET proxy configuration"
	[xml]$machineconfig = gc $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config
	if (!$machineconfig.configuration.'system.net')
	{
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "No proxy configuration exists in $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config."
	}
	else
	{
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "The following proxy configuration exists in $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config."
		$nodes = $machineconfig.SelectNodes('/configuration/system.net/defaultProxy/child::node()')
		Write-Log -Logfile $Logfile -LogLevel INFO -Message "UseSystemDefault: $($nodes.usesystemdefault)"
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "ProxyAddress: $($nodes.proxyaddress)"
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "BypassOnLocal $($nodes.bypassonlocal)"
	}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "For more .NET proxy configuration parameters, see https://docs.microsoft.com/en-us/dotnet/framework/configure-apps/file-schema/network/proxy-element-network-settings"
	
	# Server Features parameters
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting to check installed features."
	If (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)
	{
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "Command available. Checking installed features."
		$ServerFeatures = Get-WindowsFeature | ? {
			$_.Name -eq 'Server-Gui-Mgmt-Infra' -or
			$_.Name -eq 'Server-Gui-Shell'
			$_.Name -eq 'NET-Framework-45-Features'
			$_.Name -eq 'NET-Framework-45-Core'
		}
		foreach ($Feature in $ServerFeatures)
		{
			
			switch ($Feature.IsInstalled)
			{
				Installed { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Required feature $($Feature.DisplayName) [$($Feature.Name)] is installed." }
				Available { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Required feature $($Feature.DisplayName) [$($Feature.Name)] is not installed." }
			} # End Switch FeatureIsInstalled
		} # End Foreach Feature
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished checking installed features."
	} # End Server Feaatures
	Else { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Command not available. Unable to check installed features." }
	
	# Check for TLS capabilities
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Checking for TLS 1.2 configuration."
	$Keys = @'
HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client,DisabledByDefault,reg_dword,0
HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client,Enabled,reg_dword,1
HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server,DisabledByDefault,reg_dword,0
HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server,Enabled,reg_dword,1
HKLM:SOFTWARE\Microsoft\.NETFramework\v4.0.30319,SchUseStrongCrypto,reg_dword,1
'@ -split "`n" | % { $_.trim() }
	
	$KeysArray = @()
	Foreach ($line in $Keys)
	{
		[array]$linedata = $line.Split(",")
		$KeyData = New-Object PSObject
		$KeyData | Add-Member -MemberType NoteProperty -Name "Path" -Value $LineData[0]
		$KeyData | Add-Member -MemberType NoteProperty -Name "Item" -Value $LineData[1]
		$KeyData | Add-Member -MemberType NoteProperty -Name "Type" -Value $LineData[2]
		$KeyData | Add-Member -MemberType NoteProperty -Name "Value" -Value $LineData[3]
		$KeysArray += $KeyData
	}
	
	foreach ($Key in $KeysArray)
	{
		try
		{
			$Result = (Get-ItemProperty -error SilentlyContinue $Key.Path).$($Key.Item).ToString()
			If ($Result)
			{
				If ($Result -match $Key.Value)
				{
					Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) with a value of $($Key.Value) is set correctly for TLS 1.2 Configuration."
				}
				Else
				{
					Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) with a value of $($Key.Value) is not set correctly for TLS 1.2 Configuration."
					
				}
			}
			Else
			{
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) not found."	
			}
		}
		Catch
		{
			Write-Log -LogFile $Logfile -LogLevel INFO -Message "Exception or $($Key.Path)\$($Key.Item) not found."
		}
	}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished checking for TLS 1.2 Configuration settings."
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished gathering system configuration."
} # End Function System Configuration

## Begin script
Write-Log -LogFile $Logfile -LogLevel INFO -Message "========================================================="
Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting AAD Connect connectivity and resolution testing."

# If SkipDcDnsPortCheck is enabled, remove 53 from the list of ports to test on DCs
If ($SkipDcDnsPortCheck) { $Ports = @('135', '389', '445', '3268') }
Else { $Ports = @('53', '135', '389', '445', '3268') }

# Use this switch if a statically configured Rpc port for AD traffic has been configured
# on the target DC.  This port may be called for Password Hash Sync configuration.
If ($FixedDcRpcPort)
{
	$Ports += $FixedDcRpcPort
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Port $($FixedDcRpcPort) will be tested as part of the DC/local network test."
	If ($DebugLogging)
	{
		Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "For more information on configuring a fixed RPC port for DC communications, please see"
		Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "https://support.microsoft.com/en-us/help/224196/restricting-active-directory-rpc-traffic-to-a-specific-port"
	}
}

# Use the OptionalADPortTest switch to add the following ports: 88, 636
If ($OptionalADPortTest) { $OptionalADPorts += @('88', '636') }

# List modifier parameters to exclude from switch statement.  These are the parameters that should not affect which tests are run.
$Excluded = @(
	'debuglogging',
	'logfile',
	'optionaladporttest',
	'forestfqdn',
	'dcs',
	'fixeddcrpcport')
[regex]$ParametersToExclude = '(?i)^(\b' + (($Excluded | foreach { [regex]::escape($_) }) –join "\b|\b") + '\b)$'
$Params = $PSBoundParameters.Keys | ? { $_ -notmatch $ParametersToExclude }
If ($Params)
{
	switch -regex ($Params)
	{
		'\bazurecredentialcheck\b' { AzureCredential }
		'\bdns\b' { Dns }
		'\bnetwork\b|\bdcs\b|\bfixedrpcport\b|\boptionaladporttest\b' { Network }
		'onlineendpoint' { OnlineEndPoints }
		'\bsystemconfiguration\b' { SystemConfiguration }
	}
}
else
{
	"Running all tests."
	AzureCredential; Dns; Network; OnlineEndPoints; SystemConfiguration
}
Write-Log -LogFile $Logfile -LogLevel INFO -Message "Done! Logfile is $($Logfile)." -ConsoleOutput
Write-Log -LogFile $Logfile -LogLevel INFO -Message "---------------------------------------------------------"