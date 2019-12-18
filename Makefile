.DEFAULT_GOAL := development

development:
	crystal build -Dpreview_mt src/cocol.cr --warnings all --progress


prepare: ameba format

ameba:
	ameba

format:
	crystal tool format

test:
	crystal spec --error-trace
