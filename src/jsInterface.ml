(** A functor that creates the OCaml to Javascript interface. *)

module Make(L : Zoo.LANGUAGE) =
struct

  (** Create a [Format.formatter] from a Javascript print callback. *)
  let js_formatter echo =
    let buffer = ref "" in
    Format.make_formatter
    (fun s p n -> buffer := !buffer ^ String.sub s p n )
    (fun () ->
      (Js.Unsafe.fun_call echo [| Js.Unsafe.inject (Js.string !buffer) |] : unit) ;
      buffer := "")

  (* Export the interface to Javascript. *)
  let _ =
    Js.export "repl"
      (object%js

         method reset echo =
           let ppf = js_formatter echo in
           Format.fprintf ppf "%s -- programming languages zoo@\n@." L.name ;
           L.initial_environment

         method toplevel echo env cmd =
           let ppf = js_formatter echo in
           match L.toplevel_parser with
           | None ->
              Format.fprintf ppf "I am sorry but this language has no interactive toplevel." ;
              env
           | Some p ->
              begin try
                  let cmd = Js.to_string cmd in
                  let cmd = p (Lexing.from_string cmd) in
                  L.exec ~ppf env cmd
                with
                | Zoo.Error err -> Zoo.print_error ~ppf err ; env
              end

         method usefile echo env cmds =
           let ppf = js_formatter echo in
           match L.file_parser with
           | None ->
              Format.fprintf ppf "I am sorry but this language has no non-interactive interpreter." ;
              env
           | Some p ->
              begin
                try
                  let cmds = Js.to_string cmds in
                  let cmds = p (Lexing.from_string cmds) in
                  List.fold_left (L.exec ~ppf) env cmds
                with
                | Zoo.Error err -> Zoo.print_error ~ppf err ; env
              end
       end)
end
