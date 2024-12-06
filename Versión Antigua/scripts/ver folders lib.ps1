# Asegúrate de estar conectado a SharePoint primero
# Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive

$listTitle = "DocEESS"

function Get-FolderStructure {
    param (
        [string]$FolderUrl,
        [int]$Level = 0
    )

    $folders = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderUrl -ItemType Folder

    foreach ($folder in $folders) {
        $indent = "  " * $Level
        Write-Host "$indent|- $($folder.Name)" -ForegroundColor Cyan

        # Obtener y mostrar los metadatos de la carpeta
        $folderItem = Get-PnPListItem -List $listTitle -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>$($folder.Name)</Value></Eq></Where></Query></View>"
        if ($folderItem) {
            $clase = $folderItem["Clase"]
            $tipoDocumento = $folderItem["TipoDocumento2"]
            Write-Host "$indent   Clase: $clase, Tipo Documento: $tipoDocumento" -ForegroundColor Yellow
        }

        # Llamada recursiva para subcarpetas
        Get-FolderStructure -FolderUrl "$FolderUrl/$($folder.Name)" -Level ($Level + 1)
    }
}

# Iniciar la exploración desde la raíz de la biblioteca
Write-Host "Estructura de carpetas de $listTitle" -ForegroundColor Green
Get-FolderStructure -FolderUrl $listTitle