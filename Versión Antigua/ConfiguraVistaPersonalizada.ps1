# Conectar a SharePoint
Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive

# Nombre de la biblioteca
$libraryName = "Documentos del Proyecto"

# Crear la biblioteca si no existe
$library = Get-PnPList -Identity $libraryName -ErrorAction SilentlyContinue
if ($null -eq $library) {
    New-PnPList -Title $libraryName -Template DocumentLibrary
    Write-Host "Biblioteca '$libraryName' creada." -ForegroundColor Green
}

# Definir campos personalizados
$fields = @(
    @{Name="TipoDocumento"; Type="Choice"; Choices="Arquitectura,Comercial,Técnico,Inmobiliario,ODI"},
    @{Name="Estado"; Type="Choice"; Choices="Pendiente,En Progreso,Completado,No Aplica"}
)

# Crear campos personalizados
foreach ($field in $fields) {
    $existingField = Get-PnPField -List $libraryName -Identity $field.Name -ErrorAction SilentlyContinue
    if ($null -eq $existingField) {
        Add-PnPField -List $libraryName -DisplayName $field.Name -InternalName $field.Name -Type $field.Type -Choices $field.Choices.Split(",")
        Write-Host "Campo '$($field.Name)' creado." -ForegroundColor Green
    }
}

# Nombre de la vista personalizada
$viewName = "Vista Documentos Proyecto"

# Eliminar la vista si ya existe
$existingView = Get-PnPView -List $libraryName -Identity $viewName -ErrorAction SilentlyContinue
if ($null -ne $existingView) {
    Remove-PnPView -List $libraryName -Identity $viewName
    Write-Host "Vista existente '$viewName' eliminada." -ForegroundColor Yellow
}

# Crear nueva vista personalizada de tipo Tiles
$viewFields = @("DocIcon", "LinkFilename", "TipoDocumento", "Estado", "Modified", "Editor", "_UIVersionString")
$view = Add-PnPView -List $libraryName -Title $viewName -Fields $viewFields -SetAsDefault

# Configurar la vista como Tiles y agregar agrupación
$view = Get-PnPView -List $libraryName -Identity $viewName
$view.ViewType = [Microsoft.SharePoint.Client.ViewType]::Tiles
$viewQuery = "<GroupBy Collapse='FALSE'><FieldRef Name='TipoDocumento' /></GroupBy>"
$view.ViewQuery = $viewQuery
$view.Update()
$view.Context.ExecuteQuery()

Write-Host "Vista '$viewName' creada y configurada como mosaicos con agrupación." -ForegroundColor Green

# Aplicar formato JSON para iconos de estado
$jsonFormat = @"
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json",
  "elmType": "div",
  "children": [
    {
      "elmType": "span",
      "attributes": {
        "iconName": {
          "operator": "=",
          "operands": [
            "[$Estado]",
            {
              "Pendiente": "CircleRing",
              "En Progreso": "CircleHalfFull",
              "Completado": "CheckMark",
              "No Aplica": "StatusCircleBlock"
            }
          ]
        }
      },
      "style": {
        "padding-right": "8px"
      }
    },
    {
      "elmType": "span",
      "txtContent": "[$Estado]"
    }
  ]
}
"@

Set-PnPField -List $libraryName -Identity "Estado" -Values @{CustomFormatter=$jsonFormat}
Write-Host "Formato personalizado aplicado al campo 'Estado'." -ForegroundColor Green

Write-Host "Configuración de la vista personalizada en mosaicos completada." -ForegroundColor Green