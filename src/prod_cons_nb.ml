let n = try int_of_string Sys.argv.(1) with _ -> 10

module Atomic_stack : sig
  type 'a t
  val make : unit -> 'a t
  val push : 'a t -> 'a -> unit
  val pop  : 'a t -> 'a option
end = struct
  type 'a t = 'a list Atomic.t

  let make () = Atomic.make []

  let rec push r v = failwith "not implemented"

  let rec pop r = failwith "not implemented"
end

let s = Atomic_stack.make ()

let rec producer n =
  if n = 0 then ()
  else begin
    Atomic_stack.push s n;
    Format.printf "Produced %d\n%!" n;
    producer (n-1)
  end

let rec consumer n acc =
  if n = 0 then acc
  else begin
    match Atomic_stack.pop s with
    | None -> Domain.cpu_relax (); consumer n acc
    | Some v ->
        Format.printf "Consumed %d\n%!" v;
        consumer (n-1) (n + acc)
  end

let main () =
  let p = Domain.spawn (fun _ -> producer n) in
  let c = Domain.spawn (fun _ -> consumer n 0) in
  Domain.join p;
  assert (Domain.join c = n * (n+1) / 2)

let _ = main ()
