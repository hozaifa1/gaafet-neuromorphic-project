import markdown
import pdfkit
import sys
import os

def convert_md_to_pdf(md_path, pdf_path):
    # Ensure the input file exists
    if not os.path.exists(md_path):
        print(f"Error: The file '{md_path}' was not found.")
        return

    # 1. Read the Markdown file
    with open(md_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    # 2. Convert Markdown to HTML
    # The 'extra' extension enables tables, fenced code blocks, and footnotes
    html_body = markdown.markdown(md_text, extensions=['extra'])

    # 3. Add CSS for clean formatting
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; margin: 40px; color: #333; }}
            h1, h2, h3, h4 {{ color: #111; border-bottom: 1px solid #eee; padding-bottom: 5px; }}
            table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
            th, td {{ border: 1px solid #ddd; padding: 10px; text-align: left; }}
            th {{ background-color: #f8f9fa; font-weight: bold; }}
            code {{ background-color: #f1f1f1; padding: 3px 6px; border-radius: 4px; font-family: monospace; font-size: 0.9em; }}
            pre {{ background-color: #f8f9fa; padding: 15px; overflow-x: auto; border-radius: 5px; border: 1px solid #ddd; }}
            blockquote {{ border-left: 4px solid #007bff; margin-left: 0; padding-left: 15px; color: #555; font-style: italic; }}
            ul, ol {{ margin-bottom: 20px; }}
        </style>
    </head>
    <body>
        {html_body}
    </body>
    </html>
    """

    # 4. Convert HTML to PDF using pdfkit
    try:
        # options parameter can be used to set margins, page size, etc.
        options = {
            'page-size': 'A4',
            'margin-top': '0.75in',
            'margin-right': '0.75in',
            'margin-bottom': '0.75in',
            'margin-left': '0.75in',
            'encoding': "UTF-8",
        }
        pdfkit.from_string(html_content, pdf_path, options=options)
        print(f"Success! '{md_path}' has been successfully converted to '{pdf_path}'.")
    except OSError as e:
        print("Error: Could not find wkhtmltopdf.")
        print("Please ensure wkhtmltopdf is installed and added to your system's PATH.")
        print("Details:", e)

if __name__ == "__main__":
    # Check if the correct number of arguments are passed via CMD
    if len(sys.argv) != 3:
        print("Usage: python md_to_pdf.py <input_file.md> <output_file.pdf>")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        convert_md_to_pdf(input_file, output_file)