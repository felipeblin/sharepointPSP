import svgwrite
import os
from cairosvg import svg2png

# Configuración
STATES = ["En Revisión", "Aprobado", "Rechazado"]
STATE_COLORS = {"En Revisión": "orange", "Aprobado": "green", "Rechazado": "red"}
STATE_SYMBOLS = {"En Revisión": "?", "Aprobado": "✓", "Rechazado": "✗"}
HITOS = [1, 2, 3, 4]
OUTPUT_DIR = "./iconos"
ICON_SIZE = (150, 150)

def create_stacked_documents_1(dwg):
    """Opción 1: Diseño original mejorado"""
    dwg.add(dwg.rect(insert=(20, 30), size=(110, 100), rx=5, ry=5, fill='#e0e0e0'))
    dwg.add(dwg.rect(insert=(15, 20), size=(110, 100), rx=5, ry=5, fill='#f0f0f0'))
    dwg.add(dwg.rect(insert=(10, 10), size=(110, 100), rx=5, ry=5, fill='white', stroke='#d0d0d0', stroke_width=1))
    
    dwg.add(dwg.rect(insert=(20, 20), size=(70, 10), rx=2, ry=2, fill='#4a90e2'))
    for y in range(40, 91, 15):
        dwg.add(dwg.line(start=(20, y), end=(100, y), stroke='#d0d0d0', stroke_width=1))
    
    clip_path = dwg.path(d="M100,5 L110,5 L110,20 L100,20 Z", fill="#a0a0a0")
    dwg.add(clip_path)

def create_stacked_documents_2(dwg):
    """Opción 2: Diseño minimalista con bordes redondeados"""
    dwg.add(dwg.rect(insert=(10, 10), size=(130, 130), rx=15, ry=15, fill='#f5f5f5', stroke='#d0d0d0', stroke_width=2))
    dwg.add(dwg.rect(insert=(20, 20), size=(110, 110), rx=10, ry=10, fill='white', stroke='#e0e0e0', stroke_width=1))
    
    for y in range(40, 111, 20):
        dwg.add(dwg.line(start=(30, y), end=(120, y), stroke='#e0e0e0', stroke_width=1))

def create_stacked_documents_3(dwg):
    """Opción 3: Diseño de carpeta"""
    # Cuerpo de la carpeta
    dwg.add(dwg.path(d="M10,30 L140,30 L140,140 L10,140 Z", fill="#ffd700"))
    # Pestaña de la carpeta
    dwg.add(dwg.path(d="M10,30 C20,5 50,5 60,30", fill="#ffd700", stroke="#d4af37", stroke_width=1))
    # Sombra interna
    dwg.add(dwg.rect(insert=(15, 35), size=(120, 100), fill='white', opacity=0.6))
    
    for y in range(50, 121, 20):
        dwg.add(dwg.line(start=(25, y), end=(125, y), stroke='#d4af37', stroke_width=1))

def create_stacked_documents_4(dwg):
    """Opción 4: Diseño elegante"""
    # Fondo con gradiente
    gradient = dwg.linearGradient((0, 0), (0, 1))
    gradient.add_stop_color(0, "#f6f6f6")
    gradient.add_stop_color(1, "#e0e0e0")
    dwg.defs.add(gradient)
    
    dwg.add(dwg.rect(insert=(10, 10), size=(130, 130), rx=10, ry=10, fill=gradient.get_paint_server()))
    
    # Documento principal
    dwg.add(dwg.rect(insert=(20, 20), size=(110, 110), rx=5, ry=5, fill='white', stroke='#c0c0c0', stroke_width=1))
    
    # Líneas decorativas
    for y in range(40, 121, 20):
        dwg.add(dwg.line(start=(30, y), end=(120, y), stroke='#d0d0d0', stroke_width=1))
    
    # Marca de agua elegante
    dwg.add(dwg.text("Elegant", insert=(75, 75), font_size='24px', fill='#f0f0f0', 
                     text_anchor='middle', dominant_baseline='central', font_family="Arial, sans-serif", opacity=0.5))

def create_stacked_documents_5(dwg):
    """Opción 5: Diseño profesional"""
    # Fondo
    dwg.add(dwg.rect(insert=(0, 0), size=(150, 150), fill='#f0f0f0'))
    
    # Documento principal
    dwg.add(dwg.rect(insert=(10, 10), size=(130, 130), rx=2, ry=2, fill='white', stroke='#333', stroke_width=2))
    
    # Líneas de texto
    for y in range(30, 121, 15):
        dwg.add(dwg.line(start=(20, y), end=(130, y), stroke='#e0e0e0', stroke_width=1))
    
    # Logotipo corporativo
    dwg.add(dwg.circle(center=(30, 30), r=10, fill='#4a4a4a'))
    dwg.add(dwg.text("P", insert=(30, 33), font_size='14px', fill='white', 
                     text_anchor='middle', dominant_baseline='central', font_family="Arial, sans-serif"))

