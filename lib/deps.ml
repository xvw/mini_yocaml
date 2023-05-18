module D = Set.Make (String)
module T = Preface.List.Monad.Traversable (IO)

type t = D.t

module Monoid = Preface.Make.Monoid.Via_combine_and_neutral (struct
  type t = D.t

  let neutral = D.empty
  let combine = D.union
end)

let get_mtimes deps =
  deps |> D.elements |> List.map Action.get_mtime |> T.sequence
;;

let need_update deps target =
  let open IO.Syntax in
  let* exists = Action.file_exists target in
  if exists
  then
    let* mtime_target = Action.get_mtime target in
    let+ mtimes_deps = get_mtimes deps in
    List.exists (fun mtime_deps -> mtime_deps > mtime_target) mtimes_deps
  else IO.return true
;;
