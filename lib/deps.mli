type t

val need_update : t -> string -> bool IO.t

module Monoid : Preface.Specs.MONOID with type t = t
