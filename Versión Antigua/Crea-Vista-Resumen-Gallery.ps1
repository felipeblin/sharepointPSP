# Módulos requeridos
# $requiredModules = @("Microsoft.Graph", "powershell-yaml")

# foreach ($module in $requiredModules) {
#     if (-not (Get-Module -ListAvailable -Name $module)) {
#         try {
#             Install-Module $module -Scope CurrentUser -Force -ErrorAction Stop
#             Write-Host "Módulo $module instalado correctamente" -ForegroundColor Green
#         } catch {
#             Write-Host "Error al instalar $module $_ " -ForegroundColor Red
#             exit
#         }
#     }
#     Import-Module $module
# }
# exit
# Configuración
$ErrorActionPreference = "Stop"
#$VerbosePreference = "Continue"

try {
    # Cargar configuración YAML
    $yamlPath = "$PSScriptRoot/config.yaml"
    if (-not (Test-Path $yamlPath)) {
        throw "No se encuentra el archivo de configuración: $yamlPath"
    }
    
    $yaml_ = Get-Content -Path $yamlPath -Raw | ConvertFrom-Yaml
    $SitioPrincipal = $yaml_.Datos.SitioPrincipal
    $UrlProyecto = $yaml_.Datos.UrlProyecto

    if (-not $SitioPrincipal -or -not $UrlProyecto) {
        throw "Configuración YAML incompleta. Verifique SitioPrincipal y UrlProyecto"
    }

    Write-Host "Configuración YAML cargada correctamente" -ForegroundColor Green

    #Instalar módulos específicos de Graph que necesitamos
$graphModules = @(
    "Microsoft.Graph.Sites",
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Core"
)

foreach ($module in $graphModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        try {
            Install-Module $module -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "Módulo $module instalado correctamente" -ForegroundColor Green
        } catch {
            Write-Host "Error al instalar $module $_" -ForegroundColor Red
            exit
        }
    }
    Import-Module $module
}

    # Conectar a Graph API
    Connect-MgGraph -ClientId "517333ad-3e65-4983-af5e-d4b965418278" -Scopes "Sites.ReadWrite.All"
    Write-Host "Conexión a Graph API exitosa" -ForegroundColor Green

    # Extraer la última parte de la URL después de "/sites/"
