include Preface.Make.Monad.Via_return_and_bind (struct
  type 'a t = unit -> 'a

  let return x () = x
  let bind f x = f (x ())
end)

let perform x = return (Effect.perform x)

let run handler io input =
  Effect.Deep.try_with (fun () -> io input ()) () handler
;;
