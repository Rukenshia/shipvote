.PHONY: help build copy-html

# run build and then copy-html
all: build assets.zip

# run vite build
build:
	npx vite build

assets.zip: dist
	cd dist && zip -r ../assets.zip ./

