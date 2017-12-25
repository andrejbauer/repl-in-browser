module Make (L : Zoo.LANGUAGE) =
struct


  (** A fatal error reported by the toplevel. *)
  let fatal_error msg = Zoo.error ~kind:"Fatal error" msg

  (** A syntax error reported by the toplevel *)
  let syntax_error ?loc msg = Zoo.error ~kind:"Syntax error" ?loc msg

  (** Should the interactive shell be run? *)
  let interactive_shell = ref true

  (** The command-line wrappers that we look for. *)
  let wrapper = ref (Some ["rlwrap"; "ledit"])

  (** The usage message. *)
  let usage =
    match L.file_parser with
    | Some _ -> "Usage: " ^ L.name ^ " [option] ... [file] ..."
    | None   -> "Usage:" ^ L.name ^ " [option] ..."

  (** A list of files to be loaded and run. *)
  let files = ref []

  (** Add a file to the list of files to be loaded, and record whether it should
      be processed in interactive mode. *)
  let add_file interactive filename = (files := (filename, interactive) :: !files)

  (** Command-line options *)
  let options = Arg.align [
    ("--wrapper",
     Arg.String (fun str -> wrapper := Some [str]),
     "<program> Specify a command-line wrapper to be used (such as rlwrap or ledit)");
    ("--no-wrapper",
     Arg.Unit (fun () -> wrapper := None),
     " Do not use a command-line wrapper");
    ("-v",
     Arg.Unit (fun () ->
       print_endline (L.name ^ " " ^ "(" ^ Sys.os_type ^ ")");
       exit 0),
     " Print language information and exit");
    ("-n",
     Arg.Clear interactive_shell,
     " Do not run the interactive toplevel");
    ("-l",
     Arg.String (fun str -> add_file false str),
     "<file> Load <file> into the initial environment")
  ] @
  L.options

  (** Treat anonymous arguments as files to be run. *)
  let anonymous str =
    add_file true str;
    interactive_shell := false

  (** Parse the contents from a file, using a given [parser]. *)
  let read_file parser fn =
  try
    let fh = open_in fn in
    let lex = Lexing.from_channel fh in
    lex.Lexing.lex_curr_p <- {lex.Lexing.lex_curr_p with Lexing.pos_fname = fn};
    try
      let terms = parser lex in
      close_in fh;
      terms
    with
      (* Close the file in case of any parsing errors. *)
      Zoo.Error err -> close_in fh ; raise (Zoo.Error err)
  with
    (* Any errors when opening or closing a file are fatal. *)
    Sys_error msg -> fatal_error "%s" msg

  (** Parse input from toplevel, using the given [parser]. *)
  let read_toplevel parser () =
    let prompt = L.name ^ "> "
    and prompt_more = String.make (String.length L.name) ' ' ^ "> " in
    print_string prompt ;
    let str = ref (read_line ()) in
      while L.read_more !str do
        print_string prompt_more ;
        str := !str ^ (read_line ()) ^ "\n"
      done ;
      parser (Lexing.from_string (!str ^ "\n"))

  (** Parser wrapper that catches syntax-related errors and converts them to errors. *)
  let wrap_syntax_errors parser lex =
    try
      parser lex
    with
      | Failure _ ->
        syntax_error ~loc:(Zoo.location_of_lex lex) "unrecognised symbol"
      | _ ->
        syntax_error ~loc:(Zoo.location_of_lex lex) "general confusion"

  (** Load directives from the given file. *)
  let use_file ~ppf ctx (filename, interactive) =
    match L.file_parser with
    | Some f ->
       let cmds = read_file (wrap_syntax_errors f) filename in
        List.fold_left (L.exec ~ppf) ctx cmds
    | None ->
       fatal_error "Cannot load files, only interactive shell is available"

  (** Interactive toplevel *)
  let toplevel ctx =
    let eof = match Sys.os_type with
      | "Unix" | "Cygwin" -> "Ctrl-D"
      | "Win32" -> "Ctrl-Z"
      | _ -> "EOF"
    in
      let toplevel_parser =
        match L.toplevel_parser with
        | Some p -> p
        | None -> fatal_error "I am sorry but this language has no interactive toplevel."
      in
      Format.printf "%s -- programming languages zoo@\n" L.name ;
      Format.printf "Type %s to exit@." eof ;
      try
        let ctx = ref ctx in
          while true do
            try
              let cmd = read_toplevel (wrap_syntax_errors toplevel_parser) () in
                ctx := L.exec ~ppf:Format.std_formatter !ctx cmd
            with
              | Zoo.Error err -> Zoo.print_error ~ppf:Format.std_formatter err
              | Sys.Break -> Zoo.print_info ~ppf:Format.std_formatter "Interrupted.@."
          done
      with End_of_file -> ()

  (** Main program *)
  let main () =
    (* Intercept Ctrl-C by the user *)
    Sys.catch_break true;
    (* Parse the arguments. *)
    Arg.parse options anonymous usage;
    (* Attempt to wrap yourself with a line-editing wrapper. *)
    if !interactive_shell then
      begin match !wrapper with
        | None -> ()
        | Some lst ->
          let n = Array.length Sys.argv + 2 in
          let args = Array.make n "" in
            Array.blit Sys.argv 0 args 1 (n - 2);
            args.(n - 1) <- "--no-wrapper";
            List.iter
              (fun wrapper ->
                try
                  args.(0) <- wrapper;
                  Unix.execvp wrapper args
                with Unix.Unix_error _ -> ())
              lst
      end;
    (* Files were listed in the wrong order, so we reverse them *)
    files := List.rev !files;
    (* Set the maximum depth of pretty-printing, after which it prints ellipsis. *)
    Format.set_max_boxes 42 ;
    Format.set_ellipsis_text "..." ;
    try
      (* Run and load all the specified files. *)
      let ctx = List.fold_left (use_file ~ppf:Format.std_formatter) L.initial_environment !files in
        if !interactive_shell then toplevel ctx
    with
        Zoo.Error err -> Zoo.print_error ~ppf:Format.std_formatter err; exit 1
end
