# Conexión a SharePoint
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$UrlProyecto = "proyecto-prueba"

Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

try {
    $itemProperties = @{
        "Title" = "Proyecto Test 2024"
        "Zona" = "Santiago Centro"
        "SuperficieNeta" = 5000
        "SuperficieVendible" = 4500
        "TotalConstruido" = 12000
        "ConstructibilidadUsada" = 3.5
        "Incidencia" = 0.25
        "Unidades" = 120
        "EstacionamientosVendibles" = 130
        "Bodegas" = 80
        "CostoDirecto" = 850000
        "CostoTerreno" = 450000
        "MargenIFRS" = 0.18
        "IngresoTotal" = 1500000
        "TIR" = 0.15
        "Inmobiliaria" = "Socovesa Santiago"
        "CentroCosto" = "CC-2024-001"
        "RolMatriz" = "123-456"
        "FirmaPlanos" = "2024-03-15"
        "PermisoEdificacion" = "2024-04-01"
        "InicioExcavacion" = "2024-05-15"
        "InicioVentas" = "2024-06-01"
        "ResolucionRecepcion" = "2026-05-01"
        "EntregaDepartamentos" = "2026-06-01"
    }

    Add-PnPListItem -List "Proyecto Inmobiliario" -Values $itemProperties
    Write-Host "Registro de prueba insertado exitosamente" -ForegroundColor Green

} catch {
    Write-Host "Error al insertar el registro: $($_.Exception.Message)" -ForegroundColor Red
}