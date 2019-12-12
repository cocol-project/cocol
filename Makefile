.DEFAULT_GOAL := development

development:
	crystal build -Dpreview_mt src/cocol.cr --warnings all --progress
