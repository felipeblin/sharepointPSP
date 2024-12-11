
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$NombreProyecto = "Proyecto de Prueba"
$UrlProyecto = "proyecto-prueba"
# 1. Conexión al sitio principal
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al sitio principal" -ForegroundColor Green




# Función para manejar errores
function Handle-Error {
    param (
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
}

# Función para crear una lista si no existe
function Create-ListIfNotExists {
    param (
        [string]$ListName,
        [string]$ListTemplate
    )
    if (!(Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue)) {
        try {
            New-PnPList -Title $ListName -Template GenericList
            Write-Host "Lista '$ListName' creada exitosamente." -ForegroundColor Green
        } catch {
            Handle-Error "No se pudo crear la lista '$ListName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "La lista '$ListName' ya existe." -ForegroundColor Yellow
    }
}

# Crear las listas principales
Create-ListIfNotExists "Proyecto Inmobiliario" "GenericList"
Create-ListIfNotExists "Tipos de Departamentos" "GenericList"

# Función para agregar un campo a una lista si no existe
function Add-FieldIfNotExists {
    param (
        [string]$ListName,
        [string]$FieldName,
        [string]$FieldType,
        [hashtable]$AdditionalProperties = @{}
    )
    $internalName = $FieldName.Replace(" ", "")
    if (!(Get-PnPField -List $ListName -Identity $internalName -ErrorAction SilentlyContinue)) {
        try {
            Add-PnPField -List $ListName -DisplayName $FieldName -InternalName $internalName -Type $FieldType @AdditionalProperties
            Write-Host "Campo '$FieldName' agregado a la lista '$ListName'." -ForegroundColor Green
        } catch {
            Handle-Error "No se pudo agregar el campo '$FieldName' a la lista '$ListName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "El campo '$FieldName' ya existe en la lista '$ListName'." -ForegroundColor Yellow
    }
}

# Agregar campos a la lista "Proyecto Inmobiliario"
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

foreach ($field in $proyectoFields) {
    Add-FieldIfNotExists "Proyecto Inmobiliario" $field.Name $field.Type
}

# Agregar campos a la lista "Tipos de Departamentos"
$tiposFields = @(
    @{Name="TipoDep"; Type="Text"},
    @{Name="Metraje"; Type="Number"},
    @{Name="Unidades"; Type="Number"}
)

foreach ($field in $tiposFields) {
    Add-FieldIfNotExists "Tipos de Departamentos" $field.Name $field.Type
}

# Crear una relación entre las listas
try {
    $lookupList = Get-PnPList -Identity "Tipos de Departamentos"
    $lookupField = "TipoDep"
    $schemaXml = "<Field Type='Lookup' DisplayName='Tipos de Departamentos' Required='FALSE' EnforceUniqueValues='FALSE' List='{$($lookupList.Id)}' ShowField='$lookupField' UnlimitedLengthInDocumentLibrary='FALSE' RelationshipDeleteBehavior='None' ID='{$(New-Guid)}' StaticName='TiposDepartamentos' Name='TiposDepartamentos' />"
    
    Add-PnPFieldFromXml -List "Proyecto Inmobiliario" -FieldXml $schemaXml
    Write-Host "Relación creada entre 'Proyecto Inmobiliario' y 'Tipos de Departamentos'." -ForegroundColor Green
} catch {
    Handle-Error "No se pudo crear la relación entre las listas: $($_.Exception.Message)"
}

# Función para verificar si un campo existe
function Field-Exists-Name {
    param (
        [string]$ListName,
        [string]$FieldName
    )
    $field = Get-PnPField -List $ListName -Identity $FieldName -ErrorAction SilentlyContinue
    return $null -ne $field
}
function Field-Exists {
    param (
        [string]$ListName,
        [string]$InternalName
    )
    $field = Get-PnPField -List $ListName -Identity $InternalName -ErrorAction SilentlyContinue
    return $null -ne $field
}
# Función para obtener todos los campos personalizados de una lista
function Get-CustomFields {
    param (
        [string]$ListName
    )
    $allFields = Get-PnPField -List $ListName
    return $allFields | Where-Object { -not $_.Hidden -and -not $_.ReadOnlyField -and $_.InternalName -notin @("ContentType", "Attachments") }
}



# Añadir datos a la lista "Tipos de Departamentos"
$tiposDepartamentos = @(
    @{TipoDep = "1D1B"; Metraje = 36.4; Unidades = 105},
    @{TipoDep = "2D1B"; Metraje = 47.0; Unidades = 45},
    @{TipoDep = "2D2B"; Metraje = 54.9; Unidades = 45},
    @{TipoDep = "3D2B"; Metraje = 60.4; Unidades = 30}
)

# Opción 1: Usando ViewXml
foreach ($tipo in $tiposDepartamentos) {
    $camlQuery = "<View><Query><Where><Eq><FieldRef Name='TipoDep'/><Value Type='Text'>$($tipo.TipoDep)</Value></Eq></Where></Query></View>"
    $existingItems = Get-PnPListItem -List "Tipos de Departamentos" -Query $camlQuery
    
    if ($existingItems.Count -eq 0) {
        try {
            Add-PnPListItem -List "Tipos de Departamentos" -Values $tipo
            Write-Host "Datos añadidos a 'Tipos de Departamentos': $($tipo.TipoDep)" -ForegroundColor Green
        } catch {
            Handle-Error "No se pudieron añadir datos a 'Tipos de Departamentos': $($_.Exception.Message)"
        }
    } else {
        Write-Host "El dato '$($tipo.TipoDep)' ya existe en 'Tipos de Departamentos'." -ForegroundColor Yellow
    }
}

# Añadir datos a la lista "Proyecto Inmobiliario"
$proyectoData = @{
    "Title" = $NombreProyecto
    "Zona" = "Z-AA+CB/CM"
    "SuperficieNeta" = 2429.9
    "SuperficieVendible" = 10320.6
    "Unidades" = 236
    "CostoTerreno" = 128880
    "MargenIFRS" = 31.5
    "IngresoTotal" = 625129
    "TIR" = 10.8
    "Inmobiliaria" = "PILARES"
    "CentroCosto" = "2289"
    "RolMatriz" = "479-1"
    "FirmaPlanos" = "2019-08-28"
    "PermisoEdificacion" = "2020-09-23"
    "InicioVentas" = "2021-09-16"
    "ResolucionRecepcion" = "2023-07-26"
    "EntregaDepartamentos" = "2023-07-26"
}
$validData = @{}
foreach ($key in $proyectoData.Keys) {
    if (Field-Exists -ListName "Proyecto Inmobiliario" -InternalName $key) {
        $validData[$key] = $proyectoData[$key]
    } else {
        Write-Host "Campo '$key' no encontrado en la lista 'Proyecto Inmobiliario'. Se omitirá este dato." -ForegroundColor Yellow
    }
}

try {
    Add-PnPListItem -List "Proyecto Inmobiliario" -Values $validData
    Write-Host "Datos añadidos a 'Proyecto Inmobiliario'." -ForegroundColor Green
} catch {
    Handle-Error "No se pudieron añadir datos a 'Proyecto Inmobiliario': $($_.Exception.Message)"
}

# Crear una vista de formulario para la lista "Proyecto Inmobiliario"
try {
    $customFields = Get-CustomFields -ListName "Proyecto Inmobiliario"
    $fieldNames = $customFields | ForEach-Object { $_.InternalName }
    # Verificar si la vista ya existe
    $existingView = Get-PnPView -List "Proyecto Inmobiliario" -Identity "Vista Completa Formulario" -ErrorAction SilentlyContinue
    

    if ($existingView) {
        Write-Host "Actualizando vista existente..." -ForegroundColor Yellow
        # Remover la vista existente
        Remove-PnPView -List "Proyecto Inmobiliario" -Identity "Vista Completa Formulario" -Force
    }
    
    # Crear la nueva vista
    $newView = Add-PnPView -List "Proyecto Inmobiliario" `
                          -Title "Vista Completa Formulario" `
                          -Fields $fieldNames `
                          -SetAsDefault `
                          -Query "<OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>"
    
    Write-Host "Vista 'Vista Completa Formulario' creada exitosamente y establecida como predeterminada" -ForegroundColor Green
    
    Write-Host "Vista de formulario 'Vista Completa Formulario' creada para 'Proyecto Inmobiliario'." -ForegroundColor Green
} catch {
    Handle-Error "No se pudo crear la vista de formulario para 'Proyecto Inmobiliario': $($_.Exception.Message)"
}

# Crear una vista estándar para la lista "Tipos de Departamentos"
try {
    $customFields = Get-CustomFields -ListName "Tipos de Departamentos"
    $fieldNames = $customFields | ForEach-Object { if ($_.InternalName -ne "Title") { $_.InternalName } }
    
    # Crear la vista estándar
    $view = Add-PnPView -List "Tipos de Departamentos" -Title "Vista Completa" -Fields $fieldNames -SetAsDefault
    
    Write-Host "Vista estándar 'Vista Completa' creada para 'Tipos de Departamentos'." -ForegroundColor Green
} catch {
    Handle-Error "No se pudo crear la vista para 'Tipos de Departamentos': $($_.Exception.Message)"
}


