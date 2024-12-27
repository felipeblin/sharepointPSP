$yaml_ = Get-Content -Path "$PSScriptRoot/config.yaml"| ConvertFrom-Yaml -ErrorAction Stop
#$yaml_ = ConvertFrom-Yaml -Yaml $yamlContent
# $SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
# $NombreProyecto = "Proyecto de Prueba"
#$UrlProyecto = "proyecto-prueba"
$SitioPrincipal = $yaml_.Datos.SitioPrincipal
$NombreProyecto = $yaml_.Datos.NombreProyecto
$UrlProyecto = $yaml_.Datos.UrlProyecto
$IdProyecto = $yaml_.Datos.IdProyecto
$Marca = $yaml_.Datos.Marca
$Comuna = $yaml_.Datos.Comuna

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
        [string]$FieldType,
        [bool]$InDefaultView = $true,
        [string[]]$ChoiceValues = @(),
        [string]$InternalName = $null
    )
    $field = Get-PnPField -List $ListTitle -Identity $FieldName -ErrorAction SilentlyContinue
    if ($InternalName -eq $null -or $InternalName -eq "") {
        $InternalName = $FieldName
    }
    if (-not $field) {
        Write-Host "Creando campo '$FieldName'..." -ForegroundColor Yellow
        if ($FieldType -eq "Choice") {
            $newField = Add-PnPField -List $ListTitle -DisplayName $FieldName -InternalName $InternalName -Type $FieldType -Choices $ChoiceValues -AddToDefaultView:$InDefaultView
        } else {
            $newField = Add-PnPField -List $ListTitle -DisplayName $FieldName -InternalName $InternalName -Type $FieldType -AddToDefaultView
        }
        # $newField = Add-PnPField -List $ListTitle -DisplayName $FieldName -InternalName $FieldName -Type $FieldType -AddToDefaultView
        Write-Host "Campo '$FieldName' con Nombre interno '$InternalName' creado exitosamente." -ForegroundColor Green
    } else {
        Write-Host "El campo '$FieldName' ya existe." -ForegroundColor Green
    }
}

function Add-StatusToggleButton {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ListTitle,
        
        [Parameter(Mandatory = $true)]
        [string]$FieldInternalName,
        
        [Parameter(Mandatory = $false)]
        [string]$Status1 = "En Revisión",
        
        [Parameter(Mandatory = $false)]
        [string]$Status2 = "Aprobado",
        
        [Parameter(Mandatory = $false)]
        [string]$ButtonLabel = "Cambiar Estado"
    )

    # try {

        # Get the list ID
        $list = Get-PnPList -Identity $ListTitle
        $listId = $list.Id

        # Create the JavaScript function
        $scriptBlock = @"
function toggleEstado() {
    var context = SP.ClientContext.get_current();
    var list = context.get_web().get_lists().getByTitle('$ListTitle');
    var selectedItems = SP.ListOperation.Selection.getSelectedItems(context);
    
    for (var i in selectedItems) {
        var itemId = selectedItems[i].id;
        var listItem = list.getItemById(itemId);
        
        context.load(listItem, '$FieldInternalName');
        context.executeQueryAsync(
            function() {
                var currentStatus = listItem.get_item('$FieldInternalName');
                var newStatus = (currentStatus === '$Status1') ? '$Status2' : '$Status1';
                
                listItem.set_item('$FieldInternalName', newStatus);
                listItem.update();
                context.executeQueryAsync(
                    function() { 
                        location.reload(); 
                    },
                    function(sender, args) { 
                        alert('Error updating status: ' + args.get_message()); 
                    }
                );
            },
            function(sender, args) {
                alert('Error loading item: ' + args.get_message());
            }
        );
    }
}
"@

    # }
    # catch {
    #     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    # }
}

# Función para asegurar la existencia de un campo calculado

