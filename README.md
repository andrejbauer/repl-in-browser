# REPL in the browser

An example showing how to put your language implementation into a browser.

## Prerequisites

You need [OCaml](http://www.ocaml.org) and [OPAM](https://opam.ocaml.org). Install the
following OPAM packages:

    opam install menhir
    opam install js_of_ocaml js_of_ocaml-ocamlbuild js_of_ocaml-ppx

You also need `make` and Python 3 (or Python 2 but then `make serve` needs to be fixed).

## Compilation

To compile the stand-alone executable of the language type

    make lambda.native

To compile the Javascript version of the language type

    make repl.js

## Testing

To test the implementation simply visit [`index.html`](./index.html) (after you've
compiled [`repl.js`](./repl.js)). You can also start a local server with

   make serve

and visit http://localhost:8000/

## Usage

To create a stand-alone web page, put the following files on the server:

* `index.html`
* `repl.js` (note: this is a symbolic link, make sure you copy the contents)


