(** Since YOCaml captures the set of static dependencies of a task, we decided
    to use a [Set] to describe this set.

    A part of the code is described in the file [.ml] *)

type t

(** [need_update deps target] produces an effect returning [true] if one of the
    modification dates of the files in the dependencies is greater than the
    modification date of the target. [false] otherwise. This function allows to
    describe if a target should be written or not.*)
val need_update : t -> string -> bool IO.t

(** [from_list l] produces a set of dependencies from a list of file path*)
val from_list : string list -> t

val pp : Format.formatter -> t -> unit
val equal : t -> t -> bool

(** A set is a monoid. *)

module Monoid : Preface.Specs.MONOID with type t = t
