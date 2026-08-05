import subprocess
import fitz # PyMuPDF
import glob
import os

folder = r"f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Paper-materials\flowcharts"

tex_files = ["flowchart_unified.tex", "flowchart_calibration.tex", "flowchart_optimization.tex"]

for tex in tex_files:
    tex_path = os.path.join(folder, tex)
    base_name = os.path.splitext(tex)[0]
    pdf_path = os.path.join(folder, base_name + ".pdf")
    png_path = os.path.join(folder, base_name + ".png")
    svg_path = os.path.join(folder, base_name + ".svg")

    print(f"--- Compiling {tex} ---")
    cmd = f'pdflatex -interaction=nonstopmode -output-directory="{folder}" "{tex_path}"'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if not os.path.exists(pdf_path):
        print(f"ERROR compiling {tex}: {res.stderr}")
        continue

    # Convert to high-res PNG (300 DPI)
    doc = fitz.open(pdf_path)
    page = doc[0]
    pix = page.get_pixmap(dpi=300, alpha=True)
    pix.save(png_path)
    print(f"  -> Generated PNG: {png_path}")

    # Convert to Vector SVG
    svg_text = page.get_svg_image()
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(svg_text)
    print(f"  -> Generated SVG: {svg_path}")

print("All flowcharts compiled and rendered successfully!")
