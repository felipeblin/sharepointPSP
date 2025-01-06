    function Test-ProjectExists {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Title,
            
            [Parameter(Mandatory = $true)]
            [string]$Marca,
            
            [Parameter(Mandatory = $true)]
            [string]$IdProyecto,
            
            [Parameter(Mandatory = $true)]
            [string]$ListName = "Proyectos"
        )
        
        try {
            Write-Host "Validando existencia del proyecto..." -ForegroundColor Yellow
            Write-Host "  Título: $Title" -ForegroundColor Gray
            Write-Host "  Marca: $Marca" -ForegroundColor Gray
            Write-Host "  ID Proyecto: $IdProyecto" -ForegroundColor Gray
            
            # Construir la consulta CAML para buscar por múltiples criterios
            $camlQuery = "<View><Query><Where><And>
                <And>
                    <Eq><FieldRef Name='Proyecto'/><Value Type='Text'>$Title</Value></Eq>
                    <Eq><FieldRef Name='Marca'/><Value Type='Text'>$Marca</Value></Eq>
                </And>
                <Eq><FieldRef Name='IdProyecto'/><Value Type='Text'>$IdProyecto</Value></Eq>
            </And></Where></Query></View>"
            
            # Buscar items que coincidan
            $existingItems = Get-PnPListItem -List $ListName -Query $camlQuery
            if ($null -ne $existingItems -and $existingItems.Count -gt 0) {
                Write-Host "✕ Proyecto ya existe:" -ForegroundColor Red
                foreach ($item in $existingItems) {
                    Write-Host "  - Título: $($item['Title'])" -ForegroundColor Yellow
                    Write-Host "    Marca: $($item['Marca'])" -ForegroundColor Yellow
                    Write-Host "    ID Proyecto: $($item['IdProyecto'])" -ForegroundColor Yellow
                }
                return $true
            } else {
                Write-Host "✓ Proyecto no existe, puede proceder" -ForegroundColor Green
                return $false
            }
        }
        catch {
            Write-Host "✕ Error al validar proyecto: $_" -ForegroundColor Red
            throw $_
        }
    }
    function Invoke-CustomScript {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$ScriptPath,
    
            [Parameter(Mandatory = $false)]
            [hashtable]$Parameters,
    
            [Parameter(Mandatory = $false)]
            [switch]$ShowOutput = $true
        )
    
        try {
            # Validar que el script existe
            if (-not (Test-Path -Path $ScriptPath)) {
                throw "El script no existe en la ruta: $ScriptPath"
            }
    
            Write-Host "`nEjecutando script secundario..." -ForegroundColor Yellow
            Write-Host "Ruta: $ScriptPath" -ForegroundColor Gray
    
            # Si hay parámetros, mostrarlos
            if ($Parameters) {
                Write-Host "`nParámetros detectados:" -ForegroundColor Yellow
                $Parameters.GetEnumerator() | ForEach-Object {
                    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
                }
            }
    
            Write-Host "`nIniciando ejecución..." -ForegroundColor Yellow
            
            # Ejecutar el script usando el operador de llamada
            if ($Parameters) {
                $output = & $ScriptPath @Parameters
            } else {
                $output = & $ScriptPath
            }
            
            # Verificar el resultado
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                throw "El script secundario falló con código de salida: $LASTEXITCODE"
            }
    
            Write-Host "✓ Script ejecutado exitosamente" -ForegroundColor Green
            
            # Si hay salida y ShowOutput es true, mostrarla
            if ($output -and $ShowOutput) {
                Write-Host "`nSalida del script:" -ForegroundColor Yellow
                Write-Host $output -ForegroundColor Gray
            }
    
            # Retornar la salida
            return $output
    
        } catch {
            Write-Host "✕ Error al ejecutar el script: $_" -ForegroundColor Red
            Write-Host "  Detalles adicionales del error:" -ForegroundColor Yellow
            Write-Host "  - Verifique que la ruta del script es correcta" -ForegroundColor Yellow
            Write-Host "  - Confirme que tiene permisos para ejecutar el script" -ForegroundColor Yellow
            Write-Host "  - Revise la sintaxis del script" -ForegroundColor Yellow
            throw $_
        }
    }
    

    # Importar el módulo
    Import-Module PowerShell-Yaml

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
    $Comuna = $yaml_.Datos.Comuna
    # 1. Conexión al sitio principal
    Connect-PnPOnline -Url $SitioPrincipal -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
    Write-Host "Conectado exitosamente al sitio principal" -ForegroundColor Green

    # Preparar los valores para el nuevo item
    # Validar antes de crear
    $proyectoExiste = Test-ProjectExists `
        -Title $NombreProyecto `
        -Marca $Marca `
        -IdProyecto $IdProyecto `
        -ListName "Proyectos"

    if (-not $proyectoExiste) {
        # Crear el proyecto si no existe
        $itemValues = @{
            "Title" = $NombreProyecto
            "Proyecto" = $NombreProyecto
            "Marca" = $Marca
            "IdProyecto" = $IdProyecto
            "Comuna" = $Comuna
            "estado" = $yaml_.estado
            "Link" = "$SitioPrincipal/$UrlProyecto"
        }
        
        $newItem = Add-PnPListItem -List "Proyectos" -Values $itemValues
        Write-Host "✓ Proyecto agregado exitosamente con ID: $($newItem.Id)" -ForegroundColor Green
    }
    else {
        Write-Host "No se agregó el proyecto porque ya existe" -ForegroundColor Yellow
    }

    Write-Host "✓ Proyecto agregado exitosamente" -ForegroundColor Green
    Write-Host "  ID del nuevo item: $($newItem.Id)" -ForegroundColor Gray
  
    # 2. Verificar si el subsitio ya existe
    $subSiteUrl = "$SitioPrincipal/$UrlProyecto"
    $existingSite = Get-PnPSubWeb -Identity $UrlProyecto -ErrorAction SilentlyContinue
    
    if (!$existingSite) {
        # 3. Crear el subsitio solo si no existe
        $subWeb = New-PnPWeb -Title $NombreProyecto -Url $UrlProyecto -Template "STS#3" -BreakInheritance:$false
        Write-Host "Subsitio creado exitosamente" -ForegroundColor Green
    }
    else{
        Write-Host "El sitio $NombreProyecto ya existe en la URL $subSiteUrl" -ForegroundColor Yellow
      
    }
    # 3. Conectar al nuevo subsitio
    Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
    Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green
    
    $web = Get-PnPWeb
    $web.BreakRoleInheritance($true, $true)
    Write-Host "Herencia de permisos rota" -ForegroundColor Green

    
    Invoke-CustomScript -ScriptPath "$PSScriptRoot/crea-estructura.ps1" 
    Write-Host "✓ Estructura creada exitosamente" -ForegroundColor Green

    Invoke-CustomScript -ScriptPath "$PSScriptRoot/Crea-vista-DocEESS.ps1" 
    Write-Host "✓ Vista de DocEESS creada exitosamente" -ForegroundColor Green

    Invoke-CustomScript -ScriptPath "$PSScriptRoot/crea-resumen-psp.ps1" 
    Write-Host "✓ Resumen PSP creado exitosamente" -ForegroundColor Green

    Invoke-CustomScript -ScriptPath "$PSScriptRoot/crea-home-page.ps1"
    Write-Host "✓ Página de inicio creada exitosamente" -ForegroundColor Green

    Invoke-CustomScript -ScriptPath "$PSScriptRoot/Crea-Vista-Resumen.ps1"
    Write-Host "✓ Página de inicio creada exitosamente" -ForegroundColor Green