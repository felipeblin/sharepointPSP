# Site and project configuration variables
$yaml_ = Get-Content -Path "$PSScriptRoot/config.yaml"| ConvertFrom-Yaml
#$yaml_ = ConvertFrom-Yaml -Yaml $yamlContent
# $SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
# $NombreProyecto = "Proyecto de Prueba"
#$UrlProyecto = "proyecto-prueba"
$SitioPrincipal = $yaml_.Datos.SitioPrincipal
$NombreProyecto = $yaml_.Datos.NombreProyecto
$UrlProyecto = $yaml_.Datos.UrlProyecto
$IdProyecto = $yaml_.Datos.IdProyecto
$Marca = $yaml_.Datos.Marca
$Comuna = $yaml_.Datos.Comuna                        # URL-friendly project name

Write-Host "Iniciando script de creación de página para proyecto: $NombreProyecto" -ForegroundColor Cyan

# 1. Connect to SharePoint site
Write-Host "`nPaso 1: Intentando conexión a SharePoint..." -ForegroundColor Yellow
try {
    $connection = Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450" -ErrorAction Stop
    Write-Host "✓ Conectado exitosamente al sitio principal" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al conectar al sitio: $_" -ForegroundColor Red
    exit
}

# 2. Define new page name with project URL for consistency
$PaginaNueva = "HomePage-$UrlProyecto"
Write-Host "`nPaso 2: Configurando nombre de página: $PaginaNueva" -ForegroundColor Yellow

# 2.1 Check if page exists and delete it
Write-Host "`nPaso 2.1: Verificando si la página existe..." -ForegroundColor Yellow
try {
    $existingPage = Get-PnPPage -Identity $PaginaNueva -ErrorAction SilentlyContinue
    if ($null -ne $existingPage) {
        Write-Host "  Página existente encontrada. Procediendo a eliminarla..." -ForegroundColor Gray
        Remove-PnPPage -Identity $PaginaNueva -Force -Recycle
        Write-Host "  Limpiando papelera de reciclaje..." -ForegroundColor Gray
        Clear-PnPRecycleBinItem -All -Force
        Write-Host "✓ Página existente eliminada y papelera limpiada" -ForegroundColor Green
    } else {
        Write-Host "  No se encontró página existente" -ForegroundColor Gray
    }
} catch {
    Write-Host "✕ Error al verificar/eliminar página existente: $_" -ForegroundColor Red
    exit
}

