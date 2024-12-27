
# Conectar a SharePoint (asegúrate de que estás conectado primero)
$SitioPrincipal = "https://socovesa.sharepoint.com/sites/PSP-EESS"
$UrlProyecto = "proyecto-prueba-2"
Get-PnPCustomAction | ForEach-Object { Remove-PnPCustomAction -Identity $_.Id -Force }
$EditListItems = "ViewListItems, AddListItems, EditListItems,BrowseDirectories"


Add-PnPCustomAction -Name "ToggleEstado" `
    -Title "Cambiar Estado" `
    -Location "CommandUI.Ribbon" `
    -RegistrationType List `
    -Description "Button to toggle document status" `
    -Group "SiteActions" `
    -Rights @("EditListItems") `
    -Scope Web `
    -CommandUIExtension @"
<CommandUIExtension>
    <CommandUIDefinitions>
        <CommandUIDefinition Location="Ribbon.ListForm.Display.Manage.Controls._children">
            <Button 
                Id="Ribbon.Documents.ToggleEstado"
                Command="ToggleEstado"
                Image32by32="/_layouts/15/images/placeholder32x32.png"
                LabelText="Cambiar Estado"
                Description="Toggle between En Revisión and Aprobado"
                TemplateAlias="o1" />
        </CommandUIDefinition>
    </CommandUIDefinitions>
    <CommandUIHandlers>
        <CommandUIHandler
            Command="ToggleEstado"
            CommandAction="javascript:toggleEstado();" />
    </CommandUIHandlers>
</CommandUIExtension>
"@