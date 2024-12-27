

# Conectar a SharePoint
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green

Set-SPWebApplication -Identity "$SitioPrincipal/$UrlProyecto" -AllowCSPHeader $false


# # Define the new CSP directives
# $cspValue = "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://r4.res.office365.com https://js.monitor.azure.com; object-src 'none';"

# # Get current tenant settings
# $tenantSettings = Get-PnPTenantSettings

# # Update the CSP in tenant settings
# $tenantSettings.CSOM.ContentSecurityPolicy = $cspValue

# # Apply the updated settings
# Set-PnPTenantSettings -Settings $tenantSettings

# # Verify the changes
# $updatedSettings = Get-PnPTenantSettings
# Write-Host "Updated CSP:" $updatedSettings.CSOM.ContentSecurityPolicy