# 3. Create new client-side page
Write-Host "`nPaso 3: Creando nueva página..." -ForegroundColor Yellow
try {
    Start-Sleep -Seconds 2  # Small delay to ensure cleanup is complete
    $page = Add-PnPPage -Name $PaginaNueva -LayoutType Home -Title "Página del Proyecto $UrlProyecto" -ErrorAction Stop
    $page | Add-PnPPageSection -SectionTemplate OneColumnVerticalSection -Order 1

    Write-Host "✓ Página creada exitosamente" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al crear la página: $_" -ForegroundColor Red
    exit
}
# 4. Add first web part - Real Estate Project List
Write-Host "`nPaso 4: Agregando web part de Proyecto Inmobiliario..." -ForegroundColor Yellow
try {
    # Get list details
    $listaProyecto = Get-PnPList -Identity "Proyecto Inmobiliario" -ErrorAction Stop
    if ($null -eq $listaProyecto) {
        throw "Lista 'Proyecto Inmobiliario' no encontrada"
    }
    Write-Host "  Lista 'Proyecto Inmobiliario' encontrada con ID: $($listaProyecto.Id)" -ForegroundColor Gray
    
    # # Get the page and ensure section exists
    # $page = Get-PnPPage -Identity $PaginaNueva
    #Add-PnPPageSection -Page $PaginaNueva -SectionTemplate OneColumnFullWidth
    
    # Get list properties
    $listUrl = $listaProyecto.RootFolder.ServerRelativeUrl
    $siteUrl = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
    
        # Updated web part properties with specific view
        $webPartProps = @{
            isDocumentLibrary = $false
            listUrl = $listUrl
            siteUrl = $siteUrl
            webUrl = $siteUrl
            listId = $listaProyecto.Id
            baseViewId = $vistaProyecto.Id
            viewId = $vistaProyecto.Id
            selectedViewId = $vistaProyecto.Id
            selectedListUrl = $listUrl
            selectedList = @{
                id = $listaProyecto.Id
                title = "Proyecto Inmobiliario"
                url = $listUrl
                viewId = $vistaProyecto.Id
            }
        } | ConvertTo-Json
        
        Write-Host "  Agregando web part con vista 'Galeria 3'..." -ForegroundColor Gray
        
        $newWebPartProyecto = Add-PnPPageWebPart -Page $PaginaNueva `
            -DefaultWebPartType List `
            -Section 1 `
            -Column 1 `
            -Order 1 `
            -WebPartProperties @{
                selectedListId=$listaProyecto.Id
                title = "Proyecto Inmobiliario"
                selectedViewId = $vistaProyecto.Id
                viewId = $vistaProyecto.Id
            } `
            -ErrorAction Stop
    
    Write-Host "  Agregando web part con nueva configuración..." -ForegroundColor Gray
    
    # $newWebPartProyecto = Add-PnPPageWebPart -Page $PaginaNueva -DefaultWebPartType List `
    #     -Section 1 -Column 1 -WebPartProperties @{isDocumentLibrary="false"; selectedListId=$listaProyecto.Id}`
    #     -ErrorAction Stop
    Write-Host "✓ Web part de Proyecto Inmobiliario agregado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al agregar web part de Proyecto Inmobiliario: $_" -ForegroundColor Red
    Write-Host "  Detalles adicionales del error:" -ForegroundColor Yellow
    Write-Host "  - ID de la lista: $($listaProyecto.Id)" -ForegroundColor Yellow
    Write-Host "  - URL de la lista: $listUrl" -ForegroundColor Yellow
    exit
}
# 5. Add second web part - Tipos de Departamentos List
Write-Host "`nPaso 4: Agregando web part de Tipos de Departamentos..." -ForegroundColor Yellow
try {
    # Get list details
    $listaTipos = Get-PnPList -Identity "Tipos de Departamentos" -ErrorAction Stop
    if ($null -eq $listaTipos) {
        throw "Lista 'Tipos de Departamentos' no encontrada"
    }
    Write-Host "  Lista 'Tipos de Departamentos' encontrada con ID: $($listaTipos.Id)" -ForegroundColor Gray
    
    # # Get the page and ensure section exists
    # $page = Get-PnPPage -Identity $PaginaNueva
    #Add-PnPPageSection -Page $PaginaNueva -SectionTemplate OneColumnFullWidth
    
    # Get list properties
    $listUrl = $listaTipos.RootFolder.ServerRelativeUrl
    $siteUrl = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
    
    
    # Updated web part properties
    # $webPartProps = @{
    #     isDocumentLibrary = $false
    #     listUrl = $listUrl
    #     siteUrl = $siteUrl
    #     webUrl = $siteUrl
    #     listId = $listaTipos.Id
    #     baseViewId = 1
    #     selectedListUrl = $listUrl
    #     selectedList = @{
    #         id = $listaTipos.Id
    #         title = "Tipos de Departamentos"
    #         url = $listUrl
    #     }
    # } | ConvertTo-Json
    
    
    Write-Host "  Agregando web part con nueva configuración..." -ForegroundColor Gray
    
    $newWebPartProyecto = Add-PnPPageWebPart -Page $PaginaNueva -DefaultWebPartType List `
        -Section 1 -Column 1 -WebPartProperties @{isDocumentLibrary="false"; selectedListId=$listaTipos.Id}`
        -ErrorAction Stop
    Write-Host "✓ Web part de Tipos de Departamentos agregado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al agregar web part de Proyecto Inmobiliario: $_" -ForegroundColor Red
    Write-Host "  Detalles adicionales del error:" -ForegroundColor Yellow
    Write-Host "  - ID de la lista: $($listaProyecto.Id)" -ForegroundColor Yellow
    Write-Host "  - URL de la lista: $listUrl" -ForegroundColor Yellow
    exit
}
# 6. Publish the page
Write-Host "`nPaso 6: Publicando la página..." -ForegroundColor Yellow
try {
    # Simplify the publish command by removing the unsupported parameter
    $publishResult = Set-PnPPage -Identity $PaginaNueva -Publish  -CommentsEnabled:$false -ShowPublishDate $true
    Write-Host "✓ Página publicada exitosamente" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al publicar la página: $_" -ForegroundColor Red
    exit
}

Write-Host "`n✓ Proceso completado exitosamente" -ForegroundColor Green
Write-Host "URL de la página: $SitioPrincipal/$UrlProyecto/SitePages/$PaginaNueva.aspx" -ForegroundColor Cyan

# After publishing the page, set it as homepage
Write-Host "`nPaso 7: Configurando página como Home page por defecto..." -ForegroundColor Yellow
try {
    # Set the page as homepage
    Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$PaginaNueva.aspx"
    Write-Host "✓ Página configurada exitosamente como Home page por defecto" -ForegroundColor Green
} catch {
    Write-Host "✕ Error al configurar la página como Home page: $_" -ForegroundColor Red
    exit
}

Write-Host "`n✓ Proceso completado exitosamente" -ForegroundColor Green
Write-Host "URL de la página: $SitioPrincipal/$UrlProyecto/SitePages/$PaginaNueva.aspx" -ForegroundColor Cyan
Write-Host "La página ha sido configurada como Home page por defecto" -ForegroundColor Cyan