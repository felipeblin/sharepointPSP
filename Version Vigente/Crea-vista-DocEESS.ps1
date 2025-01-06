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
# Conectar a SharePoint
Connect-PnPOnline -Url "$SitioPrincipal/$UrlProyecto" -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"
Write-Host "Conectado exitosamente al nuevo subsitio $UrlProyecto" -ForegroundColor Green
# Después de crear la biblioteca DocEESS, agregar al menú de navegación
$navigationNode = Get-PnPNavigationNode -Location QuickLaunch | Where-Object {$_.Title -eq "DocEESS"}

if (-not $navigationNode) {
   Add-PnPNavigationNode -Location QuickLaunch -Title "DocEESS" -Url "$SitioPrincipal/$UrlProyecto/DocEESS"
   Write-Host "DocEESS agregado al menú lateral" -ForegroundColor Green
} else {
   Write-Host "DocEESS ya existe en el menú lateral" -ForegroundColor Yellow
}
# Crear una vista más simple pero efectiva
try {
    $listName = "DocEESS"
    $viewName = 'Estructurada'
    $proyectoFields = @("Categoria", "Subcategoria","Subcategoria2","Clase","Estado Documentos","Version","Editor","ShowDetails")
    # Verificar si la vista existe y eliminarla
    $existingView = Get-PnPView -List $listName -Identity $viewName -ErrorAction SilentlyContinue
    if ($existingView) {
        Remove-PnPView -List $listName -Identity $viewName -Force
        Write-Host "Vista anterior  eliminada" -ForegroundColor Yellow
    }
        # Crear la nueva vista
        $view = Add-PnPView -List $listName `
        -Title $viewName `
        -Fields $proyectoFields `
        -SetAsDefault `
        -Query @"
            <OrderBy>
            <FieldRef Name='Clase' Ascending='FALSE'/>
            </OrderBy>
            <GroupBy Collapse='TRUE' GroupLimit='30'>
            <FieldRef Name='Categoria'/>
            </GroupBy>
"@
        
        $view = Get-PnPView -List  $listName -Identity $viewName
        # $view.ViewType = "GALLERY"
    
        Write-Host "Vista básica creada exitosamente" -ForegroundColor Green
     
# Primero almacenamos el JSON original
$jsonFormat = @'
{"tileProps":{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/tile-formatting.schema.json",
  "width": 200,
  "height": 230,
  "hideSelection": false,
  "fillHorizontally": true,
  "overflow": "visible",
  "formatter": {
    "elmType": "div",
    "attributes": {
      "class": "sp-card-container"
    },
    "style": {
      "display": "flex",
      "flex-direction": "column",
      "overflow": "visible",
      "border": "1px solid #f8f0f0",
      "border-radius": "24px",
      "justify-content": "flex-start",
      "align-items": "stretch",
      "margin": "0 auto",
      "color": "#0078d4",
      "box-shadow": "none"
    },
    "children": [
      {
        "elmType": "div",
        "style": {
          "position": "fixed",
          "top": "0",
          "left": "0",
          "right": "0",
          "bottom": "0",
          "display": "=if([$ShowDetails], 'block', 'none')",
          "z-index": "999"
        },
        "customRowAction": {
          "action": "setValue",
          "stopPropagation": true,
          "actionInput": {
            "ShowDetails": "false"
          }
        }
      },
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
          "class": "ms-bgColor-white sp-card-subContainer"
        },
        "style": {
          "border": "none",
          "box-shadow": "none",
          "overflow": "visible",
          "height": "auto",
          "display": "flex",
          "flex-direction": "column",
          "z-index": "1000"
        },
        "children": [
          {
            "elmType": "div",
            "attributes": {
              "class": "sp-card-displayColumnContainer"
            },
            "style": {
              "border": "none",
              "overflow": "visible"
            },
            "children": [
              {
                "elmType": "div",
                "attributes": {
                  "class": "sp-card-imageContainer"
                },
                "style": {
                  "border": "none",
                  "overflow": "visible"
                },
                "children": [
                  {
                    "elmType": "img",
                    "attributes": {
                      "src": "=if([$File_x0020_Type] == '', if([$FolderChildCount] > 0, '/sites/PSP-EESS/PruebaPSP/SiteAssets/documento-si-PSP.png', '/sites/PSP-EESS/PruebaPSP/SiteAssets/documento-no-PSP.png'), if([$File_x0020_Type] == 'pdf', '/sites/PSP-EESS/PruebaPSP/SiteAssets/xls.png', if([$File_x0020_Type] == 'xlsx', '/sites/PSP-EESS/PruebaPSP/SiteAssets/xls.png', if([$File_x0020_Type] == 'pdf', '/sites/PSP-EESS/PruebaPSP/SiteAssets/pdf.png', '/sites/PSP-EESS/PruebaPSP/SiteAssets/blank.png'))) )",
                      "title": "=if([$File_x0020_Type] == '', [$Clase], '')"
                    },
                    "style": {
                      "display": "=if([$File_x0020_Type] == '', 'flex', 'none')",
                      "overflow": "visible",
                      "border": "none",
                      "justify-content": "center",
                      "align-items": "center",
                      "width": "40px",
                      "height": "40px",
                      "margin": "0 auto",
                      "color": "#0078d4"
                    }
                  }
                ]
              },
              {
                "elmType": "div",
                "attributes": {
                  "class": "sp-card-subtitle"
                },
                "style": {
                  "overflow": "visible",
                  "text-align": "center",
                  "font-size": "8px",
                  "border": "none"
                },
                "txtContent": ""
              },
              {
                "elmType": "p",
                "attributes": {
                  "class": "ms-fontColor-gray150 sp-card-subtitle"
                },
                "style": {
                  "text-align": "center",
                  "font-size": "12px",
                  "border": "none",
                  "margin-top": "8px",
                  "margin-width": "150px",
                  "white-space": "nowrap",
                  "text-overflow": "ellipsis",
                  "overflow": "visible"
                },
                "txtContent": "=if(indexOf([$Subcategoria2] + '|','|') > 20, substring([$Subcategoria2],0,20) +'...' ,[$Subcategoria2]) +'\n'+ if(indexOf([$Subcategoria] + '|','|') > 20, substring([$Subcategoria],0,20) +'...' ,[$Subcategoria]) "
              },
              {
                "elmType": "div",
                "style": {
                  "display": "flex",
                  "align-items": "center",
                  "justify-content": "space-around",
                  "width": "100%",
                  "padding": "8px",
                  "overflow": "visible"
                },
                "children": [
                  {
                    "elmType": "img",
                    "attributes": {
                      "src": "=if([$File_x0020_Type] == 'pdf', '/sites/PSP-EESS/PruebaPSP/SiteAssets/pdf.png', if([$File_x0020_Type] == 'xlsx', '/sites/PSP-EESS/PruebaPSP/SiteAssets/xls.png', if([$File_x0020_Type] == 'docx', '/sites/PSP-EESS/PruebaPSP/SiteAssets/docx.png', '/sites/PSP-EESS/PruebaPSP/SiteAssets/blank.png')))"
                    },
                    "style": {
                      "width": "=if([$File_x0020_Type] == '', '0px', '40px')",
                      "height": "45px",
                      "filter": "grayscale(100%)",
                      "margin-right": "8px",
                      "overflow": "visible"
                    }
                  },
                  {
                    "elmType": "button",
                    "style": {
                      "background-color": "=if([$EstadoDocumentos] == 'En Revisión', '#FFFFFF' , if([$EstadoDocumentos] == 'Aprobada', '#28a745', '#FFA500'))",
                      "color": "white",
                      "padding": "4px 8px",
                      "font-size": "16px",
                      "border": "none",
                      "border-radius": "50%",
                      "margin-top": "8px",
                      "cursor": "pointer",
                      "width": "30px",
                      "height": "30px",
                      "display": "=if([$FolderChildCount] > 0, 'flex', 'block')",
                      "justify-content": "center",
                      "align-items": "center",
                      "position": "relative",
                      "z-index": "1",
                      "margin-left": "auto",
                      "margin-right": "auto",
                      "overflow": "visible"
                    },
                    "txtContent": "=if([$EstadoDocumentos] == '', [$FolderChildCount], if([$EstadoDocumentos] == 'En Revisión', '🔍', '✓'))",
                    "customRowAction": {
                      "action": "setValue",
                      "stopPropagation": true,
                      "actionInput": {
                        "EstadoDocumentos": "=if([$EstadoDocumentos] == 'En Revisión', 'Aprobada', 'En Revisión')"
                      }
                    }
                  },
                  {
                    "elmType": "button",
                    "style": {
                      "background-color": "#0078d4",
                      "color": "white",
                      "padding": "0",
                      "font-size": "14px",
                      "border": "none",
                      "border-radius": "50%",
                      "margin-top": "8px",
                      "cursor": "pointer",
                      "display": "flex",
                      "position": "relative",
                      "z-index": "1",
                      "margin-left": "auto",
                      "margin-right": "auto",
                      "width": "20px",
                      "height": "20px",
                      "justify-content": "center",
                      "align-items": "center",
                      "font-weight": "bold",
                      "font-style": "italic"
                    },
                    "txtContent": "i",
                    "customRowAction": {
                      "action": "setValue",
                      "stopPropagation": true,
                      "actionInput": {
                        "ShowDetails": "=if([$ShowDetails] == true, false, true)"
                      }
                    }
                  }
                ]
              },
              {
                "elmType": "div",
                "style": {
                  "display": "=if([$ShowDetails], 'block', 'none')",
                  "background-color": "#f8f8f8",
                  "border": "1px solid #ccc",
                  "border-radius": "6px",
                  "padding-left": "10px",
                  "padding-right": "3px",
                  "margin": "1px",
                  "font-size": "10px",
                  "overflow": "visible",
                  "position": "relative",
                  "z-index": "1000"
                },
                "children": [
                  {
                    "elmType": "p",
                    "style": {
                      "margin": "4px 0"
                    },
                    "txtContent": "= 'Última modificación: ' + toLocaleString([$Modified])"
                  },
                  {
                    "elmType": "p",
                    "style": {
                      "margin": "4px 0"
                    },
                    "txtContent": "= 'Modificó: ' + [$Editor.title]"
                  },
                  {
                    "elmType": "p",
                    "style": {
                      "margin": "4px 0"
                    },
                    "txtContent": "= 'Versión actual: ' + [$_UIVersionString]"
                  }
                ]
              },
              {
                "elmType": "p",
                "attributes": {
                  "class": "ms-fontColor-gray150 sp-card-subtitle"
                },
                "style": {
                  "text-align": "center",
                  "font-size": "9px",
                  "border": "none",
                  "margin-top": "8px",
                  "margin-width": "150px",
                  "white-space": "nowrap",
                  "text-overflow": "ellipsis",
                  "overflow": "visible",
                  "align-self": "flex-end",
                  "font-weight": "bold"
                },
                  "txtContent": "=if([$File_x0020_Type] == '',if(indexOf([$Clase] + '|','|') > 20, substring([$Clase], 0, 20) + '...', [$Clase]),'')"
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
# Reemplazar PruebaPSP con el valor de $UrlProyecto
$jsonFormatModified = $jsonFormat.Replace('PruebaPSP', $UrlProyecto)

# Aplicar el formato modificado
Set-PnPView -List $listName -Identity $viewName -Values @{
    CustomFormatter = $jsonFormatModified
}
    
    # @{
    #     CustomFormatter = $formatoJson
    # }

    Write-Host "Formato aplicado exitosamente" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
$destinationFolder = "SiteAssets" # Destination folder in SharePoint
$localFolderPath = "./Version Vigente/iconos" # Local folder path
$targetFolderPath = $destinationFolder
    # Check if source folder exists
    if (-not (Test-Path $localFolderPath)) {
        throw "Local folder not found: $localFolderPath"
    }

    # Create SiteAssets folder debe existir
    $folder = Get-PnPFolder -Url $targetFolderPath 
    if (-not $folder) {
        Write-Host "No existe carpeta quiza está direccionada"
        
    }

    # Get all files from local folder
    $files = Get-ChildItem -Path $localFolderPath -File

    # Upload each file
    foreach ($file in $files) {
        Write-Host "Uploading $($file.Name)..." -ForegroundColor Cyan
        
        try {
            $fileadded = Add-PnPFile -Path $file.FullName -Folder $targetFolderPath -ErrorAction Stop
            Write-Host "Successfully uploaded $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Error uploading $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "File upload process completed" -ForegroundColor Green
    # Agrega esta biblioteca a la barra de navegación
   