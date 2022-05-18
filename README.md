# OCaml 5 Tutorial

A hands-on tutorial on the new parallelism features in OCaml 5. This tutorial was run on 19th May 2022.

## Installation

This tutorial works on x86-64 and Arm64 architectures on Linux and macOS.

With `opam` version >= 2.1:

```bash
opam update
opam switch create 5.0.0+trunk --repo=default,alpha=git+https://github.com/kit-ty-kate/opam-alpha-repository.git
opam install . --deps-only
```

with `opam` version < 2.1:

```bash
opam update
opam switch create 5.0.0+trunk --repo=default,beta=git+https://github.com/ocaml/ocaml-beta-repository.git,alpha=git+https://github.com/kit-ty-kate/opam-alpha-repository.git
opam install . --deps-only
```

Since we will be doing performance measurements, it is recommended that you also
install [`hyperfine`](https://github.com/sharkdp/hyperfine).

## Concurrency vs Parallelism

OCaml 5 distinguishes concurrency and parallelism. Concurrency is **overlapped**
execution of concurrent tasks. Parallelism is **simultaneous** execution of
tasks. OCaml 5 provides [effect
handlers](https://kcsrk.info/webman/manual/effects.html) for concurrency and
[domains](https://github.com/ocaml/ocaml/blob/trunk/stdlib/domain.mli) for
parallelism.

Let us focus on parallelism features first. 

## Domains for Parallelism

Domains are units of parallel computation. New domains can be spawned using
`Domain.spawn` primitive:

```bash
$ ocaml
# Domain.spawn;;
- : (unit -> 'a) -> 'a Domain.t = <fun>
# Domain.spawn (fun _ -> print_endline "I ran in parallel");;
I ran in parallel
- : unit Domain.t = <abstr>
```

The same example is also in [src/par.ml](src/par.ml):

```bash
$ cat src/par.ml
Domain.spawn (fun _ -> print_endline "I ran in parallel")
```

The dune command compiles the native version of the above program and runs it:

```bash
$ dune exec src/par.exe
I ran in parallel
```

In this section of the tutorial, we will be running parallel programs. The
results observed will be dependent on the number of cores that you have on your
machine. I am writing this tutorial on an 2.3 GHz Quad-Core Intel Core i7
MacBook Pro with 4 cores and 8 hardware threads. It is reasonable to expect a
speedup of 4x on embarrassingly parallel programs (and a little more if
Hyper-Threading gods are kind to us).

## Fibonacci Number

Spawned domains can be joined to get their results. The program
[src/fib.ml](src/fib.ml) computes the nth Fibonacci number. 

```ocaml
let n = try int_of_string Sys.argv.(1) with _ -> 10

let rec fib n = if n < 2 then 1 else fib (n - 1) + fib (n - 2)

let main () =
  let r = fib n in
  Printf.printf "fib(%d) = %d\n%!" n r

let _ = main ()
```

The program is a vanilla implementation of the Fibonacci function.

```bash
$ dune build src/fib.exe
$ hyperfine 'dune exec src/fib.exe 40'
Benchmark 1: dune exec src/fib.exe 40
  Time (mean ± σ):     498.5 ms ±   4.0 ms    [User: 477.8 ms, System: 14.1 ms]
  Range (min … max):   493.0 ms … 507.5 ms    10 runs
```

On my machine, it takes 500ms to compute the 40th Fibonacci number.

The program [src/fib_twice.ml](src/fib_twice.ml) computes the nth Fibonacci
number twice in parallel.

```ocaml
let n = try int_of_string Sys.argv.(1) with _ -> 10

let rec fib n = if n < 2 then 1 else fib (n - 1) + fib (n - 2)

let main () =
  let d1 = Domain.spawn (fun _ -> fib n) in
  let d2 = Domain.spawn (fun _ -> fib n) in
  let r1 = Domain.join d1 in
  Printf.printf "fib(%d) = %d\n%!" n r1;
  let r2 = Domain.join d2 in
  Printf.printf "fib(%d) = %d\n%!" n r2

let _ = main ()
```

The program spawns two domains which compute the nth Fibonacci number.
`Domain.spawn` returns a `Domain.t` value which can be joined to get the result
of the parallel computation. `Domain.join` blocks until the computation runs to
completion.

```bash
$ dune build src/fib_twice.exe
$ hyperfine 'dune exec src/fib_twice.exe 40'
Benchmark 1: dune exec src/fib_twice.exe 40
  Time (mean ± σ):     499.7 ms ±   0.9 ms    [User: 940.1 ms, System: 15.5 ms]
  Range (min … max):   498.7 ms … 501.6 ms    10 runs
```

You can see that computing the nth Fibonacci number twice almost took the same
time as computing it once thanks to parallelism.

## Nature of domains

Domains are heavy-weight entities. Each domain directly maps to an operating
system thread. Hence, they are relatively expensive to create and tear down.
Moreover, each domain brings its own runtime state local to the domain. In
particular, each domain has its own minor heap area and major heap pools.

OCaml 5 GC is designed to be a low-latency garbage collector with short
stop-the-world pauses. Whenever a domain exhausts its minor heap arena, it calls
for a stop-the-world, parallel minor GC, where all the domains collect their
minor heaps. The domains also perform concurrent (not stop-the-world) collection
of the major heap. The major collection cycle involves a number of very short
stop-the-world pauses.

Overall, the behaviour of OCaml 5 GC should match that of the OCaml 4 GC for
sequential programs, and remains scalable and low-latency for parallel programs.
For more information, please have a look at the [ICFP 2020 paper and talk on
"Retrofitting Parallelism onto
OCaml"](https://icfp20.sigplan.org/details/icfp-2020-papers/21/Retrofitting-Parallelism-onto-OCaml).

Due to the overhead of domains, **the recommendation is that you spawn exactly
one domain per available core.**

## Exercise ★★☆☆☆

Compute the nth Fibonacci number in parallel by parallelising recursive calls.
For this exercise, only spawn new domains for the top two recursive calls. You
program will only spawn two additional domains. The skeleton is in the file
[src/fib_par.ml](src/fib_par.ml):

```ocaml
let n = try int_of_string Sys.argv.(1) with _ -> 10

let rec fib n = if n < 2 then 1 else fib (n - 1) + fib (n - 2)

let fib_par n =
  if n > 20 then begin
    (* Only use parallelism when problem size is large enough *)
    failwith "not implemented"
  end else fib n

let main () =
  let r = fib_par n in
  Printf.printf "fib(%d) = %d\n%!" n r

let _ = main ()
```

When you finish the exercise, you will notice that with 2 cores, the speed up is
nowhere close to 2x. This is because of the fact that the work is imbalanced
between the two recursive calls of the fibonacci function.

```
fib(n) = fib(n-1) + fib(n-2)
fib(n) = (fib(n-2) + fib(n-3)) + fib(n-2)
```

The left recursive call does more work than the right branch. We shall get to 2x
speedup eventually. First, we need to take a detour.

## Inter-domain communication

`Domain.join` is a way to synchronize with the domain. OCaml 5 also provides
other features for inter-domain communication.

### DRF-SC guarantee

OCaml has mutable reference cells and arrays. Can we share ref cells and arrays
between multiple domains and access them in parallel? The answer is yes. But the
value that may be returned by a read may not be the latest one written to that
memory location due to the influence of compiler and hardware optimizations. The
description of the exact value returned by such racy accesses is beyond the
scope of the tutorial. For more information on this, you should refer to the
[PLDI 2018 paper on "Bounding Data Races in Space and
Time"](https://kcsrk.info/papers/pldi18-memory.pdf).

OCaml reference cells and arrays are known as **non-atomic** data structures.
Whenever two domains race to access a non-atomic memory location, and one of the
access is a write, then we say that there is a **data race**. When your program
does not have a data race, then the behaviours observed are **sequentially
consistent** -- the observed behaviour can simply be understood as the
interleaved execution of different domains.

An important guarantee is that, even if you program has data races, your program
will not crash (memory safety). The recommendation for the OCaml user is that
**avoid data races for ease of reasoning**.

### Atomics

How do we avoid races? One option is to use the
[`Atomic`](https://github.com/ocaml/ocaml/blob/trunk/stdlib/atomic.mli) module
which provides low-level atomic mutable references. Importantly, races on atomic
references are not data races, and hence, the programmer will observe
sequentially consistent behaviour.

The program [src/incr.ml](src/incr.ml) increments a counter 1M times twice in
parallel. As you can see, the non-atomic increment under counts:

```bash
% dune exec src/incr.exe
Non-atomic ref count: 1101799
Atomic ref count: 2000000
```

Atomic module is used for low-level inter-domain communication. They are used
for implementing lock-free data structures. For example, the program
[src/msg_passing.ml](src/msg_passing.ml) shows an implementation of message
passing between domains. The program uses `get` and `set` on the atomic
reference `r` for communication. Although the domains race on the access to `r`,
since `r` is an atomic variable, it is not a data race. 

```bash
% bash exec src/msg_passing.exe
Hello
```

### Compare-and-set

Atomic module also has `compare_and_set` primitive. `compare_and_set r old new`
atomically compares the current value of the atomic reference `r` with the `old`
value and replaces that with the `new` value. The program
[src/incr_cas.ml](src/incr_cas.ml) shows how to implement atomic increment
(inefficiently) using `compare_and_set`:

```ocaml
let rec incr r =
  let curr = Atomic.get r in
  if Atomic.compare_and_set r curr (curr + 1) then ()
  else begin
    Domain.cpu_relax ();
    incr r
  end
```

```bash
% dune exec src/incr_cas.exe
Atomic ref count: 2000000
```

## Exercise ★★★☆☆

Complete the implementation of the non-blocking atomic stack. The skeleton file
is [src/prod_cons_nb.ml](src/prod_cons_nb.ml). Remember that
`compare_and_set` uses physical equality. The `old` value provided must
physically match the current value of the atomic reference for the comparison to
succeed.

## Blocking synchronization

The only primitive that we have seen so far that blocks a domain is
`Domain.join`. OCaml 5 also provides blocking synchronization through
[`Mutex`](https://github.com/ocaml/ocaml/blob/trunk/stdlib/mutex.mli),
[`Condition`](https://github.com/ocaml/ocaml/blob/trunk/stdlib/condition.mli)
and
[`Semaphore`](https://github.com/ocaml/ocaml/blob/trunk/stdlib/semaphore.mli)
modules. These are the same modules that are present in OCaml 4 to synchronize
between `Threads`. These modules have been lifted up to the level of domains.

## Exercise ★★★☆☆

In the last exercise [src/prod_cons_nb.ml](src/prod_cons_nb.ml), the pop
operation on the atomic stack returns `None` if the stack is empty. In this
exercise, you will complete the implementation of a _blocking_ variant of the
stack where the `pop` operation blocks until a matching `push` appears. The
skeleton file is [src/prod_cons_b.ml](src/prod_cons_b.ml).

This exercise may be hard if you have not programmed with mutex and condition
variables previously. Fret not. In the next section, we shall look at a
higher-level API for parallel programming built on these low-level constructs.
