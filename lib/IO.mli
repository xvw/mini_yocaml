type 'a t

val perform : 'a Effect.t -> 'a t
val run : 'b Effect.Deep.effect_handler -> ('a -> 'b t) -> 'a -> 'b

include Preface.Specs.MONAD with type 'a t := 'a t
