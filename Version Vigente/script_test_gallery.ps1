
$yaml_ = Get-Content -Path "$PSScriptRoot/config.yaml"| ConvertFrom-Yaml
#$yaml_ = ConvertFrom-Yaml -Yaml $yamlContent
# $SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
# $NombreProyecto = "Proyecto de Prueba"
#$UrlProyecto = "proyecto-prueba"
$SitioPrincipal = $yaml_.Datos.SitioPrincipal
$NombreProyecto = $yaml_.Datos.NombreProyecto
$UrlProyecto = $yaml_.Datos.UrlProyecto
$IdProyecto = $yaml_.Datos.IdProyecto
$Marca = $yaml_.Datos.Marca
$Comuna = $yaml_.Datos.Comuna
# Conectar a SharePoint
# VARIABLES BÁSICAS
# Añade la línea que prefieras, por ejemplo la estable:

#Remove-Module PnP.PowerShell -Force
#Import-Module PnP.PowerShell -RequiredVersion 2.12.0 -Force
#Get-Module -Name PnP.PowerShell | Select-Object Name, Version
$siteUrl   = "https://socovesa.sharepoint.com/sites/PSP-EESS/proyecto-prueba-4"
$listName  = "DocEESS"
$viewName  = "vistaTest2"

# 1. Crear la vista si no existe (tipo HTML = moderna)
$view = Get-PnPView -List $listName -Identity $viewName -ErrorAction SilentlyContinue
if (-not $view) {
    $view = Add-PnPView -List $listName -Title $viewName -ViewType Html
}

# 2. Convertirla en diseño Gallery y dejarla por defecto
Set-PnPView -List $listName -Identity $view.Id -Values @{
    ViewType2   = "TILES"
    DefaultView = $true
}
Get-PnPView -List "DocEESS" | Select Title, ViewType2, DefaultView 
# Connect-PnPOnline -Url $siteUrl -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
# Write-Host "Conectado exitosamente al nuevo subsitio $siteUrl" -ForegroundColor Green


# $payload = @{
#   __metadata   = @{ type = 'SP.View' }
#   Title        = 'Vista-Galería'
#   ViewTypeKind = 1
#   ViewType2    = 'GALLERY'
#   DefaultView  = $true
# } | ConvertTo-Json -Depth 10 -Compress

# Invoke-PnPSPRestMethod `
#   -Url "/_api/web/lists/GetByTitle('$listName')/Views/Add" `
#   -Method POST `
#   -Content $payload `                       # <-- aquí
#   -ContentType "application/json;odata=verbose"

#Disconnect-PnPOnline