import os, sys
from os.path import join

repo       = os.environ.get('GOLLUM_REPO')
work_dir   = os.environ.get('GOLLUM_WORK_DIR', repo)
confdir    = os.environ.get('GOLLUM_SPHINX_CONF_DIR', work_dir)

conffile = join(confdir, "conf.py")

from sphinx.builders.html import StandaloneHTMLBuilder

import imp
with open(conffile, 'r') as config_file:
    mod = imp.new_module("target_conf")
    mod.__file__ = conffile
    exec(config_file, mod.__dict__)


if "setup" in dir():
    _orig_setup = setup
else:
    _orig_setup = None

class GollumBuilder(StandaloneHTMLBuilder):
    name = "gollum"
    theme = "gollum"

    def _get_translations_js(self, *args, **kargs):
        return None

    def get_outdated_docs(self, *args, **kargs):
        return None

    def build_specific(self, content):
        pass


    #def init_highlighter


def setup(app):
    if _orig_setup:
        _orig_setup(app)

    app.add_builder(GollumBuilder)
