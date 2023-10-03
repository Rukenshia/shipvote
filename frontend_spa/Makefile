.PHONY: help build copy-html

# run build and then copy-html
all: build copy-html

# run vite build
build:
	npm run build # replace with your actual command

# copy index.html to all subdirectories under dist/apps
copy-html:
	for dir in $$(find dist/apps -mindepth 1 -type d); do \
		cp src/index.html $$dir/index.html; \
	done
