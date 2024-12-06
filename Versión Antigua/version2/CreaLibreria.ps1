# Conectar al sitio de SharePoint
try {
    Write-Host "Conectando a SharePoint..." -ForegroundColor Cyan
    Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive
    Write-Host "Conexión exitosa." -ForegroundColor Green
} catch {
    Write-Host "Error al conectar a SharePoint: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Bibliotecas de documentos a crear
$lists = @("Documentos Inmobiliarios", "Documentos Arquitectura", "Documentos Técnicos", "Documentos Comerciales", "Documentos ODI")

# Eliminar bibliotecas si ya existen
foreach ($list in $lists) {
    Write-Host "Verificando si la biblioteca $list existe"
    $existingList = Get-PnPList -Identity $list -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Host "Eliminando la biblioteca $list"
        Remove-PnPList -Identity $list -Force
    }
}

# Crear bibliotecas de documentos
foreach ($list in $lists) {
    Write-Host "Creando la biblioteca $list"
    New-PnPList -Title $list -Template DocumentLibrary
}

# Definir opciones de versión
$choices = @("V.1", "V.2", "V.3", "V.4", "V.5", "V.6", "V.7", "V.8", "V.9", "V.10", "V.11", "V.12")

# Agregar columnas necesarias a cada biblioteca
foreach ($list in $lists) {
    Write-Host "Agregando columna Versión a la biblioteca $list"
    $f = Add-PnPField -List $list -DisplayName "Versión" -InternalName "Version" -Type Choice -Choices $choices
}

# Columnas específicas para Documentos Arquitectura
Write-Host "Agregando columna Comentario a Documentos Arquitectura"
$f = Add-PnPField -List "Documentos Arquitectura" -DisplayName "Comentario" -InternalName "Comentario" -Type Note
Write-Host "Agregando columna Responsable a Documentos Arquitectura"
$f = Add-PnPField -List "Documentos Arquitectura" -DisplayName "Responsable" -InternalName "Responsable" -Type User

# Configurar alertas para cada biblioteca
foreach ($list in $lists) {
    Write-Host "Configurando alertas para la biblioteca $list"
    $a = Add-PnPAlert -List $list -Title "$list - Nueva Versión" -ChangeType AddObject -DeliveryMethod Email -Frequency Immediate
}

# Crear una vista personalizada en "Documentos Arquitectura"
Write-Host "Creando una vista personalizada en Documentos Arquitectura"
$v = Add-PnPView -List "Documentos Arquitectura" -Title "Vista Personalizada" -Fields @("Title", "Version", "Comentario", "Responsable") -Query "<OrderBy><FieldRef Name='Title' /></OrderBy>"

# Nombre de la página
$pageName = "BibliotecasDocumentos.aspx"

# Eliminar la página si ya existe
Write-Host "Verificando si la página $pageName existe"
$existingPage = Get-PnPPage -Identity $pageName -ErrorAction SilentlyContinue
if ($existingPage) {
    Write-Host "Eliminando la página $pageName"
    Remove-PnPPage -Identity $pageName -Force
}

# Crear una página moderna
Write-Host "Creando la página moderna $pageName"
$p = Add-PnPPage -Name $pageName -LayoutType Home

# Agregar vistas de bibliotecas a la página
foreach ($list in $lists) {
    Write-Host "Agregando vistas de la biblioteca $list a la página"
    $listObj = Get-PnPList -Identity $list
    $viewObj = Get-PnPView -List $list -Identity "All Documents" -ErrorAction SilentlyContinue
    if ($viewObj -eq $null) {
        Write-Host "Vista 'All Documents' no encontrada, buscando la vista predeterminada"
        $viewObj = Get-PnPView -List $list | Where-Object { $_.DefaultView -eq $true }
    }
    if ($viewObj -ne $null) {
        $webPartProperties = @{
            Title = $list;
            ListId = $listObj.Id;
            ViewId = $viewObj.Id
        }
        Write-Host "Agregando sección a la página $pageName"
        $s = Add-PnPPageSection -Page $pageName -SectionTemplate OneColumn
        Write-Host "Agregando banner de texto a la página $pageName"
        $banner = Add-PnPPageTextPart -Page $pageName -Section 1 -Column 1 -Text $list 
        $cod = Add-PnPPageWebPart -Page $pageName -DefaultWebPartType Custom -WebPartProperties @{
            "ClassName" = "MyHTMLWebPart";
            "HTMLContent" = "<p>$list</p>";
        }
        Write-Host "Agregando web part de lista a la página $pageName"
        $w = Add-PnPPageWebPart -Page $pageName -DefaultWebPartType List -WebPartProperties $webPartProperties -Section 1 -Column 1 
    } else {
        Write-Host "No se pudo encontrar la vista para la lista: $list"
    }
}

# No publicar la página
Write-Host "Página $pageName creada pero no publicada."
