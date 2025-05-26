# Conectar a SharePoint
try {
    Write-Host "Conectando a SharePoint..." -ForegroundColor Cyan
    Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive
    Write-Host "Conexión exitosa." -ForegroundColor Green
} catch {
    Write-Host "Error al conectar a SharePoint: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

$yaml_ = Get-Content -Path "$PSScriptRoot/config.yaml"| ConvertFrom-Yaml
$ArchivoCSV = $yaml_.Datos.ArchivoCSV

# Obtener la URL relativa del servidor del sitio web actual
$webUrl = (Get-PnPWeb).ServerRelativeUrl
Write-Host "URL relativa del sitio web: $webUrl" -ForegroundColor Cyan

# Crear biblioteca y campos de metadatos
$listTitle = "DocEESS"
Write-Host "Verificando si la biblioteca '$listTitle' existe..." -ForegroundColor Cyan
$existingList = Get-PnPList -Identity $listTitle -ErrorAction SilentlyContinue
if (-not $existingList) {
    Write-Host "Creando biblioteca de documentos '$listTitle'..." -ForegroundColor Yellow
    New-PnPList -Title $listTitle -Template DocumentLibrary -OnQuickLaunch
    Write-Host "Biblioteca '$listTitle' creada exitosamente." -ForegroundColor Green
} else {
    Write-Host "La biblioteca '$listTitle' ya existe." -ForegroundColor Green
}

# Función para crear campo si no existe
function EnsureField {
    param (
        [string]$ListTitle,
        [string]$FieldName,
        [string]$FieldType
    )
    $field = Get-PnPField -List $ListTitle -Identity $FieldName -ErrorAction SilentlyContinue
    if (-not $field) {
        Write-Host "Creando campo '$FieldName'..." -ForegroundColor Yellow
        Add-PnPField -List $ListTitle -DisplayName $FieldName -InternalName $FieldName -Type $FieldType -AddToDefaultView
        Write-Host "Campo '$FieldName' creado exitosamente." -ForegroundColor Green
    } else {
        Write-Host "El campo '$FieldName' ya existe." -ForegroundColor Green
    }
}

Write-Host "Verificando y creando campos de metadatos 'Clase' y 'TipoDocumento2'..." -ForegroundColor Cyan
EnsureField -ListTitle $listTitle -FieldName "Clase" -FieldType "Text"
EnsureField -ListTitle $listTitle -FieldName "TipoDocumento2" -FieldType "Text"

# Leer CSV
$csvPath = "$PSScriptRoot/$ArchivoCSV"
Write-Host "Leyendo archivo CSV: $csvPath" -ForegroundColor Cyan
$csvData = Import-Csv -Path $csvPath
Write-Host "Archivo CSV leído exitosamente. Procesando $(($csvData | Measure-Object).Count) filas." -ForegroundColor Green

foreach ($row in $csvData) {
    $folderPath = "$($row.CATEGORIA)/$($row.SUBCATEGORIA)"
    if ($row.SUBCATEGORIA2) {
        $folderPath += "/$($row.SUBCATEGORIA2)"
    }
    Write-Host "Procesando carpeta: $folderPath" -ForegroundColor Cyan

    # Crear carpetas
    $folders = $folderPath -split "/"
    $currentPath = "$listTitle"
    foreach ($folder in $folders) {
        $currentPath += "/$folder"
        $folderExists = Get-PnPFolder -Url $currentPath -ErrorAction SilentlyContinue
        if (-not $folderExists) {
            $parentPath = $currentPath.Substring(0, $currentPath.LastIndexOf('/'))
            Write-Host "Intentando crear carpeta: $folder en $parentPath" -ForegroundColor Yellow
            try {
                Add-PnPFolder -Name $folder -Folder $parentPath
                Write-Host "Carpeta '$folder' creada exitosamente." -ForegroundColor Green
            } catch {
                Write-Host "Error al crear la carpeta '$folder': $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Ruta padre: $parentPath" -ForegroundColor Red
                Write-Host "Ruta completa intentada: $currentPath" -ForegroundColor Red
                # Continuar con la siguiente iteración
                continue
            }
        } else {
            Write-Host "La carpeta '$folder' ya existe." -ForegroundColor Green
        }
    }

    # Asignar metadatos
    $leafFolder = $folders[-1]
    $folderItem = Get-PnPFolder -Url $currentPath | Select-Object -ExpandProperty ListItemAllFields
    if ($folderItem) {
        Write-Host "Asignando metadatos a la carpeta: $leafFolder" -ForegroundColor Yellow
        try {
            Set-PnPListItem -List $listTitle -Identity $folderItem.Id -Values @{ "Clase" = $row.CLASE; "TipoDocumento2" = $row.'TIPO DOCUMENTO'}
            Write-Host "Metadatos asignados exitosamente a '$leafFolder'." -ForegroundColor Green
        } catch {
            
            Write-Host "Error al asignar metadatos a '$leafFolder': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Advertencia: No se pudo encontrar el elemento de lista para la carpeta: $currentPath" -ForegroundColor Red
    }
}

# ... [El resto del script permanece igual]

# Desconectar de SharePoint
Write-Host "Desconectando de SharePoint..." -ForegroundColor Cyan
Disconnect-PnPOnline
Write-Host "Desconexión exitosa. Script completado." -ForegroundColor Green