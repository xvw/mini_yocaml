type ('a, 'b) t =
  { deps : Deps.t
  ; task : 'a -> 'b IO.t
  }

let create_file target { deps; task } =
  let open IO.Syntax in
  let* need_update = Deps.need_update deps target in
  if need_update
  then
    let* () = Action.log (target ^ " need to be created") in
    let* content = task () in
    Action.write_file target content
  else Action.log (target ^ "is already up-to-date")
;;

let watch_file filepath =
  let deps = Deps.from_list [ filepath ] in
  let task () = IO.return () in
  { deps; task }
;;

let read_file filepath =
  let deps = Deps.from_list [ filepath ] in
  let task () = Action.read_file filepath in
  { deps; task }
;;