if ($SitioPrincipal -match "/sites/([^/]+)") {
  $siteName = $matches[1]
  Write-Host "El sitio es: $siteName"
}
    # Obtener Site ID
    $siteUrl = "socovesa.sharepoint.com:/sites/"+"$siteName/$UrlProyecto"
    
    $site = Get-MgSite -SiteId $siteUrl
    
    if (-not $site) {
        throw "No se encontró el sitio: $siteUrl"
    }
    $siteId = $site.Id
    Write-Host "Site ID obtenido: $siteId" -ForegroundColor Green

    # Obtener List ID con manejo de errores mejorado
    $list = Get-MgSiteList -SiteId $siteId | Where-Object DisplayName -eq "Proyecto Inmobiliario"
    if (-not $list) {
        throw "No se encontró la lista 'Proyecto Inmobiliario' en el sitio"
    }
    $listId = $list.Id
    Write-Host "List ID obtenido: $listId" -ForegroundColor Green

    # # Verificar y leer el archivo JSON
    # $jsonPath = "./Version Vigente/formatoResumen.json"
    # if (-not (Test-Path $jsonPath)) {
    #     throw "No se encuentra el archivo de formato: $jsonPath"
    # }
    # $formatoJson = Get-Content -Path $jsonPath -Raw
    
    # # Validar que el JSON sea válido
    # try {
    #     $null = $formatoJson | ConvertFrom-Json
    # } catch {
    #     throw "El archivo JSON no es válido: $_"
    # }
     # Aplicar el formato
    
     $formatoJson = @'
{"tileProps":{"$schema": "https://developer.microsoft.com/json-schemas/sp/v2/tile-formatting.schema.json",
    "height": 1000,
    "width": 1200,
    "hideSelection": false,
    "fillHorizontally": true,
    "formatter": {
      "elmType": "div",
      "style": {
        "display": "flex",
        "flex-direction": "column",
        "padding": "24px",
        "background-color": "#ffffff",
        "min-width": "1100px"
      },
      "children": [
        {
          "elmType": "div",
          "style": {
            "display": "flex",
            "justify-content": "space-between",
            "margin-bottom": "24px"
          },
          "children": [
            {
              "elmType": "div",
              "style": {
                "font-size": "24px",
                "font-weight": "bold"
              },
              "txtContent": "[$Title]"
            },
            {
              "elmType": "div",
              "style": {
                "background-color": "#0078d4",
                "color": "#ffffff",
                "padding": "8px 16px",
                "border-radius": "4px"
              },
              "txtContent": "[$CentroCosto]"
            }
          ]
        },
        {
          "elmType": "div",
          "style": {
            "display": "flex",
            "gap": "24px"
          },
          "children": [
            {
              "elmType": "div",
              "style": {
                "flex": "1",
                "display": "flex",
                "flex-direction": "column",
                "gap": "24px",
                "min-width": "500px"
              },
              "children": [
                {
                  "elmType": "div",
                  "style": {
                    "background-color": "#f3f2f1",
                    "padding": "20px",
                    "border-radius": "4px"
                  },
                  "children": [
                    {
                      "elmType": "div",
                      "style": {
                        "font-size": "18px",
                        "font-weight": "bold",
                        "margin-bottom": "16px"
                      },
                      "txtContent": "Información General"
                    },
                    {
                      "elmType": "div",
                      "style": {
                        "display": "flex",
                        "flex-direction": "column",
                        "gap": "12px"
                      },
                      "children": [
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Zona:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$Zona]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Superficie Neta:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$SuperficieNeta]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Superficie Vendible:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$SuperficieVendible]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Total Construido:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$TotalConstruido]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Constructibilidad Usada:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$ConstructibilidadUsada]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Incidencia:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$Incidencia]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Tipos de Departamentos:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$TiposDepartamentos.lookupValue]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Inmobiliaria:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$Inmobiliaria]"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "elmType": "div",
                  "style": {
                    "background-color": "#f3f2f1",
                    "padding": "20px",
                    "border-radius": "4px"
                  },
                  "children": [
                    {
                      "elmType": "div",
                      "style": {
                        "font-size": "18px",
                        "font-weight": "bold",
                        "margin-bottom": "16px"
                      },
                      "txtContent": "Unidades y Estacionamientos"
                    },
                    {
                      "elmType": "div",
                      "style": {
                        "display": "flex",
                        "flex-direction": "column",
                        "gap": "12px"
                      },
                      "children": [
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Unidades:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$Unidades]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Estacionamientos:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$EstacionamientosVendibles]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Bodegas:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$Bodegas]"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "elmType": "div",
              "style": {
                "flex": "1",
                "display": "flex",
                "flex-direction": "column",
                "gap": "24px",
                "min-width": "500px"
              },
              "children": [
                {
                  "elmType": "div",
                  "style": {
                    "background-color": "#f3f2f1",
                    "padding": "20px",
                    "border-radius": "4px"
                  },
                  "children": [
                    {
                      "elmType": "div",
                      "style": {
                        "font-size": "18px",
                        "font-weight": "bold",
                        "margin-bottom": "16px"
                      },
                      "txtContent": "Información Financiera"
                    },
                    {
                      "elmType": "div",
                      "style": {
                        "display": "flex",
                        "flex-direction": "column",
                        "gap": "12px"
                      },
                      "children": [
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Costo Directo:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$CostoDirecto]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Costo Terreno:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$CostoTerreno]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Ingreso Total:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$IngresoTotal]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Margen IFRS:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$MargenIFRS]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "TIR:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$TIR]"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "elmType": "div",
                  "style": {
                    "background-color": "#f3f2f1",
                    "padding": "20px",
                    "border-radius": "4px"
                  },
                  "children": [
                    {
                      "elmType": "div",
                      "style": {
                        "font-size": "18px",
                        "font-weight": "bold",
                        "margin-bottom": "16px"
                      },
                      "txtContent": "Fechas y Documentación"
                    },
                    {
                      "elmType": "div",
                      "style": {
                        "display": "flex",
                        "flex-direction": "column",
                        "gap": "12px"
                      },
                      "children": [
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Rol Matriz:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "[$RolMatriz]"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Firma Planos:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$FirmaPlanos])"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Permiso Edificación:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$PermisoEdificacion])"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Inicio Ventas:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$InicioVentas])"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Inicio Excavación:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$InicioExcavacion])"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Resolución Recepción:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$ResolucionRecepcion])"
                            }
                          ]
                        },
                        {
                          "elmType": "div",
                          "style": {
                            "display": "flex",
                            "justify-content": "space-between",
                            "padding": "4px 8px"
                          },
                          "children": [
                            {
                              "elmType": "div",
                              "style": {
                                "font-weight": "500",
                                "min-width": "200px"
                              },
                              "txtContent": "Entrega Departamentos:"
                            },
                            {
                              "elmType": "div",
                              "style": {
                                "min-width": "250px"
                              },
                              "txtContent": "=toLocaleDateString([$EntregaDepartamentos])"
                            }
                          ]
                        }
                      ]
                    }
                  ]
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
    
    # Definir campos con validación
    $proyectoFields = @(
        "Title","CentroCosto","Zona",
        "SuperficieNeta","SuperficieVendible","TotalConstruido",
        "ConstructibilidadUsada","Incidencia","TiposDepartamentos",
        "Inmobiliaria","Unidades","EstacionamientosVendibles",
        "Bodegas","CostoDirecto","CostoTerreno","IngresoTotal",
        "MargenIFRS","TIR","RolMatriz","FirmaPlanos",
        "PermisoEdificacion","InicioVentas","InicioExcavacion",
        "ResolucionRecepcion","EntregaDepartamentos"
    )

    # Verificar si la vista ya existe
    #$existingView = Get-MgSiteListView -SiteId $siteId -ListId $listId | Where-Object DisplayName -eq "Galeria 3"
    

    # Recupera todas las vistas de la lista
    $allViews = Invoke-MgGraphRequest -Uri "/v1.0/sites/$siteId/lists/$listId/views" -Method GET

    # Filtra la vista "Galeria 3"
    $existingView = $allViews.value | Where-Object { $_.displayName -eq "Galeria 3" }

    if ($existingView) {
        Write-Host "La vista 'Galeria 3' ya existe. Se actualizará." -ForegroundColor Yellow
        
        # Actualizar vista existente
        $updateUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/lists/$listId/views/$($existingView.Id)"
        $updateBody = @{
            displayName = "Galeria 3"
            fields = $proyectoFields
            formatter = $formatoJson
        }
        
        $response = Invoke-MgGraphRequest -Uri $updateUrl -Method PATCH -Body $updateBody
        Write-Host "Vista actualizada exitosamente" -ForegroundColor Green
    } else {
        # Crear nueva vista
        $createBody = @{
            displayName = "Galeria 3"
            viewType = "html"
            fields = $proyectoFields
            formatter = $formatoJson
        }

        $createUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/lists/$listId/views"
        $response = Invoke-MgGraphRequest -Uri $createUrl -Method POST -Body $createBody
        Write-Host "Vista creada exitosamente" -ForegroundColor Green
    }

    # Verificar navegación
    $navNodes = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/navigation/quickLaunch" -Method GET
    $existingNode = $navNodes.value | Where-Object displayName -eq "Resumen Proyecto"

    if (-not $existingNode) {
        $navBody = @{
            displayName = "Resumen Proyecto"
            url = $list.WebUrl
            isDocLib = $true
        }
        
        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/navigation/quickLaunch" -Method POST -Body $navBody
        Write-Host "Enlace agregado al menú de navegación" -ForegroundColor Green
    } else {
        Write-Host "El enlace ya existe en el menú de navegación" -ForegroundColor Yellow
    }

} catch {
    Write-Host "`nError durante la ejecución:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nDetalles del error:" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
} finally {
    # Desconectar de Graph API
    if (Get-MgContext) {
        Disconnect-MgGraph
        Write-Host "`nDesconexión de Graph API completada" -ForegroundColor Green
    }
}