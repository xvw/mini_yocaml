type ('a, 'b) t

val deps_of : ('a, 'b) t -> Deps.t

(** {1 Predefined rules} *)

(** [watch_file filepath] just adds [filepath] in the set of deps, but dothing.
    This rule is useful for watching file that do not need to be read, ie, the
    binary of the generator that can be written like that
    [watch_file Sys.argv.(0)]. *)
val watch_file : string -> (unit, unit) t

(** [read_file filepath] add [filepath] in the set of deps and read its content. *)
val read_file : string -> (unit, string) t

(** [concat_file filepath] add [filepath] in the set of deps and pipe the
    content of the [filepath] to the previous result. For example :

    {[
      read_file "a.html" >>> concat_file "b.html" >>> concat_file "c.html"
    ]}

    Will produce a [t] where the set of deps contains
    ["a.html", "b.html", "c.html"] and which returns the concatenation of the
    three files. *)
val concat_file : ?separator:string -> string -> (string, string) t

(** {1 Combinators over rules} *)

(** [lift f] promote a regular function into a rule. The produced rule has no
    dependencies. *)
val lift : ('a -> 'b) -> ('a, 'b) t

val fst : ('a, 'b) t -> ('a * 'c, 'b * 'c) t
val snd : ('a, 'b) t -> ('c * 'a, 'c * 'b) t
val ( <<< ) : ('b, 'c) t -> ('a, 'b) t -> ('a, 'c) t
val ( >>> ) : ('a, 'b) t -> ('b, 'c) t -> ('a, 'c) t
val ( ^>> ) : ('a -> 'b) -> ('b, 'c) t -> ('a, 'c) t
val ( >>^ ) : ('a, 'b) t -> ('b -> 'c) -> ('a, 'c) t
val ( <<^ ) : ('b, 'c) t -> ('a -> 'b) -> ('a, 'c) t
val ( ^<< ) : ('b -> 'c) -> ('a, 'b) t -> ('a, 'c) t
val ( *** ) : ('a, 'b) t -> ('c, 'd) t -> ('a * 'c, 'b * 'd) t
val ( &&& ) : ('a, 'b) t -> ('a, 'c) t -> ('a, 'b * 'c) t

(** {1 Action over rules} *)

(** [create_file target rule] will produces the effect that create the file
    [target] using the content produced by [rule] only if it is neeeded.*)
val create_file : string -> (unit, string) t -> unit IO.t
