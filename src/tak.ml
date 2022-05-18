let (x,y,z) =
  try
    let x = int_of_string Sys.argv.(1) in
    let y = int_of_string Sys.argv.(2) in
    let z = int_of_string Sys.argv.(3) in
    (x,y,z)
  with _ -> (18,12,6)

let rec tak x y z =
  if x > y then
    tak (tak (x-1) y z) (tak (y-1) z x) (tak (z-1) x y)
  else z

let main () =
  let r = tak x y z in
  Printf.printf "tak %d %d %d = %d\n" x y z r

let _ = main ()
