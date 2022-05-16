let twice_in_parallel f =
  let d1 = Domain.spawn f in
  let d2 = Domain.spawn f in
  ignore @@ Domain.join d1;
  ignore @@ Domain.join d2

let rec incr r =
  let curr = Atomic.get r in
  if Atomic.compare_and_set r curr (curr + 1) then ()
  else begin
    Domain.cpu_relax ();
    incr r
  end

let main () =
  let r = Atomic.make 0 in
  let f () = for _i=1 to 1_000_000 do incr r done in
  twice_in_parallel f;
  Printf.printf "Atomic ref count: %d\n" (Atomic.get r)

let _ = main ()
