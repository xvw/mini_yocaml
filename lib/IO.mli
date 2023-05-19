(** Since version 5, OCaml allows effects to be described, propagated and
    interpreted. However, in the absence of consensus, effects are not tracked
    by the type system. As in YOCaml, we want to factually distinguish pure
    functions from impure functions, we would like to be able to mark them as
    impure functions. For this, we use a type humorously named ['a IO.t].

    Under the bonnet, the type of an impure expression (['a IO.t], which denotes
    an expression of type ['a] and propagates effects) is nothing more than a
    value wrapped in a function taking [unit] as argument:
    ([type 'a t = unit -> 'a]).

    This allows you to never execute an operation and leave it to the
    interpreter to execute the function.

    This is probably not very useful, but it has the merit of matching the
    YOCaml design, essentially the
    {{:https://github.com/xhtmlboi/yocaml/blob/main/lib/yocaml/effect.mli}
      Effect} module.

    Here is a brief example of how to use [IO], in conjunction with effects
    definition to build an interpretable program:

    {[
      (* First, let us describe the effects we would like to propagate: *)
      type _ Effect.t += Print : string -> unit t
      type _ Effect.t += Read : string t

      (* Let's wrap these effects in IO  *)
      let print message = IO.perform @@ Print message
      let read () = IO.perform @@ Read

      (* Let's define a small programme *)
      let program () =
        let open IO.Syntax in
        let* () = print "Hello, World!" in
        let* () = print "What is your name?" in
        let* name = read () in
        print @@ "Hello " ^ name ^ ", Welcome here!"
      ;;

      (* Now let's interpret our effects in a handler documented here *)
      (* https://v2.ocaml.org/manual/effects.html#s%3Aeffects-basics *)
      let handler =
        { effc =
            (fun (type a) (eff : a t) ->
              match eff with
              | Print message ->
                Some
                  (fun (k : (a, _) continuation) ->
                    let () = print_endline message in
                    continue k ())
              | Read ->
                Some
                  (fun (k : (a, _) continuation) ->
                    let result = read_line () in
                    continue k result)
              | _ -> None)
        }
      ;;

      (* And now we can interpret our programme! *)
      let () = IO.run handler program ()
    ]} *)

(** The type that describes a suspended value (to be interpreted) *)
type 'a t

(** [perform effect] places the execution of an effect in an IO context
    (suspends its execution). *)
val perform : 'a Effect.t -> 'a t

(** [run handler io_function input] executes a function ([io]) of type
    ['input -> 'output IO.t] by provisioning it with the value [input] in a
    given effect handler. *)
val run : 'b Effect.Deep.effect_handler -> ('a -> 'b t) -> 'a -> 'b

(** In order to be usable, [IO] is a monad, offering all operators and syntax
    objects for ease of use. *)

include Preface.Specs.MONAD with type 'a t := 'a t (** @inline *)
