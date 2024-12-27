# Connect to your site collection root
   # Importar el módulo

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
   # 1. Conexión al sitio principal
   Connect-PnPOnline -Url $SitioPrincipal -Interactive -ClientId "87c053fe-3af4-4d2f-90fe-6df7bd28b450"

# Create the JavaScript content
$scriptContent = @"
function toggleEstado() {
    var context = SP.ClientContext.get_current();
    var list = context.get_web().get_lists().getByTitle('Your List Name');
    var selectedItems = SP.ListOperation.Selection.getSelectedItems(context);
    
    for (var i in selectedItems) {
        var itemId = selectedItems[i].id;
        var listItem = list.getItemById(itemId);
        
        context.load(listItem, 'EstadoDocumentos');
        context.executeQueryAsync(
            function() {
                var currentStatus = listItem.get_item('EstadoDocumentos');
                var newStatus = (currentStatus === 'En Revisión') ? 'Aprobado' : 'En Revisión';
                
                listItem.set_item('EstadoDocumentos', newStatus);
                listItem.update();
                context.executeQueryAsync(
                    function() { 
                        location.reload(); 
                    },
                    function(sender, args) { 
                        alert('Error updating status: ' + args.get_message()); 
                    }
                );
            },
            function(sender, args) {
                alert('Error loading item: ' + args.get_message());
            }
        );
    }
}
"@

# First save the script to a local file
$scriptContent | Out-File -FilePath "toggleEstado.js" -Encoding UTF8

# Then upload the file
Add-PnPFile -Path "toggleEstado.js" -Folder "SiteAssets"

# Add the JavaScript link at Site Collection level
Add-PnPJavaScriptLink -Name "ToggleEstadoScript" `
    -Url "~sitecollection/SiteAssets/toggleEstado.js" `
    -Sequence 1000 `
    -Scope Site