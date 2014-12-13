# Configuration file for ipython-nbconvert.

c = get_config()

#------------------------------------------------------------------------------
# NbConvertApp configuration
#------------------------------------------------------------------------------

# The export format to be used.
c.NbConvertApp.export_format = 'latex'

# PostProcessor class used to write the  results of the conversion
c.NbConvertApp.postprocessor_class = 'pdf'

# Create a massive crash report when IPython encounters what may be an internal
# error.  The default is to append a short message to the usual traceback
c.NbConvertApp.verbose_crash = True

#------------------------------------------------------------------------------
# LatexExporter configuration
#------------------------------------------------------------------------------

# 
c.LatexExporter.template_path = ['.']

# 
# c.LatexExporter.template_extension = '.tplx'

# Name of the template file to use
c.LatexExporter.template_file = 'cjk'

#------------------------------------------------------------------------------
# PDFPostProcessor configuration
#------------------------------------------------------------------------------

# Shell command used to run bibtex.
# c.PDFPostProcessor.bib_command = ['bibtex', '{filename}']

# Whether or not to display the output of the compile call.
# c.PDFPostProcessor.verbose = False

# How many times pdflatex will be called.
# c.PDFPostProcessor.latex_count = 3

# default highlight language
# c.PDFPostProcessor.default_language = 'ipython'

# Filename extensions of temp files to remove after running.
# c.PDFPostProcessor.temp_file_exts = ['.aux', '.bbl', '.blg', '.idx', '.log', '.out']

# Shell command used to compile PDF.
c.PDFPostProcessor.latex_command = ['xelatex', '{filename}']

