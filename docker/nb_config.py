c = get_config()

# The base URL for the notebook server.
# Leading and trailing slashes can be omitted, and will automatically be added.
c.NotebookApp.base_url = '/'

# DISABLED: use %pylab or %matplotlib in the notebook to enable matplotlib.
# c.NotebookApp.pylab = 'disabled'

# The port the notebook server will listen on. c.NotebookApp.port = 8888
c.NotebookApp.port = 8888

# Hashed password to use for web authentication.
# To generate, type in a python/IPython shell:
#   from IPython.lib import passwd; passwd()
# The string should be of the form type:salt:hashed-password.
#c.NotebookApp.password = u'sha1:passwd'

# Whether to enable MathJax for typesetting math/TeX
# When disabled, equations etc. will appear as their untransformed TeX source.
c.NotebookApp.enable_mathjax = True

# The IP address the notebook server will listen on.
c.NotebookApp.ip = '0.0.0.0'

c.NotebookApp.open_browser = False

# Whether to trust or not X-Scheme/X-Forwarded-Proto and X-Real-Ip/X-Forwarded-
# For headerssent by the upstream reverse proxy. Necessary if the proxy handles
# SSL
c.NotebookApp.trust_xheaders = True

# Supply overrides for the tornado.web.Application that the IPython notebook
# uses.
#c.NotebookApp.tornado_settings = {'static_url_prefix':'/ipynb/static/'}

