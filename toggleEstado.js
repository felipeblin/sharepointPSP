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
