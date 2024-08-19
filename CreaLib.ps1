# Conectar a SharePoint
try {
    Write-Host "Conectando a SharePoint..." -ForegroundColor Cyan
    Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive
    Write-Host "Conexión exitosa." -ForegroundColor Green
} catch {
    Write-Host "Error al conectar a SharePoint: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Nombre de la biblioteca
$libraryName = "Documentos del Proyecto"

# Usar el directorio actual como ruta local
$localPath = Get-Location

# Arreglo de nombres de archivos para subir
$filesToUpload = @(
    "APIsTable-4.xlsx",
    "SolicitudAccesoDatos.pdf"
)

# Función para generar metadatos aleatorios
function Get-RandomMetadata {
    $estados = @("En curso", "Completado", "Aplazada", "No iniciada")
    $tiposDocumento = @("Inmobiliario", "Arquitectura", "Técnico", "Comercial", "ODI")
    $comentarios = @("Revisión pendiente", "Aprobado por gerencia", "Requiere modificaciones", "Versión final", "En proceso de revisión")

    return @{
        "Estado" = $estados | Get-Random
        "Comentario" = $comentarios | Get-Random
        "TipoDocumento" = $tiposDocumento | Get-Random
    }
}

# Función para subir un archivo con metadatos
function Upload-FileToSharePoint($fileName) {
    $filePath = Join-Path $localPath $fileName
    if (Test-Path $filePath) {
        try {
            Write-Host "Intentando subir $fileName..." -ForegroundColor Cyan
            $metadata = Get-RandomMetadata
            $file = Add-PnPFile -Path $filePath -Folder $libraryName -Values $metadata
            Write-Host "Archivo $fileName subido exitosamente con los siguientes metadatos:" -ForegroundColor Green
            $metadata.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Green }
            
            # Verificar que los metadatos se hayan aplicado correctamente
            $uploadedFile = Get-PnPFile -Url $file.ServerRelativeUrl -AsListItem
            Write-Host "Metadatos verificados del archivo subido:" -ForegroundColor Cyan
            $uploadedFile.FieldValues | Where-Object { $_.Key -in "Estado", "Comentario", "TipoDocumento" } | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Host "Error al subir $fileName : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "El archivo $fileName no se encuentra en el directorio actual." -ForegroundColor Yellow
    }
}

# Verificar si la biblioteca existe y sus columnas
Write-Host "Verificando si la biblioteca '$libraryName' existe y sus columnas..." -ForegroundColor Cyan
$library = Get-PnPList -Identity $libraryName -Includes Fields
if ($null -eq $library) {
    Write-Host "La biblioteca '$libraryName' no existe. Por favor, crea la biblioteca primero." -ForegroundColor Red
    exit
}

# Verificar y crear campos si no existen
$requiredFields = @("Estado", "Comentario", "TipoDocumento")
foreach ($fieldName in $requiredFields) {
    if ($null -eq $library.Fields | Where-Object { $_.InternalName -eq $fieldName }) {
        Write-Host "Creando campo $fieldName..." -ForegroundColor Yellow
        if ($fieldName -eq "Estado") {
            Add-PnPField -List $libraryName -DisplayName $fieldName -InternalName $fieldName -Type Choice -Choices "En curso", "Completado", "Aplazada", "No iniciada"
        } else {
            Add-PnPField -List $libraryName -DisplayName $fieldName -InternalName $fieldName -Type Text
        }
    } else {
        Write-Host "Campo $fieldName ya existe." -ForegroundColor Green
    }
}

Write-Host "Biblioteca '$libraryName' y sus campos verificados." -ForegroundColor Green

# Subir cada archivo en el arreglo
foreach ($file in $filesToUpload) {
    Upload-FileToSharePoint $file
}

Write-Host "Proceso de carga de archivos completado." -ForegroundColor Cyan

# La conexión se mantiene abierta, no se desconecta
Write-Host "Script completado. La conexión a SharePoint se mantiene abierta." -ForegroundColor Green