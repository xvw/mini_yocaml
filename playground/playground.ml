open Effect
open Effect.Deep
open Mini_yocaml

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

let () = IO.run handler program ()
