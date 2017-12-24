let echoer f (s : string) : unit =
  Js.Unsafe.fun_call f [| Js.Unsafe.inject (Js.number_of_float 42.0) |]

let _ =
  Js.export "repl"
  (object%js
     method toplevel s f =
       echoer f "It might work" ;
       Js.bytestring (Lang.toplevel (Js.to_bytestring s))
   end)
