module T = Domainslib.Task

let num_domains = try int_of_string @@ Sys.argv.(1) with _ -> 1
let n = try int_of_string @@ Sys.argv.(2) with _ -> 1024

let min = 128
let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) ()

let _ = Random.init 42
let a = Array.init n (fun _ -> Random.int n)
let b = Array.make n 0

type array_slice = {arr: int array; index: int; length: int}

let sort a =
  for i = a.index to a.index + a.length - 2 do
    for j = i + 1 to a.index + a.length - 1 do
      if a.arr.(j) < a.arr.(i) then
        let t = a.arr.(i) in
        a.arr.(i) <- a.arr.(j);
        a.arr.(j) <- t
    done
  done

let merge a b res =
  let rec loop ai bi ri =
    match a.index + a.length - ai, b.index + b.length - bi with
    | n, 0 -> Array.blit a.arr ai res.arr ri n
    | 0, n -> Array.blit b.arr bi res.arr ri n
    | _, _ ->
        if a.arr.(ai) < b.arr.(bi) then begin
          res.arr.(ri) <- a.arr.(ai);
          loop (ai+1) bi (ri+1)
        end else begin
          res.arr.(ri) <- b.arr.(bi);
          loop ai (bi+1) (ri+1)
        end
  in
  loop a.index b.index res.index

let rec merge_sort a b l =
  if a.length <= min then begin
    sort a;
    a
  end else
    let a1= {a with index = a.index; length = a.length / 2} in
    let b1 = {b with index = b.index; length = b.length / 2} in
    let r1 = T.async pool (fun _ -> merge_sort a1 b1 (2*l+1)) in

    let a2 = {a with index = a.index + a.length / 2;
                length = a.length - a.length / 2} in
    let b2 = {b with index = b.index + b.length / 2;
                length = b.length - b.length / 2} in
    let r2 = T.async pool (fun _ -> merge_sort a2 b2 (2*l+2)) in

    let (r1, r2) = (T.await pool r1, T.await pool r2) in

    if r1.arr != r2.arr then begin
      if r2.arr == a.arr then begin
        merge r1 r2 a;
        a
      end else begin
        merge r1 r2 b;
        b
      end
    end else if r1.arr == a.arr then begin
      merge r1 r2 b;
      b
    end else begin
      merge r1 r2 a;
      a
    end

let _ =
  let aslice = {arr = a; index = 0; length = n}in
  let bslice = {arr = b; index = 0; length = n} in

  let _r = T.run pool (fun _ -> merge_sort aslice bslice 0) in
(*   Array.iter (fun i -> print_endline (string_of_int i)) _r.arr; *)
  T.teardown_pool pool
