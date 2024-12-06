# Conectar a SharePoint
try {
    Write-Host "Conectando a SharePoint..." -ForegroundColor Cyan
    Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive
    Write-Host "Conexión exitosa." -ForegroundColor Green
} catch {
    Write-Host "Error al conectar a SharePoint: $($_.Exception.Message)" -ForegroundColor Red
    exit
}
# Asumiendo que ya estás conectado a SharePoint con Connect-PnPOnline

# Nombre de la biblioteca y de la nueva vista
$listTitle = "DocEESS"
# Nombre de la vista
$viewName = "Vista Agrupada por Carpetas"

# Borrar la vista existente si existe
$existingView = Get-PnPView -List $listTitle -Identity $viewName -ErrorAction SilentlyContinue
if ($existingView) {
    Write-Host "Borrando vista existente '$viewName'..." -ForegroundColor Yellow
    Remove-PnPView -List $listTitle -Identity $viewName
    Write-Host "Vista '$viewName' borrada exitosamente." -ForegroundColor Green
}
# Terminar la ejecución
exit
# Crear una nueva vista básica
try {
    $viewFields = @("DocIcon", "LinkFilename", "Clase", "Modified", "Editor")
    $view = Add-PnPView -List $listTitle -Title $viewName -Fields $viewFields -ViewType 'None' -SetAsDefault

    if ($view) {
        Write-Host "Vista '$viewName' creada exitosamente." -ForegroundColor Green
        
        # Configuración básica de la vista
        $viewXml = @"
<View Type="None" DisplayName="$viewName" Url="$($view.ServerRelativeUrl)" Level="1" BaseViewID="1" ContentTypeID="0x" ImageUrl="/_layouts/15/images/generic.png?rev=47">
  <Query>
    <OrderBy>
      <FieldRef Name="FileLeafRef" Ascending="TRUE"/>
    </OrderBy>
  </Query>
  <ViewFields>
    <FieldRef Name="DocIcon" />
    <FieldRef Name="LinkFilename" />
    <FieldRef Name="Clase" />
    <FieldRef Name="Modified" />
    <FieldRef Name="Editor" />
  </ViewFields>
  <RowLimit Paged="TRUE">100</RowLimit>
  <Toolbar Type="Standard" />
</View>
"@

        Set-PnPView -List $listTitle -Identity $view.Id -Values @{ViewQuery = $viewXml}
        Write-Host "Configuración básica de la vista aplicada." -ForegroundColor Green

        # Verificar la configuración
        $updatedView = Get-PnPView -List $listTitle -Identity $viewName
        Write-Host "Configuración final de la vista:" -ForegroundColor Cyan
        $updatedView | Format-List Title, ViewType, ViewFields
        
        Write-Host "ViewQuery:" -ForegroundColor Cyan
        Write-Host $updatedView.ViewQuery
    }
    else {
        Write-Host "No se pudo crear la vista." -ForegroundColor Red
    }
}
catch {
    Write-Host "Error al crear o configurar la vista: $($_.Exception.Message)" -ForegroundColor Red
}
