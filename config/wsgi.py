"""
WSGI config for netdelta project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/1.9/howto/deployment/wsgi/
"""
import os
import sys
import site

venv_root = "/home/iantibble/jango/netdelta304"

# Add the site-packages of the chosen virtualenv to work with
site.addsitedir(venv_root + '/local/lib/python3.8/site-packages')

# Add the app's directory to the PYTHONPATH
sys.path.append('/home/iantibble/netdelta_sites/SITE/netdelta/')
sys.path.append('/home/iantibble/netdelta_sites/SITE/netdelta/netdelta')

os.environ['DJANGO_SETTINGS_MODULE'] = 'netdelta.settings'

# Activate your virtual env
#activate_env=os.path.expanduser(venv_root + "/bin/activate_this.py")
#execfile(activate_env, dict(__file__=activate_env))

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
