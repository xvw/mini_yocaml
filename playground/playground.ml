open Effect
open Effect.Deep
open Mini_yocaml

type _ Effect.t += Print : string -> unit t | Read : string t

let program () =
  let open IO.Syntax in
  let* () = IO.perform @@ Print "Hello, World!" in
  let* () = IO.perform @@ Print "What is your name ?" in
  let* name = IO.perform Read in
  IO.perform @@ Print ("Hello, " ^ name)
;;

let handler =
  { effc =
      (fun (type a) (eff : a t) ->
        match eff with
        | Print message ->
          let callback (k : (a, _) continuation) =
            let () = print_endline message in
            continue k ()
          in
          Some callback
        | Read ->
          let callback (k : (a, _) continuation) =
            let result = read_line () in
            continue k result
          in
          Some callback
        | _ -> None)
  }
;;

let () = IO.run handler program ()
