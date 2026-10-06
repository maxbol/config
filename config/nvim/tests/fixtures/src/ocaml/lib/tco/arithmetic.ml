(* Lives in a subdirectory on purpose: a multi-directory dune project is what
   makes dune record /workspace_root paths instead of relative ones. *)
let fold_vals a b = (a * b) + a - 1

let sum_list l = List.fold_left (fun acc x -> acc + fold_vals x 2) 0 l
