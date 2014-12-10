gollum:
	#git clone git@github.com:gollum/gollum
	mkdir -p gollum && cd gollum && wget https://github.com/klorenz/gollum/tarball/master/ -O- | tar xzf - --strip-components=1

bundle:
	cd gollum && bundle install --path gems

install-rest2html:
	DEST=$$(find gollum -name rest2html) ;\
	cp rest2html $$DEST ;\
	cp sphinx_conf.py $$(dirname $$DEST)/conf.py

# install-markups:
	# cp rest2html $$(find gollum -name markups.rb | grep github-markup)

gollum-sphinx: gollum bundle
