(lang dune 3.1)

(name ocaml5_tutorial)

(generate_opam_files true)

(source
 (github kayceesrk/ocaml5-tutorial))

(authors "KC Sivaramakrishnan")

(maintainers "KC Sivaramakrishnan")

(license MIT)

(documentation https://github.com/kayceesrk/ocaml5-tutorial/blob/main/README.md)

(package
 (name ocaml5_tutorial)
 (synopsis "A tutorial on new concurrency features in OCaml 5")
 (description "A tutorial on new concurrency features in OCaml 5")
 (depends ocaml dune))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
