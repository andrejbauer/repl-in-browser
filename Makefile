PYTHON ?= python3
PORT ?= 8000

JSFLAGS = -use-menhir -menhir "menhir --explain" -use-ocamlfind -plugin-tag "package(js_of_ocaml.ocamlbuild)"
FLAGS = $(JSFLAGS) -libs unix
OCAMLBUILD ?= ocamlbuild

.PHONY: serve clean repl.js lambda.native

default: repl.js

_build/repl.js:
	$(OCAMLBUILD) $(JSFLAGS) src/repl.js

lambda.native:
	$(OCAMLBUILD) $(FLAGS) src/lambda.native

repl.js: _build/repl.js
	ln -fs _build/src/repl.js .

serve: repl.js
	python3 -m http.server $(PORT)

clean:
	$(OCAMLBUILD) -clean
