# Save as: AD_Enum.ps1
# Run in PowerShell on a domain-joined system

Write-Host "==== AS-REP Roastable Accounts ====" -ForegroundColor Cyan
$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.Filter = "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
$searcher.PropertiesToLoad.Add("samaccountname") | Out-Null
$results = $searcher.FindAll()
foreach ($res in $results) { $res.Properties.samaccountname }

Write-Host "`n==== Unconstrained Delegation (Computers) ====" -ForegroundColor Cyan
$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.Filter = "(&(userAccountControl:1.2.840.113556.1.4.803:=524288)(objectCategory=computer))"
$searcher.PropertiesToLoad.Add("dnshostname") | Out-Null
$results = $searcher.FindAll()
foreach ($res in $results) { $res.Properties.dnshostname }

Write-Host "`n==== Constrained Delegation (Computers with AllowedToDelegateTo) ====" -ForegroundColor Cyan
$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.Filter = "(&(msds-allowedtodelegateto=*)(objectCategory=computer))"
$searcher.PropertiesToLoad.Add("dnshostname") | Out-Null
$searcher.PropertiesToLoad.Add("msds-allowedtodelegateto") | Out-Null
$results = $searcher.FindAll()
foreach ($res in $results) {
    $name = $res.Properties.dnshostname
    $deleg = $res.Properties."msds-allowedtodelegateto"
    Write-Host "$name -> $deleg"
}

Write-Host "`n==== Domain Admins ====" -ForegroundColor Cyan
try {
    ([ADSI]"WinNT://$env:USERDOMAIN/Domain Admins,group").psbase.Invoke("Members") | 
    ForEach-Object { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
} catch {
    Write-Host "Couldn't retrieve Domain Admins. Likely due to lack of rights." -ForegroundColor Yellow
}

Write-Host "`n==== Enterprise Admins ====" -ForegroundColor Cyan
try {
    ([ADSI]"WinNT://$env:USERDOMAIN/Enterprise Admins,group").psbase.Invoke("Members") | 
    ForEach-Object { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
} catch {
    Write-Host "Couldn't retrieve Enterprise Admins. Likely due to lack of rights." -ForegroundColor Yellow
}

Write-Host "`n==== Logged-in User on This Machine ====" -ForegroundColor Cyan
try {
    $loggedInUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName
    Write-Host $loggedInUser
} catch {
    Write-Host "Could not determine logged-in user." -ForegroundColor Yellow
}
