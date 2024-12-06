$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$NombreProyecto = "Proyecto de Prueba"
$UrlProyecto = "proyecto-prueba"

# Importar y limpiar los datos del CSV
$csvData = Import-Csv "Version Vigente/EstructuraArquitectura3.csv" | ForEach-Object {
    $cleanProperties = @{}
    # Iterar sobre cada propiedad del objeto
    $_.PSObject.Properties | ForEach-Object {
        # Limpiar el valor: eliminar espacios al inicio y final, y asteriscos
        $cleanValue = if ($_.Value) {
            $_.Value.Trim().TrimStart('*').Trim()
        } else {
            ""
        }
        $cleanProperties[$_.Name] = $cleanValue
    }
    # Crear un nuevo objeto con las propiedades limpias
    New-Object PSObject -Property $cleanProperties
}

Write-Host "CSV importado y limpiado exitosamente" -ForegroundColor Green

# $csvData = Import-Csv "Version Vigente/EstructuraArquitectura3.csv"
# Conectar a SharePoint
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green

# Obtener la URL relativa del servidor del sitio web actual
$webUrl = (Get-PnPWeb).ServerRelativeUrl
Write-Host "URL relativa del sitio web: $webUrl" -ForegroundColor Cyan
# Función para asegurar la existencia de un campo
function EnsureField {
    param (
        [string]$ListTitle,
        [string]$FieldName,
        [string]$FieldType
    )
    $field = Get-PnPField -List $ListTitle -Identity $FieldName -ErrorAction SilentlyContinue
    if (-not $field) {
        Write-Host "Creando campo '$FieldName'..." -ForegroundColor Yellow
        $newField = Add-PnPField -List $ListTitle -DisplayName $FieldName -InternalName $FieldName -Type $FieldType -AddToDefaultView
        Write-Host "Campo '$FieldName' creado exitosamente." -ForegroundColor Green
    } else {
        Write-Host "El campo '$FieldName' ya existe." -ForegroundColor Green
    }
}

# Nombre de la biblioteca
$libraryName = "DocEESS"

# Borrar la biblioteca DocEESS si existe
Write-Host "Verificando si existe la biblioteca $libraryName..." -ForegroundColor Cyan
$library = Get-PnPList -Identity $libraryName -ErrorAction SilentlyContinue

if ($library) {
    Write-Host "La biblioteca $libraryName existe. Procediendo a eliminarla..." -ForegroundColor Yellow
    Remove-PnPList -Identity $libraryName -Force
    Write-Host "Biblioteca $libraryName eliminada." -ForegroundColor Green
    
    Write-Host "Eliminando $libraryName de la papelera de reciclaje..." -ForegroundColor Yellow
    Get-PnPRecycleBinItem | Where-Object { $_.LeafName -eq $libraryName } | ForEach-Object {
        Clear-PnPRecycleBinItem -Identity $_ -Force
    }
    Write-Host "$libraryName eliminada de la papelera de reciclaje." -ForegroundColor Green
} else {
    Write-Host "La biblioteca $libraryName no existe." -ForegroundColor Green
}

# Crear la nueva biblioteca
Write-Host "Creando nueva biblioteca $libraryName..." -ForegroundColor Cyan
New-PnPList -Title $libraryName -Template DocumentLibrary
Write-Host "Nueva biblioteca $libraryName creada." -ForegroundColor Green

# Asegurar que los campos necesarios existen
EnsureField -ListTitle $libraryName -FieldName "Categoria" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Subcategoria" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Subcategoria2" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Clase" -FieldType "Text"

