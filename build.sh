#!/bin/sh

mkdir docs

unzip webHelpN2-all.zip -d docs

git subtree push --prefix docs origin gh-pages