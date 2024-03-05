module T = Domainslib.Task

let num_domains = try int_of_string (Array.get Sys.argv 1) with _ -> 1
let w = try int_of_string (Array.get Sys.argv 2) with _ -> 200
let niter = 50
let limit = 4.

let mandelbrot pool w =
  let h = w in
  let fw = float w /. 2. and fh = float h /. 2. in
  Printf.printf "P4\n%i %i\n" w h;
  let red_h = h - 1 and red_w = w - 1 in
  T.parallel_for_reduce pool (@) [] ~start:0 ~finish:red_h ~body:(fun y ->
    let byte = ref 0 in
    let buf = Buffer.create 16 in
    let ci = float y /. fh -. 1. in
    for x = 0 to red_w do
      let cr = float x /. fw -. 1.5
      and zr = ref 0. and zi = ref 0. and trmti = ref 0. and n = ref 0 in
      begin try
        while true do
          zi := 2. *. !zr *. !zi +. ci;
          zr := !trmti +. cr;
          let tr = !zr *. !zr and ti = !zi *. !zi in
          if tr +. ti > limit then begin
            byte := !byte lsl 1;
            raise Exit
          end else if incr n; !n = niter then begin
            byte := (!byte lsl 1) lor 0x01;
            raise Exit
          end else
            trmti := tr -. ti
        done
      with Exit -> ()
      end;
      if x mod 8 = 7 then Buffer.add_uint8 buf !byte
    done;
    let rem = w mod 8 in
    if rem != 0 then (* the row doesnt divide evenly by 8 *)
      Buffer.add_uint8 buf (!byte lsl (8 - rem)); (* output last few bits *)
    [buf]
  )

let main () =
  let pool = T.setup_pool ~num_domains:(num_domains - 1) () in
  let l = T.run pool (fun _ -> mandelbrot pool w) in
  T.teardown_pool pool;
  List.iter (fun buf -> output_bytes stdout (Buffer.to_bytes buf)) l

let _ = main ()
