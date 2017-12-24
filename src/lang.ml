let toplevel =
  let k = ref 0 in
  fun s ->
    incr k ;
    (string_of_int !k) ^ ": " ^ s
