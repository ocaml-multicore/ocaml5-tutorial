module T = Domainslib.Task

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ ->  2000

let eval_A i j = 1. /. float((i+j)*(i+j+1)/2+i+1)

let eval_A_times_u pool u v =
  let n = Array.length v - 1 in
  T.parallel_for pool ~start:0 ~finish:n ~body:(fun i ->
    let vi = ref 0. in
      for j = 0 to n do vi := !vi +. eval_A i j *. u.(j) done;
      v.(i) <- !vi
  )

let eval_At_times_u pool u v =
  let n = Array.length v -1 in
  T.parallel_for pool ~start:0 ~finish:n ~body:(fun i ->
    let vi = ref 0. in
      for j = 0 to n do vi := !vi +. eval_A j i *. u.(j) done;
      v.(i) <- !vi
  )

let eval_AtA_times_u pool u v =
  let w = Array.make (Array.length u) 0.0 in
  eval_A_times_u pool u w; eval_At_times_u pool w v


let () =
  let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) () in
  let u = Array.make n 1.0  and  v = Array.make n 0.0 in
  T.run pool (fun _ ->
  for _i = 0 to 9 do
    eval_AtA_times_u pool u v; eval_AtA_times_u pool v u
  done);

  let vv = ref 0.0  and  vBv = ref 0.0 in
  for i=0 to n-1 do
    vv := !vv +. v.(i) *. v.(i);
    vBv := !vBv +. u.(i) *. v.(i)
  done;
  T.teardown_pool pool;
  Printf.printf "%0.9f\n" (sqrt(!vBv /. !vv))