function EnsureCalculatedField {
    param (
        [string]$ListTitle,
        [string]$FieldName
    )
    
    $field = Get-PnPField -List $ListTitle -Identity $FieldName -ErrorAction SilentlyContinue
    if (-not $field) {
        Write-Host "Creando campo calculado '$FieldName'..." -ForegroundColor Yellow
        
        $schemaXml = @"
 <Field ID='{$(New-Guid)}' 
       Type='Calculated' 
       DisplayName='$FieldName' 
       Name='$FieldName' 
       Group='Custom Columns'
       ResultType='Number'>
    <Formula>=Count([Title])</Formula>
    <FieldRefs>
        <FieldRef Name='Title'/>
    </FieldRefs>
 </Field>
"@
 
        try {
            $newCalculated = Add-PnPFieldFromXml -List $ListTitle -FieldXml $schemaXml
            Write-Host "Campo calculado '$FieldName' creado exitosamente." -ForegroundColor Green
            
            $defaultView = Get-PnPView -List $ListTitle | Where-Object { $_.DefaultView -eq $true }
            $fields = $defaultView.ViewFields + $FieldName
            $seteado = Set-PnPView -List $ListTitle -Identity $defaultView.Id -Fields $fields
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
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
$existingLibrary = Get-PnPList -Identity $libraryName -ErrorAction SilentlyContinue
if ($existingLibrary) {
    Write-Host "La biblioteca $libraryName ya existe." -ForegroundColor Yellow

} else {
    New-PnPList -Title $libraryName -Template DocumentLibrary
    Write-Host "Nueva biblioteca $libraryName creada." -ForegroundColor Green
}
# Agregar campo calculado para contar archivos en carpetas
$calculatedFormula = "=COUNTA([FileLeafRef])"  # Fórmula para contar archivos
EnsureCalculatedField -ListTitle $libraryName `
    -FieldName "ConteoArchivos" `
    -Formula $calculatedFormula `
    -FieldType "Number"

Write-Host "Campo calculado 'ConteoArchivos' creado exitosamente o ya existente." -ForegroundColor Green
# Asegurar que los campos necesarios existen
EnsureField -ListTitle $libraryName -FieldName "Categoria" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Subcategoria" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Subcategoria2" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Clase" -FieldType "Text"
EnsureField -ListTitle $libraryName -FieldName "Estado Documentos" -InternalName "EstadoDocumentos" -FieldType "Choice" -ChoiceValues @("En Revisión", "Aprobada") 


$EditListItems = "ViewListItems, AddListItems, EditListItems,BrowseDirectories"
# Create the custom action
# Link the JavaScript file
# Add-PnPJavaScriptLink -Name "ToggleEstadoScript" `
#     -Url "$SitioPrincipal/SiteAssets/toggleEstado.js" `
#     -Sequence 1000 `
#     -Scope Web

# # Add the custom action for the button
# Add-PnPCustomAction -Name "ToggleEstado" `
#     -Title "Cambiar Estado" `
#     -Location "CommandUI.Ribbon" `
#     -RegistrationType List `
#     -Description "Button to toggle document status" `
#     -Group "SiteActions" `
#     -Rights @("EditListItems") `
#     -Scope Web `
#     -CommandUIExtension @"
#     <CommandUIExtension>
#     <CommandUIDefinitions>
#     <CommandUIDefinition Location="Ribbon.ListItem.Actions.Controls._children">
#         <Button 
#             Id="Ribbon.ListItem.ToggleEstado"
#             Command="ToggleEstado"
#             Image32by32="/_layouts/15/images/placeholder32x32.png"
#             LabelText="Cambiar Estado"
#             Description="Toggle between En Revisión and Aprobado"
#             TemplateAlias="o1" />
#     </CommandUIDefinition>
#     </CommandUIDefinitions>
#     <CommandUIHandlers>
#     <CommandUIHandler
#         Command="ToggleEstado"
#         CommandAction="javascript:toggleEstado();" />
#     </CommandUIHandlers>
#     </CommandUIExtension>
# "@

# Write-Host "Button successfully added to the list!" -ForegroundColor Green

# # Basic usage with minimum required parameters
# Add-StatusToggleButton `
#     -ListTitle $libraryName `
#     -FieldInternalName "EstadoDocumentos"

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
                try {
                    $newfolder =Add-PnPFolder -Name $folder -Folder $parentPath
                    Write-Host "Carpeta '$folder' creada exitosamente." -ForegroundColor Green
                }
                catch {
                    Write-Host "Error al crear la carpeta '$folder': $($_.Exception.Message)" -ForegroundColor Red
                }
                
                
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
                    # After successfully setting folder metadata, set default column values
                        try {
                            # Get the relative folder path from the current path
                            $relativeFolder = $currentPath.Replace("$libraryName/", "")
                            
                            # Set default column values for the current folder
                            foreach ($key in $metadata.Keys) {
                                Set-PnPDefaultColumnValues -List $libraryName -Field $key -Value $metadata[$key] -Folder $relativeFolder
                            }
                            Write-Host "Default column values set for folder '$folder'" -ForegroundColor Green
                        } catch {
                            Write-Host "Error setting default column values for folder '$folder': $($_.Exception.Message)" -ForegroundColor Red
                        }

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