# Procesar los datos del CSV
foreach ($row in $csvData) {
    $folderPath = $row.SUBCATEGORIA
    if ($row.SUBCATEGORIA2) {
        $folderPath += "/$($row.SUBCATEGORIA2)"
    }
    Write-Host "Procesando: $folderPath" -ForegroundColor Cyan

    # Crear carpetas
    $folders = $folderPath -split "/"
    $currentPath = $libraryName
    $metadata = @{
        "Categoria" = $row.CATEGORIA
        "Clase" = $row.CLASE  # Agregar el campo Clase aquí
    }

    foreach ($folder in $folders) {
        $currentPath += "/$folder"
        $folderExists = Get-PnPFolder -Url $currentPath -ErrorAction SilentlyContinue
        if (-not $folderExists) {
            $parentPath = $currentPath.Substring(0, $currentPath.LastIndexOf('/'))
            Write-Host "Creando carpeta: $folder en $parentPath" -ForegroundColor Yellow
     #       try {
                $newfolder =Add-PnPFolder -Name $folder -Folder $parentPath
                Write-Host "Carpeta '$folder' creada exitosamente." -ForegroundColor Green
                
                # Agregar metadatos
                $folderItem = Get-PnPFolder -Url $currentPath
                $folderItem.ListItemAllFields.Context.Load($folderItem.ListItemAllFields)
                $folderItem.ListItemAllFields.Context.ExecuteQuery()

                # Determinar qué metadatos agregar basado en el nivel de la carpeta
                if ($folders.IndexOf($folder) -eq 0) { # Nivel de Subcategoría
                    $metadata["Subcategoria"] = $row.SUBCATEGORIA
                } elseif ($folders.IndexOf($folder) -eq 1) { # Nivel de Subcategoría2
                    $metadata["Subcategoria2"] = $row.SUBCATEGORIA2
                }
                try {
                    # Aplicar todos los metadatos acumulados hasta este punto
                    $setMeta = Set-PnPListItem -List $libraryName -Identity $folderItem.ListItemAllFields.Id -Values $metadata

                    Write-Host "Metadatos agregados para la carpeta '$folder': $($metadata | ConvertTo-Json -Compress)" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error al actualizar metadatos para la carpeta '$folder': $($_.Exception.Message)" + "\n Al intentar:\n Metadatos agregados para la carpeta '$folder': $($metadata | ConvertTo-Json -Compress)" -ForegroundColor Red
                }
                
#            } catch {
                # Write-Host "Error al crear la carpeta '$folder' o agregar metadatos: $($_.Exception.Message)" -ForegroundColor Red
                # Write-Host "Ruta padre: $parentPath" -ForegroundColor Red
                # Write-Host "Ruta completa intentada: $currentPath" -ForegroundColor Red
                continue
   #         }
        } else {
            Write-Host "La carpeta '$folder' ya existe. Actualizando metadatos..." -ForegroundColor Yellow
            try {
                $folderItem = Get-PnPFolder -Url $currentPath
                $folderItem.ListItemAllFields.Context.Load($folderItem.ListItemAllFields)
                $folderItem.ListItemAllFields.Context.ExecuteQuery()

                # Actualizar metadatos para carpetas existentes
                $metaAct = Set-PnPListItem -List $libraryName -Identity $folderItem.ListItemAllFields.Id -Values $metadata
                Write-Host "Metadatos actualizados para la carpeta '$folder': $($metadata | ConvertTo-Json -Compress)" -ForegroundColor Green
            } catch {
                Write-Host "Error al actualizar metadatos para la carpeta '$folder': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
# Después de crear la biblioteca DocEESS, agregar al menú de navegación
$navigationNode = Get-PnPNavigationNode -Location QuickLaunch | Where-Object {$_.Title -eq "DocEESS"}

if (-not $navigationNode) {
   Add-PnPNavigationNode -Location QuickLaunch -Title "DocEESS" -Url "$webUrl/DocEESS"
   Write-Host "DocEESS agregado al menú lateral" -ForegroundColor Green
} else {
   Write-Host "DocEESS ya existe en el menú lateral" -ForegroundColor Yellow
}


# Crear una vista más simple pero efectiva
try {
    $listName = "DocEESS"
    $viewName = 'Estructurada'

    # Verificar si la vista existe y eliminarla
    $existingView = Get-PnPView -List $listName -Identity $viewName -ErrorAction SilentlyContinue
    if ($existingView) {
        #Remove-PnPView -List $listName -Identity $viewName -Force
        Write-Host "Vista anterior no eliminada" -ForegroundColor Yellow
    }
    else {
        # Crear la nueva vista
        $view = Add-PnPView -List $listName `
            -Title $viewName `
            -Fields $proyectoFields `
            -SetAsDefault `
            -Query "<OrderBy><FieldRef Name='ID' Ascending='FALSE'/></OrderBy>" 
        
        $view = Get-PnPView -List  $listName -Identity $viewName
        # $view.ViewType = "GALLERY"
    
        Write-Host "Vista básica creada exitosamente" -ForegroundColor Green
    }   
    # Aplicar el formato
    Set-PnPView -List $listName -Identity $viewName -Values @{
        CustomFormatter = @\' 
            {"$schema": "https://developer.microsoft.com/json-schemas/sp/v2/tile-formatting.schema.json",
                "height": 120,
                "width": 150,
                "hideSelection": false,
                "fillHorizontally": true,
                "formatter": {
                "elmType": "div",
                "attributes": {
                    "class": "sp-card-container"
                },
                "children": [
                    {
                    "elmType": "div",
                    "attributes": {
                        "class": "sp-card-defaultClickButton"
                    },
                    "customRowAction": {
                        "action": "defaultClick"
                    }
                    },
                    {
                    "elmType": "div",
                    "attributes": {
                        "class": "ms-bgColor-white sp-css-borderColor-neutralLight sp-card-borderHighlight sp-card-subContainer"
                    },
                    "children": [
                        {
                        "elmType": "div",
                        "attributes": {
                            "class": "sp-card-displayColumnContainer"
                        },
                        "children": [
                            {
                            "elmType": "div",
                            "attributes": {
                                "class": "sp-card-imageContainer"
                            },
                            "children": [
                                {
                                "elmType": "img",
                                "attributes": {
                                    "src": "=if([$Clase] == 'PERMISOS', '/sites/PruebaPSP/SiteAssets/briefing.png', if([$Clase] == 'INMOBILIARIOS', '/sites/PruebaPSP/SiteAssets/inventory.png', if([$Clase] == 'VERSIÓN OBRA', '/sites/PruebaPSP/SiteAssets/completed-task.png', if([$Clase] == 'DOC COM', '/sites/PruebaPSP/SiteAssets/project-management.png', ''))))",
                                    "title": "[$Clase]"
                                },
                                "style": {
                                    "width": "50px",
                                    "height": "50px",
                                    "margin": "0 auto",
                                    "color": "#0078d4"
                                }
                                }
                            ]
                            },
                            {
                            "elmType": "p",
                            "attributes": {
                                "class": "ms-fontColor-neutralPrimary sp-card-content sp-card-highlightedContent sp-card-keyboard-focusable"
                            },
                            "style": {
                                "text-align": "center",
                                "font-size": "11 px"
                            },
                            "txtContent": "[$FileLeafRef]",
                            "defaultHoverField": "[$FileLeafRef]"
                            },
                            {
                            "elmType": "p",
                            "attributes": {
                                "class": "ms-fontColor-neutralSecondary sp-card-label"
                            },
                            "style": {
                                "text-align": "center",
                                "font-size": "11 px"
                            },
                            "txtContent": "[$Clase]"
                            }
                        ]
                        }
                    ]
                    }
                ]
                }
            }
        \'@
    }
    
    # @{
    #     CustomFormatter = $formatoJson
    # }

    Write-Host "Formato aplicado exitosamente" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}