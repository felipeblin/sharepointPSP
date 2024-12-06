# Configuración

$lists = @("Documentos Inmobiliarios", "Documentos Arquitectura", "Documentos Técnicos", "Documentos Comerciales", "Documentos ODI")
$versionChoices = @("V.1", "V.2", "V.3", "V.4", "V.5", "V.6", "V.7", "V.8", "V.9", "V.10", "V.11", "V.12")
$pageName = "BibliotecasDocumentos.aspx"


# Función para conectar a SharePoint
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$NombreProyecto = "Proyecto de Prueba"
$UrlProyecto = "proyecto-prueba"
# 1. Conexión al sitio principal
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al sitio principal" -ForegroundColor Green

# Función para el manejo de errores
function Handle-Error {
    param($ErrorMessage)
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    # Aquí podrías agregar más lógica de manejo de errores, como logging a un archivo
}

# Función para crear o actualizar una biblioteca
function Create-Or-Update-Library {
    param($ListName)
    try {
        if (Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue) {
            Write-Host "Actualizando la biblioteca $ListName" -ForegroundColor Yellow
            # Aquí podrías agregar lógica para actualizar la biblioteca existente
        } else {
            Write-Host "Creando la biblioteca $ListName" -ForegroundColor Green
            New-PnPList -Title $ListName -Template DocumentLibrary
        }
        
        # Agregar columna Versión
        if (-not (Get-PnPField -List $ListName -Identity "Version" -ErrorAction SilentlyContinue)) {
            Add-PnPField -List $ListName -DisplayName "Versión" -InternalName "Version" -Type Choice -Choices $versionChoices
        }
        
        # Configurar alertas
        Add-PnPAlert -List $ListName -Title "$ListName - Nueva Versión" -ChangeType AddObject -DeliveryMethod Email -Frequency Immediate
    } catch {
        Handle-Error "Error al crear/actualizar la biblioteca $ListName $($_.Exception.Message)"
    }
}

# Función para crear la página moderna
function Create-Modern-Page {
    try {
        if (Get-PnPPage -Identity $pageName -ErrorAction SilentlyContinue) {
            Remove-PnPPage -Identity $pageName -Force
        }
        Add-PnPPage -Name $pageName -LayoutType Home
        
        foreach ($list in $lists) {
            $listObj = Get-PnPList -Identity $list
            $viewObj = Get-PnPView -List $list -Identity "All Documents" -ErrorAction SilentlyContinue
            if ($null -eq $viewObj) {
                $viewObj = Get-PnPView -List $list | Where-Object { $_.DefaultView -eq $true }
            }
            if ($null -ne $viewObj) {
                $webPartProperties = @{
                    Title = $list
                    ListId = $listObj.Id
                    ViewId = $viewObj.Id
                }
                $section = Add-PnPPageSection -Page $pageName -SectionTemplate OneColumn
                Add-PnPPageWebPart -Page $pageName -DefaultWebPartType CustomMessageRegion -Section $section -Column 1 -WebPartProperties @{
                    "message" = "<h2>$list</h2>"
                }
                Add-PnPPageWebPart -Page $pageName -DefaultWebPartType List -WebPartProperties $webPartProperties -Section $section -Column 1
            } else {
                Handle-Error "No se pudo encontrar la vista para la lista: $list"
            }
        }
    } catch {
        Handle-Error "Error al crear la página moderna: $($_.Exception.Message)"
    }
}

# Ejecución principal
Connect-ToSharePoint

foreach ($list in $lists) {
    Create-Or-Update-Library $list
}

# Columnas específicas para Documentos Arquitectura
if (-not (Get-PnPField -List "Documentos Arquitectura" -Identity "Comentario" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List "Documentos Arquitectura" -DisplayName "Comentario" -InternalName "Comentario" -Type Note
}
if (-not (Get-PnPField -List "Documentos Arquitectura" -Identity "Responsable" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List "Documentos Arquitectura" -DisplayName "Responsable" -InternalName "Responsable" -Type User
}

# Crear vista personalizada en Documentos Arquitectura
if (-not (Get-PnPView -List "Documentos Arquitectura" -Identity "Vista Personalizada" -ErrorAction SilentlyContinue)) {
    Add-PnPView -List "Documentos Arquitectura" -Title "Vista Personalizada" -Fields @("Title", "Version", "Comentario", "Responsable") -Query "<OrderBy><FieldRef Name='Title' /></OrderBy>"
}

#Create-Modern-Page

Write-Host "Proceso completado." -ForegroundColor Green