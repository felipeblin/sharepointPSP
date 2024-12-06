# Asegúrate de que el módulo PnP.PowerShell esté cargado
Import-Module PnP.PowerShell

# Función para manejar errores
function Handle-Error {
    param (
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
}

# Conectar a SharePoint
try {
    Write-Host "Conectando a SharePoint..." -ForegroundColor Cyan
    Connect-PnPOnline -Url "https://socovesa.sharepoint.com/sites/PruebaPSP" -Interactive -ClientId "a5bf8b44-d3e7-4b3b-af7f-dd670a5cc65d"
    Write-Host "Conexión exitosa." -ForegroundColor Green
} catch {
    Handle-Error "Error al conectar a SharePoint: $($_.Exception.Message)"
    exit
}

# Nombre de la página
$pageName = "Resumen Proyecto Inmobiliario Dinámico"

# Eliminar la página si ya existe
if (Get-PnPPage -Identity $pageName -ErrorAction SilentlyContinue) {
    Remove-PnPPage -Identity $pageName -Force
    Write-Host "Página existente eliminada." -ForegroundColor Yellow
}

# Contenido HTML
$htmlContent = @'
<div id="customContent">
    <div id="errorMessages" style="color: red; margin-bottom: 20px;"></div>
    <div id="resumenProyecto">
        <div class="column">
            <h2>Proyecto Inmobiliario</h2>
            <div id="proyectoTable"></div>
        </div>
        <div class="column">
            <h2>Tipos de Departamentos</h2>
            <div id="tiposTable"></div>
            <h2>Fechas Importantes</h2>
            <div id="fechasTable"></div>
        </div>
    </div>
</div>
'@

# Contenido del script
$scriptContent = @'
<script>
(function() {
    function loadScript(url, callback) {
        var script = document.createElement("script");
        script.type = "text/javascript";
        if (script.readyState) {
            script.onreadystatechange = function() {
                if (script.readyState === "loaded" || script.readyState === "complete") {
                    script.onreadystatechange = null;
                    callback();
                }
            };
        } else {
            script.onload = function() {
                callback();
            };
        }
        script.src = url;
        document.getElementsByTagName("head")[0].appendChild(script);
    }

    function initializeApp() {
        console.log("Inicializando aplicación");

        function showError(message) {
            console.error(message);
            $("#errorMessages").append("<p>" + message + "</p>");
        }

        function getListData(listName, retryCount = 0) {
            console.log("Obteniendo datos de la lista: " + listName);
            return $.ajax({
                url: _spPageContextInfo.webAbsoluteUrl + "/_api/web/lists/getbytitle('" + listName + "')/items",
                method: "GET",
                headers: { "Accept": "application/json; odata=verbose" }
            }).fail(function(error) {
                if (retryCount < 3) {
                    console.log("Reintentando obtener datos de " + listName + ". Intento " + (retryCount + 1));
                    return getListData(listName, retryCount + 1);
                }
                showError("Error al cargar datos de " + listName + ": " + JSON.stringify(error));
            });
        }

        function createTable(data, fields) {
            console.log("Creando tabla con " + data.length + " filas");
            if (data.length === 0) {
                return "<p>No se encontraron datos.</p>";
            }
            var table = '<table><tr>';
            fields.forEach(function(field) {
                table += '<th>' + field + '</th>';
            });
            table += '</tr>';
            data.forEach(function(item) {
                table += '<tr>';
                fields.forEach(function(field) {
                    table += '<td>' + (item[field] || '') + '</td>';
                });
                table += '</tr>';
            });
            table += '</table>';
            return table;
        }

        function loadData() {
            console.log("Cargando datos");
            var proyectoFields = ["Zona", "SuperficieNeta", "SuperficieVendible", "Unidades", "CostoDirecto", "CostoTerreno", "MargenIFRS", "IngresoTotal", "TIR", "Inmobiliaria", "CentroCosto", "RolMatriz"];
            var tiposFields = ["TipoDep", "Metraje", "Unidades"];
            var fechasFields = ["FirmaPlanos", "PermisoEdificacion", "InicioExcavacion", "InicioVentas", "ResolucionRecepcion", "EntregaDepartamentos"];

            getListData("Proyecto Inmobiliario").done(function(response) {
                console.log("Datos de Proyecto Inmobiliario recibidos");
                var items = response.d.results;
                $("#proyectoTable").html(createTable(items, proyectoFields));
                $("#fechasTable").html(createTable(items, fechasFields));
            });

            getListData("Tipos de Departamentos").done(function(response) {
                console.log("Datos de Tipos de Departamentos recibidos");
                var items = response.d.results;
                $("#tiposTable").html(createTable(items, tiposFields));
            });
        }

        $(document).ready(function() {
            console.log("Documento listo");
            try {
                loadData();
            } catch (error) {
                showError("Error general: " + error.message);
            }
        });
    }

    function ensureSharePointReady(callback) {
        if (window.SP && SP.SOD && SP.SOD.execute) {
            SP.SOD.execute('sp.js', 'SP.ClientContext', callback);
        } else if (typeof _spPageContextInfo !== 'undefined') {
            callback();
        } else {
            setTimeout(function() { ensureSharePointReady(callback); }, 100);
        }
    }

    loadScript("https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.min.js", function() {
        ensureSharePointReady(initializeApp);
    });
})();
</script>
'@

# Contenido de estilos
$styleContent = @'
<style>
    #resumenProyecto { display: flex; }
    .column { flex: 1; padding: 10px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
</style>
'@

# Crear la página
try {
    $page = Add-PnPPage -Name $pageName -LayoutType Article
    Write-Host "Página creada exitosamente." -ForegroundColor Green
} catch {
    Handle-Error "Error al crear la página: $($_.Exception.Message)"
    exit
}

# Añadir el contenido a la página
try {
    Add-PnPPageTextPart -Page $page -Text $htmlContent
    Add-PnPPageTextPart -Page $page -Text $scriptContent
    Add-PnPPageTextPart -Page $page -Text $styleContent
    Write-Host "Contenido añadido exitosamente a la página." -ForegroundColor Green
} catch {
    Handle-Error "Error al añadir contenido a la página: $($_.Exception.Message)"
}

# Publicar la página
try {
    $page.Publish()
    Write-Host "Página publicada exitosamente." -ForegroundColor Green
} catch {
    Handle-Error "Error al publicar la página: $($_.Exception.Message)"
}

# Desconectar de SharePoint

Write-Host "Desconexión de SharePoint completada." -ForegroundColor Cyan