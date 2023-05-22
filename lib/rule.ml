type ('a, 'b) t =
  { deps : Deps.t
  ; task : 'a -> 'b IO.t
  }

let deps_of { deps; _ } = deps

module Category = Preface.Make.Category.Via_id_and_compose (struct
  type nonrec ('a, 'b) t = ('a, 'b) t

  let id =
    let deps = Deps.Monoid.neutral in
    let task x = IO.return x in
    { deps; task }
  ;;

  let compose rule_a rule_b =
    let deps = Deps.Monoid.combine rule_a.deps rule_b.deps in
    let task = IO.(rule_a.task <=< rule_b.task) in
    { deps; task }
  ;;
end)

module Arrow =
  Preface.Make.Arrow.Over_category_and_via_arrow_and_fst
    (Category)
    (struct
      type nonrec ('a, 'b) t = ('a, 'b) t

      let arrow f =
        let deps = Deps.Monoid.neutral in
        let task x = IO.return (f x) in
        { deps; task }
      ;;

      let fst rule =
        let deps = rule.deps in
        let task (x, y) =
          let open IO in
          let+ x = rule.task x in
          x, y
        in
        { deps; task }
      ;;
    end)

let lift = Arrow.arrow

include (Arrow : Preface.Specs.ARROW with type ('a, 'b) t := ('a, 'b) t)

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

let concat_file ?(separator = "\n") filepath =
  let concat (x, y) = x ^ separator ^ y in
  let init x = x, () in
  init ^>> snd (read_file filepath) >>^ concat
;;
