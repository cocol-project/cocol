.DEFAULT_GOAL := development

development:
	shards build cocol -Dpreview_mt --progress --error-trace

quick:
	crystal build src/cocol -Dpreview_mt --progress --error-trace

prepare: format ameba test

format:
	crystal tool format

ameba:
	ameba

test:
	crystal spec --error-trace -t -Dpreview_mt $(spec)
