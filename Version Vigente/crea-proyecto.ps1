    $SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
    $NombreProyecto = "Proyecto de Prueba"
    $UrlProyecto = "proyecto-prueba"
    # 1. Conexión al sitio principal
    Connect-PnPOnline -Url $SitioPrincipal -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
    Write-Host "Conectado exitosamente al sitio principal" -ForegroundColor Green

  
    # 2. Verificar si el subsitio ya existe
    $subSiteUrl = "$SitioPrincipal/$UrlProyecto"
    $existingSite = Get-PnPSubWeb -Identity $UrlProyecto -ErrorAction SilentlyContinue
    
    if (!$existingSite) {
        # 3. Crear el subsitio solo si no existe
        $subWeb = New-PnPWeb -Title $NombreProyecto -Url $UrlProyecto -Template "STS#0" -BreakInheritance:$false
        Write-Host "Subsitio creado exitosamente" -ForegroundColor Green
    }
    else{
        Write-Host "El sitio $NombreProyecto ya existe en la URL $subSiteUrl" -ForegroundColor Yellow
      
    }
    # 3. Conectar al nuevo subsitio
    Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
    Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green
    # # 4. Crear estructura de bibliotecas según el CSV
    # $bibliotecas = @(
    #     "DOCUMENTOS INMOBILIARIOS",
    #     "DOCUMENTOS ARQUITECTURA-ODI",
    #     "DOCUMENTOS CONSTRUCCIÓN",
    #     "DOCUMENTOS COMERCIALES"
    # )

    # foreach ($biblioteca in $bibliotecas) {
    #     New-PnPList -Title $biblioteca -Template DocumentLibrary
    #     Write-Host "Biblioteca '$biblioteca' creada" -ForegroundColor Green
    # }

      # 5. Configurar permisos básicos
    # Romper herencia de permisos para el sitio (corregido)
    $web = Get-PnPWeb
    $web.BreakRoleInheritance($true, $true)
    Write-Host "Herencia de permisos rota" -ForegroundColor Green