# Conectar a SharePoint (asegúrate de que estás conectado primero)
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

Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

# Leemos el archivo JSON del directorio actual
$formatoJson = [String](Get-Content -Path "./Version Vigente/formatoResumen.json" -Raw)

# Creamos la vista de tipo galería
#$listaProyectos = Get-PnPList -Identity "Proyecto Inmobiliario"

$proyectoFields = @(
  "Title","CentroCosto","Zona",
  "SuperficieNeta","SuperficieVendible","TotalConstruido","ConstructibilidadUsada","Incidencia","TiposDepartamentos",
  "Inmobiliaria","Unidades","EstacionamientosVendibles","Bodegas","CostoDirecto","CostoTerreno","IngresoTotal",
  "MargenIFRS","TIR","RolMatriz","FirmaPlanos","PermisoEdificacion","InicioVentas","InicioExcavacion","ResolucionRecepcion","EntregaDepartamentos" 
)
# Crear una vista más simple pero efectiva
# try {
    $listName = "Proyecto Inmobiliario"
    $viewName = 'Galeria 3'
    
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
    }
    
    # @{
    #     CustomFormatter = $formatoJson
    # }

    Write-Host "Formato aplicado exitosamente" -ForegroundColor Green
    # Get the list and its ID
    $list = Get-PnPList -Identity "Proyecto Inmobiliario"
    $listId = $list.Id
    $listUrl = $list.RootFolder.ServerRelativeUrl

    Write-Host "List ID: $listId"
    Write-Host "List URL: $listUrl"

    # Después de crear la biblioteca DocEESS, agregar al menú de navegación
    $navigationNode = Get-PnPNavigationNode -Location QuickLaunch | Where-Object {$_.Title -eq "Resumen Proyecto"}

    if (-not $navigationNode) {
      Add-PnPNavigationNode -Location QuickLaunch -Title "Resumen Proyecto" -Url $listUrl
    Write-Host "Proyecto Inmobiliario ya existe en el menú lateral" -ForegroundColor Yellow
      Write-Host "Proyecto Inmobiliario agregado al menú lateral" -ForegroundColor Green
    } else {
       Write-Host "Proyecto Inmobiliario ya existe en el menú lateral" -ForegroundColor Yellow
    }
# Add-PnPView -List $listaProyectos -Title "Galería 2" -SetAsDefault:$false -Fields "Title","CentroCosto","Zona",
#  "SuperficieNeta","SuperficieVendible","TotalConstruido","ConstructibilidadUsada","Incidencia","TiposDepartamentos",
#  "Inmobiliaria","Unidades","EstacionamientosVendibles","Bodegas","CostoDirecto","CostoTerreno","IngresoTotal",
#  "MargenIFRS","TIR","RolMatriz","FirmaPlanos","PermisoEdificacion","InicioVentas","InicioExcavacion","ResolucionRecepcion","EntregaDepartamentos" 
#  -ViewType2 Gallery -CustomFormatter $formatoJson