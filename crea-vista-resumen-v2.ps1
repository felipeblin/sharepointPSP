# First list all fields to get internal names
Write-Host "`nObteniendo nombres internos de los campos..." -ForegroundColor Yellow
try {
    $lista = Get-PnPList -Identity "Proyecto Inmobiliario" -ErrorAction Stop
    $campos = Get-PnPField -List $lista
    
    # Define CustomView XML
    $customView = @"
<View Type='HTML' DisplayName='Galeria 3'>
    <Method Name='HTML' />
    <Format>
        <HTML>
            <![CDATA[
                <div class="proyecto-card">
                    <!-- Título y ID del proyecto -->
                    <div class="proyecto-titulo">
                        <xsl:value-of select="@Title"/> 
                        <span class="proyecto-id"><xsl:value-of select="@ProyectoID"/></span>
                    </div>

                    <!-- Información General -->
                    <div class="proyecto-seccion">
                        <h3>Información General</h3>
                        <div class="proyecto-info-grid">
                            <div class="proyecto-campo">
                                <span class="proyecto-etiqueta">Zona:</span>
                                <span class="proyecto-valor"><xsl:value-of select="@Zona"/></span>
                            </div>
                            <div class="proyecto-campo">
                                <span class="proyecto-etiqueta">Superficie Neta:</span>
                                <span class="proyecto-valor"><xsl:value-of select="@SuperficieNeta"/></span>
                            </div>
                            <!-- Continuar con otros campos... -->
                        </div>
                    </div>

                    <!-- Información Financiera -->
                    <div class="proyecto-seccion">
                        <h3>Información Financiera</h3>
                        <div class="proyecto-info-grid">
                            <div class="proyecto-campo">
                                <span class="proyecto-etiqueta">Costo Directo:</span>
                                <span class="proyecto-valor"><xsl:value-of select="@CostoDirecto"/></span>
                            </div>
                            <!-- Continuar con otros campos... -->
                        </div>
                    </div>

                    <!-- Fechas y Documentación -->
                    <div class="proyecto-seccion">
                        <h3>Fechas y Documentación</h3>
                        <div class="proyecto-info-grid">
                            <div class="proyecto-campo">
                                <span class="proyecto-etiqueta">Rol Matriz:</span>
                                <span class="proyecto-valor"><xsl:value-of select="@RolMatriz"/></span>
                            </div>
                            <!-- Continuar con otros campos... -->
                        </div>
                    </div>
                </div>

                <style>
                    .proyecto-card {
                        background: #f8f9fa;
                        padding: 20px;
                        margin: 10px;
                        border-radius: 8px;
                        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    }
                    .proyecto-titulo {
                        font-size: 24px;
                        font-weight: bold;
                        margin-bottom: 20px;
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                    }
                    .proyecto-id {
                        background: #007bff;
                        color: white;
                        padding: 4px 8px;
                        border-radius: 4px;
                        font-size: 16px;
                    }
                    .proyecto-seccion {
                        margin-bottom: 20px;
                    }
                    .proyecto-seccion h3 {
                        font-size: 18px;
                        color: #333;
                        margin-bottom: 15px;
                        border-bottom: 1px solid #ddd;
                        padding-bottom: 5px;
                    }
                    .proyecto-info-grid {
                        display: grid;
                        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
                        gap: 10px;
                    }
                    .proyecto-campo {
                        display: flex;
                        justify-content: space-between;
                        padding: 5px 0;
                    }
                    .proyecto-etiqueta {
                        font-weight: 500;
                        color: #555;
                    }
                    .proyecto-valor {
                        color: #333;
                    }
                </style>
            ]]>
        </HTML>
    </Format>
    <ViewFields>
        <FieldRef Name="Title"/>
        <FieldRef Name="ProyectoID"/>
        <FieldRef Name="Zona"/>
        <FieldRef Name="SuperficieNeta"/>
        <FieldRef Name="SuperficieVendible"/>
        <FieldRef Name="TotalConstruido"/>
        <FieldRef Name="ConstructibilidadUsada"/>
        <FieldRef Name="Incidencia"/>
        <FieldRef Name="TiposDepartamentos"/>
        <FieldRef Name="Inmobiliaria"/>
        <FieldRef Name="CostoDirecto"/>
        <FieldRef Name="CostoTerreno"/>
        <FieldRef Name="IngresoTotal"/>
        <FieldRef Name="MargenIFRS"/>
        <FieldRef Name="TIR"/>
        <FieldRef Name="Unidades"/>
        <FieldRef Name="Estacionamientos"/>
        <FieldRef Name="Bodegas"/>
        <FieldRef Name="RolMatriz"/>
        <FieldRef Name="FirmaPlanos"/>
        <FieldRef Name="PermisoEdificacion"/>
        <FieldRef Name="InicioVentas"/>
        <FieldRef Name="InicioExcavacion"/>
        <FieldRef Name="ResolucionRecepcion"/>
        <FieldRef Name="EntregaDepartamentos"/>
    </ViewFields>
    <Query>
        <OrderBy>
            <FieldRef Name="Title" Ascending="True"/>
        </OrderBy>
    </Query>
    <RowLimit>30</RowLimit>
</View>
"@

    # Create the view with custom format
    Add-PnPView -List $lista `
        -Title "Galeria 3" `
        -Fields $validFields `
        -ViewType Html `
        -CustomView $customView `
        -SetAsDefault

    Write-Host "`n✓ Vista creada exitosamente con formato personalizado" -ForegroundColor Green

} catch {
    Write-Host "`n✕ Error: $_" -ForegroundColor Red
    Write-Host "  Detalles adicionales del error:" -ForegroundColor Yellow
    Write-Host "  - Asegúrese de que la lista existe" -ForegroundColor Yellow
    Write-Host "  - Verifique los permisos de acceso" -ForegroundColor Yellow
    Write-Host "  - Confirme que los campos existen en la lista" -ForegroundColor Yellow
    exit
}