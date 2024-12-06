# Definir las variables iniciales
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$UrlProyecto = "proyecto-prueba"
$libraries = @(
    "Proyecto Inmobiliario"
)

# Conectar a SharePoint
try {
    Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
    Write-Host "Conexión establecida exitosamente con SharePoint" -ForegroundColor Green
} catch {
    Write-Host "Error al conectar con SharePoint: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Función para eliminar una biblioteca y su contenido de la papelera
function Remove-LibraryAndCleanup {
    param (
        [string]$LibraryName
    )
    
    try {
        # Verificar si la biblioteca existe
        $library = Get-PnPList -Identity $LibraryName -ErrorAction SilentlyContinue
        
        if ($library) {
            Write-Host "Eliminando biblioteca: $LibraryName..." -ForegroundColor Yellow
            
            # Eliminar la biblioteca
            Remove-PnPList -Identity $LibraryName -Force
            Write-Host "Biblioteca $LibraryName eliminada exitosamente." -ForegroundColor Green
            
            # Limpiar la papelera de reciclaje usando el nuevo comando
            Write-Host "Limpiando elementos de la papelera de reciclaje..." -ForegroundColor Yellow
            $recycleBinItems = Get-PnPRecycleBinItem | Where-Object { $_.LeafName -eq $LibraryName }
            if ($recycleBinItems) {
                $recycleBinItems | ForEach-Object {
                    Clear-PnPRecycleBinItem -Identity $_.Id -Force
                }
            }
            Write-Host "Elementos de la papelera eliminados." -ForegroundColor Green
        } else {
            Write-Host "La biblioteca $LibraryName no existe." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Error al eliminar la biblioteca $LibraryName`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Solicitar confirmación antes de proceder
Write-Host "`nSe eliminarán las siguientes bibliotecas:" -ForegroundColor Yellow
$libraries | ForEach-Object { Write-Host "- $_" -ForegroundColor Cyan }
$confirmation = Read-Host "`n¿Está seguro que desea eliminar estas bibliotecas? (S/N)"

if ($confirmation -eq "S") {
    # Eliminar cada biblioteca
    foreach ($library in $libraries) {
        Remove-LibraryAndCleanup -LibraryName $library
    }
    Write-Host "`nProceso de eliminación completado." -ForegroundColor Green
} else {
    Write-Host "`nOperación cancelada por el usuario." -ForegroundColor Yellow
}

# Desconectar sesión
# Disconnect-PnPOnline
# Write-Host "Sesión de SharePoint finalizada." -ForegroundColor Green