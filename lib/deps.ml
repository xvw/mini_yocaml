module D = Set.Make (String)
module T = Preface.List.Monad.Traversable (IO)

type t = D.t

let from_list list = D.of_list list

module Monoid = Preface.Make.Monoid.Via_combine_and_neutral (struct
  type t = D.t

  let neutral = D.empty
  let combine = D.union
end)

let get_mtimes deps =
  deps
  |> D.elements (* Apply the effect [Get_modification_time]*)
  |> List.map Action.get_mtime
  (* At this stage, we have a [int IO.t list] but we want a [int list IO.t] *)
  (* So we use [T.sequence] to go from [int IO.t list] to [int list IO.t] *)
  |> T.sequence
;;

let need_update deps target =
  let open IO.Syntax in
  let* exists = Action.file_exists target in
  if exists (* If the file exists we should try to reach the deps mtimes *)
  then
    let* mtime_target = Action.get_mtime target in
    let+ mtimes_deps = get_mtimes deps in
    (* We check if there, at least, one deps that has a greater mtime. *)
    List.exists (fun mtime_deps -> mtime_deps >= mtime_target) mtimes_deps
  else (* The file target does not exists. We need an update *)
    IO.return true
;;

let equal = D.equal

let pp ppf deps =
  Format.fprintf
    ppf
    "Deps [@[<v 0>%a@]]"
    (Format.pp_print_list
       ~pp_sep:(fun ppf () -> Format.fprintf ppf ";@ ")
       Format.pp_print_string)
    (D.elements deps)
;;
