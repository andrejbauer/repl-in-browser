PYTHON ?= python3
PORT ?= 8000

.PHONY: serve clean js

default: build

serve: js
	python3 -m http.server $(PORT)

js:
	ocamlbuild -use-ocamlfind -cflags -linkpkg -plugin-tag "package(js_of_ocaml.ocamlbuild)" src/repl.js

clean:
	ocamlbuild -clean
