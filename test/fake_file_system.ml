type elt =
  { name : string
  ; mtime : int
  ; content : [ `Dir of t | `File of string ]
  }

and t = elt list

let file ?(mtime = 0) name content = { name; mtime; content = `File content }

let dir name content =
  let mtime =
    List.fold_left (fun acc { mtime; _ } -> max acc mtime) 0 content
  in
  { name; mtime; content = `Dir content }
;;

let log _ = ()
let fail message = Error message
