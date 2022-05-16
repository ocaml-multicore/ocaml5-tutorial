let r = Atomic.make None

let sender () = Atomic.set r (Some "Hello")

let rec receiver () =
  match Atomic.get r with
  | None -> Domain.cpu_relax (); receiver ()
  | Some m -> print_endline m

let main () =
  let s = Domain.spawn sender in
  let d = Domain.spawn receiver in
  Domain.join s;
  Domain.join d

let _ = main ()
