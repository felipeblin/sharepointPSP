# Parámetros de conexión
$siteUrl = "https://socovesa.sharepoint.com/sites/SostenibilidadEmpresasSocovesa-SocovesaSur"
$outputFile = ".\SharePointInventario.csv"
$outputTextFile = ".\EstructuraDirectorio.txt"

# Conectar a SharePoint Online con ClientId
Connect-PnPOnline -Url $siteUrl -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al sitio principal"

# Obtener la lista "Documentos compartidos"
$list = Get-PnPList -Identity "Documentos compartidos"
Write-Host "Obteniendo elementos de la biblioteca: $($list.Title)"

# Obtener todos los elementos
$items = Get-PnPListItem -List $list -Fields "FileLeafRef", "FileRef", "FSObjType", "File_x0020_Size" -PageSize 500

# Crear un hashtable para almacenar la estructura jerárquica
$hierarchy = @{}
$rootItems = @()
$global:inventory = @()
$global:textOutput = @()

# Procesar los elementos y construir la jerarquía
foreach ($item in $items) {
    if ($item["FileRef"] -like "*/Información Sostenibilidad Socochat/*") {
        $path = $item["FileRef"]
        $parentPath = Split-Path -Parent $path
        
        if (-not $hierarchy.ContainsKey($parentPath)) {
            $hierarchy[$parentPath] = @()
        }
        $hierarchy[$parentPath] += $item
        
        if ($parentPath -like "*/Información Sostenibilidad Socochat") {
            $rootItems += $item
        }
    }
}

# Función para crear la indentación
function Get-Indentation {
    param($level)
    return "    " * $level
}

# Función recursiva para procesar la jerarquía
function Process-Items {
    param(
        $parentPath,
        $level
    )
    
    if ($hierarchy.ContainsKey($parentPath)) {
        # Primero procesar las carpetas
        $folders = $hierarchy[$parentPath] | Where-Object { $_["FSObjType"] -eq "1" } | Sort-Object { $_["FileLeafRef"] }
        foreach ($folder in $folders) {
            $indent = Get-Indentation $level
            $folderStructure = "${indent}${indent}└──── 📁 $($folder['FileLeafRef'])"
            
            $global:inventory += [PSCustomObject]@{
                Estructura = $folderStructure
                Nombre = $folder["FileLeafRef"]
                TamañoMB = ""
            }
            
            $global:textOutput += $folderStructure
            Write-Host $folderStructure
            
            Process-Items -parentPath $folder["FileRef"] -level ($level + 1)
        }
        
        # Luego procesar los archivos
        $files = $hierarchy[$parentPath] | Where-Object { $_["FSObjType"] -ne "1" } | Sort-Object { $_["FileLeafRef"] }
        foreach ($file in $files) {
            $indent = Get-Indentation $level
            $tamanio = if ($file["File_x0020_Size"]) { [math]::Round($file["File_x0020_Size"]/1MB, 2) } else { 0 }
            $fileStructure = "${indent}${indent}└────── 📄 $($file['FileLeafRef']) ($tamanio MB)"
            
            $global:inventory += [PSCustomObject]@{
                Estructura = $fileStructure
                Nombre = $file["FileLeafRef"]
                TamañoMB = $tamanio
            }
            
            $global:textOutput += $fileStructure
            Write-Host $fileStructure
        }
    }
}

# Iniciar el procesamiento desde la raíz
$rootPath = "/sites/SostenibilidadEmpresasSocovesa-SocovesaSur/Documentos compartidos/General/Información Sostenibilidad Socochat"
Write-Host "`nEstructura del directorio:`n"
Process-Items -parentPath $rootPath -level 0

if ($global:inventory.Count -gt 0) {
    # Guardar el CSV
    $global:inventory | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    
    # Guardar el archivo de texto
    $global:textOutput | Out-File -FilePath $outputTextFile -Encoding UTF8
    
    Write-Host "`nInventario completado exitosamente."
    Write-Host "CSV guardado en: $outputFile"
    Write-Host "Estructura de árbol guardada en: $outputTextFile"
} else {
    Write-Host "No se encontraron elementos para exportar."
}