(** Create a language from its definition. *)
module Make : functor (L : Zoo.LANGUAGE) ->
                      sig
                        (** The main program *)
                        val main : unit -> unit
                      end
