let twice_in_parallel f =
  let d1 = Domain.spawn f in
  let d2 = Domain.spawn f in
  ignore @@ Domain.join d1;
  ignore @@ Domain.join d2

let plain_ref () =
  let r = ref 0 in
  let f () = for _i=1 to 1_000_000 do incr r done in
  twice_in_parallel f;
  Printf.printf "Non-atomic ref count: %d\n" !r

let atomic_ref () =
  let r = Atomic.make 0 in
  let f () = for _i=1 to 1_000_000 do Atomic.incr r done in
  twice_in_parallel f;
  Printf.printf "Atomic ref count: %d\n" (Atomic.get r)

let main () =
  plain_ref ();
  atomic_ref ()

let _ = main ()
