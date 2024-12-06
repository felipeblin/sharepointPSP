import svgwrite

# Create a new SVG file representing stacked documents
dwg = svgwrite.Drawing("documentos_apilados2.svg", profile='tiny', size=("150px", "150px"))

# Draw the base of the document
dwg.add(dwg.rect(insert=(25, 25), size=(100, 100), rx=10, ry=10, fill="#f0f0f0", stroke="black", stroke_width=2))

# Draw inner rectangles to represent lines of text on the document
dwg.add(dwg.rect(insert=(35, 45), size=(80, 10), rx=5, ry=5, fill="white", stroke="black", stroke_width=1))
dwg.add(dwg.rect(insert=(35, 65), size=(80, 10), rx=5, ry=5, fill="white", stroke="black", stroke_width=1))
dwg.add(dwg.rect(insert=(35, 85), size=(80, 10), rx=5, ry=5, fill="white", stroke="black", stroke_width=1))

# Save the SVG file
dwg.save()

"documentos_apilados2.svg"