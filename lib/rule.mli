type ('a, 'b) t

(** {1 Predefined rules} *)

(** [watch_file filepath] just adds [filepath] in the set of deps, but dothing.
    This rule is useful for watching file that do not need to be read, ie, the
    binary of the generator that can be written like that
    [watch_file Sys.argv.(1)]. *)
val watch_file : string -> (unit, unit) t

(** [read_file filepath] add [filepath] in the set of deps and read its content. *)
val read_file : string -> (unit, string) t

(** {1 Action over rules} *)

(** [create_file target rule] will produces the effect that create the file
    [target] using the content produced by [rule] only if it is neeeded.*)
val create_file : string -> (unit, string) t -> unit IO.t
