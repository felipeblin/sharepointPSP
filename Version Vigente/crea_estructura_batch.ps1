Get-Module PnP.PowerShell
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
# Rutas y archivos
$YamlPath = "$PSScriptRoot/config.yaml"
$CsvPath  = "$PSScriptRoot/EstructuraArquitectura3.csv"

# 1. Cargar YAML
$yml = ConvertFrom-Yaml (Get-Content $YamlPath -Raw)
$SiteURL  = "$($yml.Datos.SitioPrincipal)/$($yml.Datos.UrlProyecto)"
$ListName = "DocEESS"

# 2. Conexión (app-only; ajusta credenciales)
Connect-PnPOnline -Url $SiteURL  -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green
#---------------- 2. ELIMINAR BIBLIOTECA SI YA EXISTE ----------------------
$list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
if ($list) {
    Write-Host "La biblioteca '$ListName' existe; eliminando..." -ForegroundColor Yellow
    Remove-PnPList -Identity $ListName -Force

    # opcional: vaciar papelera para no dejar restos
    Get-PnPRecycleBinItem | Where-Object { $_.Title -eq $ListName } |
        Clear-PnPRecycleBinItem -Force
}

#---------------- 3. CREAR BIBLIOTECA -------------------------------------
Write-Host "Creando biblioteca '$ListName'..." -ForegroundColor Yellow
New-PnPList -Title $ListName -Template DocumentLibrary | Out-Null

#---------------- 4. CAMPOS (tus helpers) ----------------------------------
EnsureField -ListTitle $ListName -FieldName "Categoria"      -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "Subcategoria"   -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "Subcategoria2"  -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "Clase"          -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "TipoDocumento"  -FieldType "Text"

EnsureField -ListTitle $ListName -FieldName "Estado Documentos" `
            -InternalName "EstadoDocumentos" -FieldType "Choice" `
            -ChoiceValues @("En Revisión","Aprobado")

EnsureField -ListTitle $ListName -FieldName "ProyectoID"     -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "ProyectoNombre" -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "Marca"          -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "Comuna"         -FieldType "Text"
EnsureField -ListTitle $ListName -FieldName "ShowDetails"    -FieldType "Boolean"

EnsureCalculatedField -ListTitle $ListName -FieldName "ConteoArchivos"

# ------------------------------------------------------------------------
# 5. Crear TODA la estructura y asignar metadatos
#    - Resolve-PnPFolder crea cada nivel que falte (evita “File Not Found”)
#    - Set-PnPListItem se manda en lote → pocas llamadas
#    - Contadores para ver progreso
# ------------------------------------------------------------------------

$data       = Import-Csv $CsvPath
$totalItems = $data.Count
$carpetasNuevas = 0
$metaEnCola    = 0
$batchMeta     = New-PnPBatch   # lote SOLO para metadatos

foreach ($row in $data) {
    # ---- 1. limpiar y tomar columnas obligatorias -----------------------
    $cat  = if ($row.CATEGORIA) { $row.CATEGORIA.Trim() } else { "" }
    $sub1 = if ($row.SUBCATEGORIA) { $row.SUBCATEGORIA.Trim() } else { "" }
    $sub2 = if ($row.SUBCATEGORIA2) { $row.SUBCATEGORIA2.Trim() } else { "" }

    if ([string]::IsNullOrEmpty($cat) -or [string]::IsNullOrEmpty($sub1)) { 
        Write-Host "Saltando fila con categoría o subcategoría vacía" -ForegroundColor Yellow
        continue 
    }

    # ---- 2. ruta completa relativa a la biblioteca ----------------------
    $fullPath = if ($sub2) { "$cat/$sub1/$sub2" } else { "$cat/$sub1" }

    # ---- 3. garantizar carpeta (crea niveles faltantes) -----------------
   
        Resolve-PnPFolder -SiteRelativePath "$ListName/$fullPath" -ErrorAction Stop
        
        # Obtener el item de lista asociado a la carpeta
        $folderItem = Get-PnPListItem -List $ListName -FolderServerRelativeUrl "$ListName/$fullPath" -ErrorAction SilentlyContinue
        
        if ($null -eq $folderItem ) {
            Write-Host "No se pudo obtener el item de lista para la carpeta: $fullPath" -ForegroundColor Red
            continue
        }
        
        # Verificar si es una carpeta nueva
        if ($folderItem.FieldValues.ItemChildCount -eq 0) {          # recién creada
            $carpetasNuevas++
            Write-Host "[$carpetasNuevas/$totalItems] Creada: $fullPath" -ForegroundColor Cyan
        }

        # ---- 4. preparar metadatos ------------------------------------------
        $vals = @{
            Categoria        = $cat
            Subcategoria     = $sub1
            Subcategoria2    = $sub2
            Clase           = if ($row.CLASE) { $row.CLASE.Trim() } else { "" }
            TipoDocumento   = if ($row.'TIPO DOCUMENTO') { $row.'TIPO DOCUMENTO'.Trim() } else { "" }
            EstadoDocumentos = "En Revisión"
            ProyectoID       = $yml.Datos.IdProyecto
            ProyectoNombre   = $yml.Datos.NombreProyecto
            Marca            = $yml.Datos.Marca
            Comuna           = $yml.Datos.Comuna
            ShowDetails      = $false
        }

        # ---- 5. añadir la actualización al lote -----------------------------
        Set-PnPListItem -List $ListName -Identity $folderItem.Id `
                        -Values $vals -Batch $batchMeta
        $metaEnCola++
        
        # Mostrar progreso
        Write-Progress -Activity "Procesando carpetas" -Status "$metaEnCola de $totalItems" `
                       -PercentComplete (($metaEnCola / $totalItems) * 100)
    
}

# Limpiar la barra de progreso
Write-Progress -Activity "Procesando carpetas" -Completed

# ---- 6. enviar lote de metadatos en una sola llamada REST ---------------
Invoke-PnPBatch -Batch $batchMeta -ErrorAction Stop

Write-Host "`nTotal carpetas nuevas:   $carpetasNuevas"
Write-Host "Metadatos aplicados a: $metaEnCola carpetas`n" -ForegroundColor Green