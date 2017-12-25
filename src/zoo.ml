(* This file contains all the common code used by the languages implemented in the PL Zoo. *)

type location =
  | Location of Lexing.position * Lexing.position (** delimited location *)
  | Nowhere (** no location *)

type 'a located = { data : 'a ; loc : location }

let make_location loc1 loc2 = Location (loc1, loc2)

let location_of_lex lex =
  Location (Lexing.lexeme_start_p lex, Lexing.lexeme_end_p lex)

let locate ?(loc=Nowhere) x = { data = x; loc = loc }

(** Exception [Error (loc, err, msg)] indicates an error of type [err] with error message
    [msg], occurring at location [loc]. *)
exception Error of (location * string * string)

(** [error ~loc ~kind] raises an error of the given [kind]. The [kfprintf] magic allows
    one to write [msg] using a format string. *)
let error ?(kind="Error") ?(loc=Nowhere) =
  let k _ =
    let msg = Format.flush_str_formatter () in
      raise (Error (loc, kind, msg))
  in
    Format.kfprintf k Format.str_formatter

let print_parens ?(max_level=9999) ?(at_level=0) ppf =
  if max_level < at_level then
    begin
      Format.fprintf ppf "(@[" ;
      Format.kfprintf (fun ppf -> Format.fprintf ppf "@])") ppf
    end
  else
    begin
      Format.fprintf ppf "@[" ;
      Format.kfprintf (fun ppf -> Format.fprintf ppf "@]") ppf
    end

let print_location loc ppf =
  match loc with
  | Nowhere ->
      Format.fprintf ppf "unknown location"
  | Location (begin_pos, end_pos) ->
      let begin_char = begin_pos.Lexing.pos_cnum - begin_pos.Lexing.pos_bol in
      let end_char = end_pos.Lexing.pos_cnum - begin_pos.Lexing.pos_bol in
      let begin_line = begin_pos.Lexing.pos_lnum in
      let filename = begin_pos.Lexing.pos_fname in

      if String.length filename != 0 then
        Format.fprintf ppf "file %S, line %d, charaters %d-%d" filename begin_line begin_char end_char
      else
        Format.fprintf ppf "line %d, characters %d-%d" (begin_line - 1) begin_char end_char

(** Print a message at a given location [loc] of message type [msg_type]. *)
let print_message ~ppf ?(loc=Nowhere) msg_type =
  match loc with
  | Location _ ->
     Format.fprintf ppf "%s at %t:@\n" msg_type (print_location loc) ;
     Format.kfprintf (fun ppf -> Format.fprintf ppf "@.") ppf
  | Nowhere ->
     Format.fprintf ppf "%s: " msg_type ;
     Format.kfprintf (fun ppf -> Format.fprintf ppf "@.") ppf

let print_info ~ppf msg = Format.kfprintf (fun ppf -> Format.pp_print_flush ppf ()) ppf msg

let print_error ~ppf (loc, err_type, msg) = print_message ~ppf ~loc err_type "%s" msg

module type LANGUAGE =
sig
  val name : string
  type command
  type environment
  val options : (Arg.key * Arg.spec * Arg.doc) list
  val initial_environment : environment
  val read_more : string -> bool
  val file_parser : (Lexing.lexbuf -> command list) option
  val toplevel_parser : (Lexing.lexbuf -> command) option
  val exec : ppf:Format.formatter -> environment -> command -> environment
end
