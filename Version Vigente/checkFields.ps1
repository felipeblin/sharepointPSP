# Connect to SharePoint
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$UrlProyecto = "proyecto-prueba"

Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

# Define field configurations
$proyectoFields = @(
    @{Name="Zona"; Type="Text"},
    @{Name="Superficie Neta"; Type="Number"},
    @{Name="Superficie Vendible"; Type="Number"},
    @{Name="Total Construido"; Type="Number"},
    @{Name="Constructibilidad Usada"; Type="Number"},
    @{Name="Incidencia"; Type="Number"},
    @{Name="Unidades"; Type="Number"},
    @{Name="Estacionamientos Vendibles"; Type="Number"},
    @{Name="Bodegas"; Type="Number"},
    @{Name="Costo Directo"; Type="Currency"},
    @{Name="Costo Terreno"; Type="Currency"},
    @{Name="Margen IFRS"; Type="Number"},
    @{Name="Ingreso Total"; Type="Currency"},
    @{Name="TIR"; Type="Number"},
    @{Name="Inmobiliaria"; Type="Text"},
    @{Name="Centro Costo"; Type="Text"},
    @{Name="Rol Matriz"; Type="Text"},
    @{Name="Firma Planos"; Type="DateTime"},
    @{Name="Permiso Edificacion"; Type="DateTime"},
    @{Name="Inicio Excavacion"; Type="DateTime"},
    @{Name="Inicio Ventas"; Type="DateTime"},
    @{Name="Resolucion Recepcion"; Type="DateTime"},
    @{Name="Entrega Departamentos"; Type="DateTime"}
)

function Ensure-Field {
    param (
        [string]$ListName,
        [string]$FieldName,
        [string]$FieldType
    )
    
    try {
        $field = Get-PnPField -List $ListName -Identity $FieldName -ErrorAction SilentlyContinue
        if (-not $field) {
            Write-Host "Creando campo '$FieldName'..." -ForegroundColor Yellow
            Add-PnPField -List $ListName -DisplayName $FieldName -InternalName ($FieldName -replace ' ', '_') -Type $FieldType
            Write-Host "Campo '$FieldName' creado exitosamente." -ForegroundColor Green
        } else {
            Write-Host "Campo '$FieldName' ya existe." -ForegroundColor Green
        }
    } catch {
        Write-Host "Error creando campo '$FieldName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

$listName = "Proyecto Inmobiliario"
foreach ($field in $proyectoFields) {
    Ensure-Field -ListName $listName -FieldName $field.Name -FieldType $field.Type
}

try {
    $viewName = "Vista Formulario"
    $fieldNames = $proyectoFields | ForEach-Object { $_.Name }
    
    $existingView = Get-PnPView -List $listName -Identity $viewName -ErrorAction SilentlyContinue
    if ($existingView) {
        Remove-PnPView -List $listName -Identity $viewName -Force
        Write-Host "Vista anterior eliminada exitosamente" -ForegroundColor Yellow
    }
    
    Add-PnPView -List $listName `
        -Title $viewName `
        -Fields $fieldNames `
        -SetAsDefault `
        -Query "<OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>" `
        -RowLimit 30
    
    Write-Host "Vista creada exitosamente" -ForegroundColor Green
    
} catch {
    Write-Host "Error creando vista: $($_.Exception.Message)" -ForegroundColor Red
}