def create_stacked_documents_6(dwg):
    """Opción 6: Diseño juguetón"""
    # Fondo colorido
    dwg.add(dwg.rect(insert=(0, 0), size=(150, 150), fill='#FFD700'))
    
    # Documento principal con forma de nube
    cloud_path = dwg.path(d="M25,60 a20,20 0 0,1 0,-40 h100 a20,20 0 0,1 0,40 h-10 a10,10 0 0,1 -10,10 h-70 a10,10 0 0,0 -10,10 z", 
                          fill='white', stroke='#FFA500', stroke_width=2)
    dwg.add(cloud_path)
    
    # Elementos decorativos
    dwg.add(dwg.circle(center=(40, 40), r=15, fill='#FF6B6B'))
    dwg.add(dwg.circle(center=(110, 40), r=15, fill='#4ECDC4'))
    dwg.add(dwg.rect(insert=(70, 70), size=(30, 30), fill='#45B7D1', rx=5, ry=5))
    
    # Texto juguetón
    dwg.add(dwg.text("Fun!", insert=(75, 100), font_size='24px', fill='#FF6B6B', 
                     text_anchor='middle', dominant_baseline='central', font_family="Comic Sans MS, cursive"))

def add_state_circle(dwg, state):
    """Añade el círculo de estado con su símbolo"""
    dwg.add(dwg.circle(center=(30, 30), r=15, fill=STATE_COLORS[state]))
    if state == "En Revisión":
        dwg.add(dwg.text("?", insert=(30, 35), font_size='24px', fill='white', 
                         text_anchor='middle', dominant_baseline='central', font_family="Arial, sans-serif"))
    elif state == "Aprobado":
        dwg.add(dwg.path(d="M23,30 L26,33 L32,27", stroke='white', fill='none', stroke_width=2))
    elif state == "Rechazado":
        dwg.add(dwg.path(d="M25,25 L35,35 M35,25 L25,35", stroke='white', fill='none', stroke_width=2))

def add_hito_circle(dwg, hito):
    """Añade el círculo de hito con su número"""
    dwg.add(dwg.circle(center=(120, 120), r=15, fill='#4a90e2'))
    dwg.add(dwg.text(str(hito), insert=(120, 120), font_size='16px', fill='white', 
                     text_anchor='middle', dominant_baseline='central', font_family="Arial, sans-serif"))

def generate_icon(state, hito, design_option):
    """Genera un icono SVG para una combinación específica de estado e hito"""
    filename = f"doc_{state}_{hito}_option{design_option}"
    dwg = svgwrite.Drawing(f"{OUTPUT_DIR}/{filename}.svg", size=ICON_SIZE)
    
    design_functions = {
        1: create_stacked_documents_1,
        2: create_stacked_documents_2,
        3: create_stacked_documents_3,
        4: create_stacked_documents_4,
        5: create_stacked_documents_5,
        6: create_stacked_documents_6
    }
    
    if design_option not in design_functions:
        raise ValueError("Invalid design option. Choose 1, 2, 3, 4, 5, or 6.")
    
    design_functions[design_option](dwg)
    add_state_circle(dwg, state)
    add_hito_circle(dwg, hito)
    
    dwg.save()
    
    # Convertir SVG a PNG
    with open(f"{OUTPUT_DIR}/{filename}.svg", 'rb') as svg_file:
        svg_data = svg_file.read()
    png_data = svg2png(bytestring=svg_data,
                       output_width=ICON_SIZE[0],
                       output_height=ICON_SIZE[1])
    with open(f"{OUTPUT_DIR}/{filename}.png", 'wb') as png_file:
        png_file.write(png_data)

def main(design_option):
    """Función principal para generar todos los iconos"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for state in STATES:
        for hito in HITOS:
            if state != "Aprobado" and hito > 1:
                continue
            generate_icon(state, hito, design_option)
    
    print(f"Iconos generados exitosamente en el directorio: {OUTPUT_DIR}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2 or sys.argv[1] not in ['1', '2', '3', '4', '5', '6']:
        print("Usage: python script.py [1|2|3|4|5|6]")
        print("1: Original mejorado, 2: Minimalista, 3: Carpeta")
        print("4: Elegante, 5: Profesional, 6: Juguetón")
        sys.exit(1)
    
    design_option = int(sys.argv[1])
    main(design_option)