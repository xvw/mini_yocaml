type elt =
  | File of
      { name : string
      ; mtime : int
      ; content : string
      }
  | Dir of
      { name : string
      ; mtime : int
      ; children : elt list
      }

type t = elt list

let rec pp_elt ppf = function
  | File { name; mtime; content } ->
    Format.fprintf ppf "File {%s; %d; %s}" name mtime content
  | Dir { name; mtime; children } ->
    Format.fprintf
      ppf
      "Dir {@[<hov 1>%s; %d; @[<hov 1>%a]@]@]}"
      name
      mtime
      (Format.pp_print_list pp_elt)
      children
;;

let pp = Format.pp_print_list pp_elt

let mtime = function
  | File { mtime; _ } | Dir { mtime; _ } -> mtime
;;

let name = function
  | File { name; _ } | Dir { name; _ } -> name
;;

let compare_fs a b = String.compare (name a) (name b)

let rec equal_elt a b =
  match a, b with
  | ( File { name = name_a; mtime = mtime_a; content = content_a }
    , File { name = name_b; mtime = mtime_b; content = content_b } ) ->
    String.equal name_a name_b
    && Int.equal mtime_a mtime_b
    && String.equal content_a content_b
  | ( Dir { name = name_a; mtime = mtime_a; children = children_a }
    , Dir { name = name_b; mtime = mtime_b; children = children_b } ) ->
    String.equal name_a name_b
    && Int.equal mtime_a mtime_b
    && List.equal
         equal_elt
         (List.sort compare_fs children_a)
         (List.sort compare_fs children_b)
  | _ -> false
;;

let equal = List.equal equal_elt
let fs_testable = Alcotest.testable pp equal
let elt_testable = Alcotest.testable pp_elt equal_elt
let file ?(mtime = 0) name content = File { name; mtime; content }

let dir name children =
  let mtime =
    List.fold_left (fun acc child -> max acc (mtime child)) 0 children
  in
  Dir { name; mtime; children }
;;

let get_elt fs path_str =
  let path = String.split_on_char '/' path_str in
  let rec aux fs path =
    match fs, path with
    | elt :: xs, [ fragment ] ->
      if String.equal (name elt) fragment then Some elt else aux xs path
    | Dir { children; name; _ } :: xs, fragment :: path_xs ->
      if String.equal name fragment then aux children path_xs else aux xs path
    | _ :: xs, path -> aux xs path
    | [], _ -> None
  in
  aux fs path
;;

let log _ = ()
let fail message = Error message
let file_exists fs path = Option.is_some (get_elt fs path)

let get_modification_time fs path =
  match get_elt fs path with
  | None -> Error ("file or directory" ^ path ^ " does not exists")
  | Some x -> Ok (mtime x)
;;

let read_file fs path =
  match get_elt fs path with
  | Some (File { content; _ }) -> Ok content
  | _ -> Error ("file" ^ path ^ " does not exists")
;;

(* Test *)

(* Since this module is present only for
   testing purpose, we can inline tests *)

let test_get_elt =
  let open Alcotest in
  test_case "Some test using get_elt" `Quick (fun () ->
    let fs =
      dir
        "."
        [ file "hello.txt" "Hello, World!"
        ; dir
            "post"
            [ file "index.md" "First post"
            ; file "second.md" "second post"
            ; dir "images" [ file "foo.png" "an image" ]
            ]
        ]
    in
    check (option elt_testable) "should be equal" (Some fs) (get_elt [ fs ] ".");
    check
      (option elt_testable)
      "should be equal"
      (Some (file "hello.txt" "Hello, World!"))
      (get_elt [ fs ] "./hello.txt");
    check
      (option elt_testable)
      "should be equal"
      None
      (get_elt [ fs ] "./asdsadasdsad");
    check
      (option elt_testable)
      "should be equal"
      (Some (file "foo.png" "an image"))
      (get_elt [ fs ] "./post/images/foo.png");
    check
      (option elt_testable)
      "should be equal"
      (Some (file "second.md" "second post"))
      (get_elt [ fs ] "./post/second.md");
    check
      (option elt_testable)
      "should be equal"
      None
      (get_elt [ fs ] "./post/secondz.md");
    check
      (option elt_testable)
      "should be equal"
      (Some
         (dir
            "post"
            [ file "index.md" "First post"
            ; file "second.md" "second post"
            ; dir "images" [ file "foo.png" "an image" ]
            ]))
      (get_elt [ fs ] "./post"))
;;

let test_cases = "Fake_file_system", [ test_get_elt ]
