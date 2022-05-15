# OCaml 5 Tutorial

A hands-on tutorial on the new concurrency and parallelism features in OCaml 5. The tutorial was run in May 2022. 

## Installation

This tutorial works on x86-64 and Arm64 architectures on Linux and macOS.

With `opam` version >= 2.1:

```bash
opam update
opam switch create 5.0.0+trunk --repo=default,alpha=git+https://github.com/kit-ty-kate/opam-alpha-repository.git
```

with `opam` version < 2.1:

```bash
opam update
opam switch create 5.0.0+trunk --repo=default,beta=git+https://github.com/ocaml/ocaml-beta-repository.git,alpha=git+https://github.com/kit-ty-kate/opam-alpha-repository.git
```

## Concurrency vs Parallelism

OCaml 5 distinguishes concurrency and parallelism. Concurrency is **overlapped** execution of concurrent tasks. Parallelism is **simultaneous** execution of tasks. OCaml 5 provides [effect handlers](https://kcsrk.info/webman/manual/effects.html) for concurrency and [domains](https://github.com/ocaml/ocaml/blob/trunk/stdlib/domain.mli) for parallelsim.
