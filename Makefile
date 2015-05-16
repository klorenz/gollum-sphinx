gollum:
	#git clone git@github.com:gollum/gollum
	mkdir -p gollum && cd gollum && wget https://github.com/klorenz/gollum/tarball/master/ -O- | tar xzf - --strip-components=1

bundle:
	cd gollum && bundle install --path gems

install-rest2html:
	DEST=$$(find gollum -name rest2html) ; echo $$DEST ; DEST_DIR=$$(dirname $$DEST) ; \
	if [ -e $$DEST/rest2html ] ; then rm $$DEST/rest2html ; fi ;\
	    cp rest2html $$DEST ;\
	if [ -e $$DEST_DIR/conf.py ] ; then rm $$DEST_DIR/conf.py ; fi ;\
	    cp sphinx_conf.py $$DEST_DIR/conf.py ;\
	cp rest.js gollum/lib/gollum/public/gollum/javascript/editor/langs/

# install-markups:
	# cp rest2html $$(find gollum -name markups.rb | grep github-markup)

run-gollum:
	export GOLLUM_REPO=$(PWD) ;\
        cd gollum ;\
        bundle exec bin/gollum $(GOLLUM_REPO) --template ../templates


gollum-sphinx: gollum bundle

_static/wiki.js: src/wiki.coffee
	coffee -c -o _static/ $<
	if [ -d ../mw-sphinx-doc ] ; then \
		cp $@ ../mw-sphinx-doc/_static ;\
	fi

rest.js: rest.coffee
	coffee -c -o . $<

.PHONY: gollum
