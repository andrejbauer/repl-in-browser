let echoer f (msg : string) : unit =
  Js.Unsafe.fun_call f [| Js.Unsafe.inject (Js.bytestring msg) |]

let _ =
  Js.export "repl"
  (object%js
     method toplevel s f = Js.bytestring (Lang.toplevel (Js.to_bytestring s))
     method commands s f =
       let s = Js.to_bytestring s in
       echoer f (Format.sprintf "We got %d characters.@." (String.length s))
   end)
