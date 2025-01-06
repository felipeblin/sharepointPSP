
# Variables
$siteUrl = "https://tu-dominio.sharepoint.com/sites/tu-sitio"
$libraryName = "DocEESS"
$viewName = "test"
$yaml_ = Get-Content -Path "/Users/felipeblin/vscode/sharepoint/sharepointPSP/Version Vigente/config.yaml"| ConvertFrom-Yaml
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
# JSON para la vista de galería (Card View)
$viewJson = @"
{
    "view": {
        "schema": {
            "rowFormatter": {
                "elmType": "div",
                "style": {
                    "display": "flex",
                    "flex-direction": "column",
                    "align-items": "center",
                    "padding": "10px",
                    "border": "1px solid #ddd",
                    "margin": "5px",
                    "width": "200px"
                },
                "children": [
                    {
                        "elmType": "img",
                        "attributes": {
                            "src": "@thumbnail.large"
                        },
                        "style": {
                            "width": "100%",
                            "height": "150px",
                            "object-fit": "cover"
                        }
                    },
                    {
                        "elmType": "div",
                        "txtContent": "[$FileLeafRef]",
                        "style": {
                            "font-weight": "bold",
                            "margin-top": "10px"
                        }
                    },
                    {
                        "elmType": "div",
                        "txtContent": "[$Modified]",
                        "style": {
                            "font-size": "12px",
                            "color": "#666"
                        }
                    }
                ]
            }
        }
    }
}
"@


# Crear la vista y aplicar el formato JSON
$proyectoFields = @("Categoria", "Subcategoria","Subcategoria2","Clase","Estado Documentos","Version","Editor","ShowDetails")
Add-PnPView -List $libraryName -Title $viewName -Fields $proyectoFields -SetAsDefault
Set-PnPView -List $libraryName -Identity $viewName -Values @{CustomFormatter = $viewJson }

# Desconectar la sesión
Disconnect-PnPOnline