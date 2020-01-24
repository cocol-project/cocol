.DEFAULT_GOAL := development

development:
	crystal build -Dpreview_mt src/cocol.cr --warnings all --progress


prepare: format ameba test

format:
	crystal tool format

ameba:
	ameba

test:
	crystal spec --error-trace -t -Dpreview_mt $(spec)
