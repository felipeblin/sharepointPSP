
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
    $proyectoFields = @("Categoria", "Clase","Subcategoria","Subcategoria2")
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
            <FieldRef Name='ID' Ascending='FALSE'/>
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
  "height": 150,
  "width": 200,
  "hideSelection": false,
  "fillHorizontally": true,
  "formatter": {
    "elmType": "div",
    "attributes": {
      "class": "sp-card-container"
    },
    "style": {
      "overflow": "hidden",
      "display": "flex",
      "border": "none",
      "justify-content": "center",
      "align-items": "center",
      "margin": "0 auto",
      "color": "#0078d4",
      "box-shadow": "none"
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
          "class": "ms-bgColor-white sp-card-subContainer"
        },
        "style": {
          "border": "none",
          "box-shadow": "none"
        },
        "children": [
          {
            "elmType": "div",
            "attributes": {
              "class": "sp-card-displayColumnContainer"
            },
            "style": {
              "border": "none"
            },
            "children": [
              {
                "elmType": "div",
                "attributes": {
                  "class": "sp-card-imageContainer"
                },
                "style": {
                  "border": "none"
                },
                "children": [
                  {
                    "elmType": "img",
                    "attributes": {
                      "src": "=if([$Clase] == 'PERMISOS', '/sites/PSP-EESS/PruebaPSP/SiteAssets/documento-si-PSP.png', if(indexOf([$Clase], 'INMOBILIARIOS') != -1 , '/sites//PSP-EESS/PruebaPSP/SiteAssets/documento-si-PCT.png', if(indexOf([$Clase], 'VERSIÓN OBRA') != -1, '/sites/PSP-EESS/PruebaPSP/SiteAssets/documento-no-PSP.png', if([$Clase] == 'DOC COM', '/sites/PSP-EESS/PruebaPSP/SiteAssets/documento-no-PSP.png', ''))))",
                      "title": "[$Clase]"
                    },
                    "style": {
                      "overflow": "hidden",
                      "display": "flex",
                      "border": "none",
                      "justify-content": "center",
                      "align-items": "center",
                      "width": "50px",
                      "height": "50px",
                      "margin": "0 auto",
                      "bold": "true",
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
                  "overflow": "hidden",
                  "text-align": "center",
                  "font-size": "9px",
                  "border": "none"
                },
                "txtContent": "=if(length([$FileLeafRef]) > 20, substring([$FileLeafRef], 0, 20), [$FileLeafRef])",
                "defaultHoverField": "[$FileLeafRef]"
              },
              {
                "elmType": "div",
                "attributes": {
                  "class": "sp-card-title"
                },
                "style": {
                  "overflow": "hidden",
                  "text-align": "center",
                  "font-size": "9px",
                  "border": "none"
                },
                "txtContent": "[$Subcategoria]"
              },
              {
                "elmType": "p",
                "attributes": {
                  "class": "ms-fontColor-neutralSecondary sp-card-subtitle"
                },
                "style": {
                  "overflow": "hidden",
                  "text-align": "center",
                  "font-size": "9px",
                  "border": "none"
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
