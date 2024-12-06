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
    $estados = @("Pendiente", "En Progreso", "Completado")
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
        }
        catch {
            Write-Host "Error al subir $fileName : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "El archivo $fileName no se encuentra en el directorio actual." -ForegroundColor Yellow
    }
}

# Verificar si la biblioteca existe
Write-Host "Verificando si la biblioteca '$libraryName' existe..." -ForegroundColor Cyan
$startTime = Get-Date
$timeout = New-TimeSpan -Minutes 2
$library = $null

while ($null -eq $library -and ((Get-Date) - $startTime) -lt $timeout) {
    try {
        $library = Get-PnPList -Identity $libraryName -ErrorAction Stop
    }
    catch {
        Write-Host "No se pudo verificar la biblioteca. Reintentando..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}

if ($null -eq $library) {
    Write-Host "No se pudo verificar la existencia de la biblioteca '$libraryName' después de 2 minutos. Por favor, verifica la conexión y el nombre de la biblioteca." -ForegroundColor Red
    exit
}

Write-Host "Biblioteca '$libraryName' encontrada." -ForegroundColor Green

# Subir cada archivo en el arreglo
foreach ($file in $filesToUpload) {
    Upload-FileToSharePoint $file
}

Write-Host "Proceso de carga de archivos completado." -ForegroundColor Cyan

# Desconectar de SharePoint
#Disconnect-PnPOnline
#Write-Host "Desconectado de SharePoint." -ForegroundColor Green