$modules = "UniversalDashboard", "DnsServer", "ActiveDirectory", "PKI"
foreach ($m in $modules) {
  if (-not (Get-Module $m -ListAvailable)) {
    Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force
  }
}
