import os, sys
from os.path import join

repo       = os.environ.get('GOLLUM_REPO')
work_dir   = os.environ.get('GOLLUM_WORK_DIR', repo)
confdir    = os.environ.get('GOLLUM_SPHINX_CONF_DIR', work_dir)

#import rpdb2 ; rpdb2.start_embedded_debugger('foo')

conffile = join(confdir, "conf.py")

from sphinx.builders.html import StandaloneHTMLBuilder

_orig_setup = None


#
# import symbols from original conf file manually
#
import imp
with open(conffile, 'r') as config_file:
    from sphinx.util.osutil import cd
    mod = imp.new_module("target_conf")
    mod.__file__ = conffile

    with cd(os.path.dirname(conffile)):
        exec(config_file, mod.__dict__)

    sys.modules['target_conf'] = mod
    G = globals()
    for (k,v) in mod.__dict__.items():
        if k not in G:
            G[k] = v
        if k == "setup":
            G["_orig_setup"] = v


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
