
$libraryName = "Documentos del Proyecto"

$ViewFields = @("LinkFilename", "TipoDocumento", "Estado")
$ViewName = "VistaMosaico"
# Comprobar si la vista existe y borrarla
$View = Get-PnPView -List $List -Identity $ViewName -ErrorAction SilentlyContinue
if ($View -ne $null) {
    Remove-PnPView -List $List -Identity $View.Id -Force
    Write-Host "Vista '$ViewName' eliminada"
}
# Crear una nueva vista
$ViewFields = @("LinkFilename", "TipoDocumento", "Estado")
$NewView = Add-PnPView -List $LibraryName -Title $ViewName -ViewType Html -Paged -Fields $ViewFields
Write-Host "Vista '$ViewName' creada"

# JSON para la vista de mosaico
$TileViewJSON = @'
{
    "$schema": "https://developer.microsoft.com/json-schemas/sp/view-formatting.schema.json",
    "tiles": {
        "formatter": {
            "elmType": "a",
            "attributes": {
                "href": "[$FileRef]",
                "style": {
                    "display": "block",
                    "padding": "10px",
                    "background-color": "#f3f2f1",
                    "border": "1px solid #edebe9",
                    "border-radius": "6px",
                    "box-shadow": "2px 2px 5px rgba(0,0,0,0.1)",
                    "text-align": "center",
                    "text-decoration": "none",
                    "color": "black"
                }
            },
            "children": [
                {
                    "elmType": "div",
                    "style": {
                        "font-size": "14px",
                        "font-weight": "600",
                        "margin-bottom": "4px"
                    },
                    "txtContent": "[$FileLeafRef]"
                },
                {
                    "elmType": "div",
                    "style": {
                        "font-size": "12px"
                    },
                    "txtContent": "[$TipoDocumento]"
                },
                {
                    "elmType": "div",
                    "style": {
                        "font-size": "12px"
                    },
                    "txtContent": "[$Estado]"
                }
            ]
        }
    }
}
'@

# Aplicar el JSON a la vista usando CSOM
$Ctx = Get-PnPContext
$ViewCsom = $List.Views.GetById($NewView.Id)
$ViewCsom.CustomFormatter = $TileViewJSON
$ViewCsom.Update()
$Ctx.ExecuteQuery()

Write-Host "Vista '$ViewName' actualizada a modo mosaico con formato JSON"

