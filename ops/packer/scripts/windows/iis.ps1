<powershell>
write-output "Running IIS Script"
write-host "(host) Running IIS Script"

Enable-PSRemoting -Force
Set-ExecutionPolicy RemoteSigned –Force

import-module servermanager

# Is everything lowercase or camelcase? Seen examples for both

add-windowsfeature web-server -includeallsubfeature
# Add-WindowsFeature Web-Server -IncludeAllSubFeature
# Add-WindowsFeature Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Health, Web-Http-Logging, Web-Performance, Web-Stat-Compression, Web-Security, Web-Filtering, Web-App-Dev, Web-Net-Ext, Web-ASP, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Lgcy-Scripting, Web-WMI -IncludeManagementTools

add-windowsfeature net-framework-features, net-framework-core
# Add-WindowsFeature NET-Framework-Features, NET-Framework-Core
</powershell>
