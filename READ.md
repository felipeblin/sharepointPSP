El proyecto considera un Sitio Maestro para manejar los documentos de arquitectura y construcción entre otros. El sitio Maestro el cual tendrá una serie de subsidios, uno por cada proyecto inmobiliario. Deberá el inheritance con el sitio Maestro.  Se pretende crear una estructura visual especial segúnda requerimientos del usuario probablemente modificando  las vistas con estructuras json para los CSS
EL directorio de versión vigente es el directorio donde deberían estasr los codigos probados
Hasta el mometo lo validado es:
**** Se creó el sitio maestro:
     "https://socovesa.sharepoint.com/sites/PSP-EESS"  notar que quedo con el nombre PSP como titulo
     Nota: en Sharepoint Admin Center se debe habilitar Custom Script. Buscar en Active Sites->Seleccionar el sitio y en settings está la opción de habilitar
     Bajo este sitio se crearán los subsitios
     **** Se debe usar crea-proyecto.ps1 que llama a los scripts:
     **** Crea-estructura crea el árbol del proyecto y los metadatos asociados  
     **** Crea-vista-DocEESS crea la vista y carga el archivo de formato formatoConMetaData.json   
     **** Crea-resumen-psp .ps1 crea el resumen del proyecto a través de una Lista: Proyecto Inmobiliario. según se pidió (La vista que se crea no queda como Gallery)

**** Se debe crear una vista manualmente de tipo Gallery y se setea cómo seleccionada por defecto en "Edit current View" en el menú de la vista
**** Luego se debe ejecutar Crea-Vista-resumen.ps1 formatea la vista creada en el paso anterior (chequear que el nombre sea el mismo) usa archivo formatoResumen.json
