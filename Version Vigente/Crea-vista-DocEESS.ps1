
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$NombreProyecto = "Proyecto de Prueba"
$UrlProyecto = "proyecto-prueba"
# Conectar a SharePoint
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green
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
        CustomFormatter = @' 
            {"tileProps":{"$schema": "https://developer.microsoft.com/json-schemas/sp/v2/tile-formatting.schema.json",
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
    }
'@
    }
    
    # @{
    #     CustomFormatter = $formatoJson
    # }

    Write-Host "Formato aplicado exitosamente" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}