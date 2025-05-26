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
    $proyectoFields = @("Name","Categoria", "Subcategoria","Subcategoria2","Clase","Estado Documentos","Version","Editor","ShowDetails")
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
        Set-PnPView -List $listName -Identity $view.Id -Values @{
            ViewType2   = "TILES"
            DefaultView = $true
        }
    
        Write-Host "Vista básica creada exitosamente" -ForegroundColor Green
     
# Primero almacenamos el JSON original
$jsonFormat = @'
{"tileProps":
        {
  "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/tile-formatting.schema.json",
  "width": 200,
  "height": 130,
  "hideSelection": false,
  "fillHorizontally": true,
  "overflow": "visible",
  "formatter": {
    "elmType": "div",
    "style": {
      "display": "flex",
      "flex-direction": "column",
      "overflow": "visible",
      "border-radius": "24px",
      "justify-content": "flex-start",
      "align-items": "center",
      "margin": "0 auto",
      "color": "#0078d4",
      "box-shadow": "none",
      "position": "relative"
    },
    "children": [
      {
        "elmType": "div",
        "style": {
          "position": "relative",
          "width": "40px",
          "height": "40px",
          "margin-top": "40px"
        },
        "children": [
          {
            "elmType": "img",
            "attributes": {
              "src": "=if([$File_x0020_Type] == '', if([$FolderChildCount] > 0, '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/documento-si-PSP.png', '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/documento-no-PSP.png'), if([$File_x0020_Type] == 'pdf', '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/pdf.png', if([$File_x0020_Type] == 'xlsx', '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/xls.png', if([$File_x0020_Type] == 'docx', '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/docx.png', '/sites/PSP-EESS/proyecto-prueba-4/SiteAssets/blank.png'))))",
              "title": "=if([$File_x0020_Type] == '', [$Clase], '')",
              "alt": "=if([$File_x0020_Type] == '', 'Icono de carpeta ' + [$FileLeafRef], 'Icono de ' + [$File_x0020_Type])"
            },
            "style": {
              "width": "40px",
              "height": "40px",
              "object-fit": "contain",
              "border": "none"
            }
          },
          {
            "elmType": "button",
            "style": {
              "position": "absolute",
              "bottom": "-6px",
              "left": "-6px",
              "background-color": "=if([$EstadoDocumentos] == 'En Revisión', '#FFFFFF', if([$EstadoDocumentos] == 'Aprobada', '#28a745', '#FFA500'))",
              "color": "white",
              "padding": "0",
              "font-size": "14px",
              "border": "none",
              "border-radius": "50%",
              "cursor": "pointer",
              "width": "20px",
              "height": "20px",
              "display": "=if([$FolderChildCount] > 0, 'flex', 'block')",
              "justify-content": "center",
              "align-items": "center",
              "z-index": "1",
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
              "position": "absolute",
              "top": "-6px",
              "right": "-6px",
              "background-color": "#0078d4",
              "color": "white",
              "padding": "0",
              "font-size": "14px",
              "border": "none",
              "border-radius": "50%",
              "cursor": "pointer",
              "width": "20px",
              "height": "20px",
              "display": "flex",
              "justify-content": "center",
              "align-items": "center",
              "z-index": "1",
              "overflow": "visible"
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
          "width": "40px",
          "height": "40px",
          "display": "=if([$File_x0020_Type] == '', 'block', 'none')"
        }
      },
      {
        "elmType": "div",
        "style": {
          "text-align": "center",
          "font-size": "12px",
          "font-weight": "bold",
          "margin-top": "=if([$File_x0020_Type] == '', '-30px', '10px')",
          "width": "100%",
          "overflow": "hidden",
          "white-space": "nowrap",
          "text-overflow": "ellipsis"
        },
        "txtContent": "[$FileLeafRef]"
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
          "margin-top": "-50px",
          "font-size": "10px",
          "overflow": "visible",
          "position": "relative",
          "z-index": "1000",
          "width": "90%"
        },
        "children": [
          {
            "elmType": "p",
            "style": {
              "margin": "2px 0"
            },
            "txtContent": "= 'Última modificación: ' + toLocaleString([$Modified])"
          },
          {
            "elmType": "p",
            "style": {
              "margin": "2px 0"
            },
            "txtContent": "= 'Modificó: ' + [$Editor.title]"
          },
          {
            "elmType": "p",
            "style": {
              "margin": "2px 0"
            },
            "txtContent": "= 'Versión actual: ' + [$_UIVersionString]"
          }
        ]
      },
      {
        "elmType": "p",
        "style": {
          "text-align": "center",
          "font-size": "9px",
          "border": "none",
          "margin-top": "-90px",
          "width": "150px",
          "white-space": "nowrap",
          "text-overflow": "ellipsis",
          "overflow": "hidden",
          "align-self": "center",
          "font-weight": "bold"
        },
        "txtContent": "=if([$File_x0020_Type] == '', if(length([$Clase]) > 20, substring([$Clase], 0, 20) + '...', [$Clase]), '')"
      },
      {
        "elmType": "button",
        "attributes": {
          "class": "sp-card-defaultClickButton",
          "role": "presentation",
          "aria-label": "Abrir"
        },
        "style": {
          "position": "absolute",
          "top": "0",
          "left": "0",
          "width": "100%",
          "height": "100%",
          "background-color": "transparent",
          "border": "none",
          "cursor": "pointer",
          "z-index": "0"
        },
        "customRowAction": { "action": "defaultClick" }
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
   