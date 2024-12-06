# Conectar a SharePoint (asegúrate de que estás conectado primero)
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$UrlProyecto = "proyecto-prueba"

Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

# Definir los campos que queremos mostrar
$proyectoFields = @(
    "Zona",
    "Superficie Neta",
    "Superficie Vendible",
    "Total Construido",
    "Constructibilidad Usada",
    "Incidencia",
    "Unidades",
    "Estacionamientos Vendibles",
    "Bodegas",
    "Costo Directo",
    "Costo Terreno",
    "Margen IFRS",
    "Ingreso Total",
    "TIR",
    "Inmobiliaria",
    "Centro ZonaCosto",
    "Rol Matriz",
    "Firma de Planos",
    "Permiso de Edificación",
    "Inicio Excavación",
    "Inicio de Ventas",
    "Resolución Recepción",
    "Entrega Departamentos"
)

# Crear una vista más simple pero efectiva
try {
    $listName = "Proyecto Inmobiliario"
    $viewName = "Vista Formulario"

    # Verificar si la vista existe y eliminarla
    $existingView = Get-PnPView -List $listName -Identity $viewName -ErrorAction SilentlyContinue
    if ($existingView) {
        Remove-PnPView -List $listName -Identity $viewName -Force
        Write-Host "Vista anterior eliminada" -ForegroundColor Yellow
    }

    # Crear la nueva vista
    $view = Add-PnPView -List $listName `
        -Title $viewName `
        -Fields $proyectoFields `
        -SetAsDefault `
        -Query "<OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>" `
        -RowLimit 30

    Write-Host "Vista básica creada exitosamente" -ForegroundColor Green

    # Aplicar un formato JSON más simple para probar
    $simpleFormat = @"
{
    "hideSelection": true,
    "hideColumnHeader": true,
    "formatter": {
        "elmType": "div",
        "style": {
            "padding": "10px"
        },
        "children": [
            {
                "elmType": "div",
                "style": {
                    "display": "flex",
                    "flex-direction": "column",
                    "gap": "10px"
                },
                "children": [
                    {
                        "elmType": "div",
                        "txtContent": "=@currentField.displayName + ': ' + @currentField"
                    }
                ]
            }
        ]
    }
}
"@

    # Aplicar el formato
    Set-PnPView -List $listName -Identity $viewName -Values @{
        CustomFormatter = $simpleFormat
    }

    Write-Host "Formato aplicado exitosamente" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}