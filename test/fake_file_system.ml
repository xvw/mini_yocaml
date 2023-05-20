type t =
  | File of
      { name : string
      ; mtime : int
      ; content : string
      }
  | Dir of
      { name : string
      ; mtime : int
      ; children : t list
      }

let rec pp ppf = function
  | File { name; mtime; content } ->
    Format.fprintf ppf "File {%s; %d; %s}" name mtime content
  | Dir { name; mtime; children } ->
    Format.fprintf
      ppf
      "Dir {%s; %d; %a}"
      name
      mtime
      (Format.pp_print_list pp)
      children
;;

let rec equal a b =
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
    && List.equal equal children_a children_b
  | _ -> false
;;

let fs_testable = Alcotest.testable pp equal

let mtime = function
  | File { mtime; _ } | Dir { mtime; _ } -> mtime
;;

let name = function
  | File { name; _ } | Dir { name; _ } -> name
;;

let file ?(mtime = 0) name content = File { name; mtime; content }

let dir name children =
  let mtime =
    List.fold_left (fun acc child -> max acc (mtime child)) 0 children
  in
  Dir { name; mtime; children }
;;

let get_elt fs path_str =
  let path = String.split_on_char '/' path_str in
  let rec aux_dir path children =
    match path, children with
    | fragment :: _, x :: xs ->
      if String.equal (name x) fragment then Some (x, path) else aux_dir path xs
    | _ -> None
  in
  let rec aux fs path =
    let () = print_endline (String.concat "/" path) in
    match fs, path with
    | File _, [ fragment ] | Dir _, [ fragment ] ->
      if String.equal (name fs) fragment then Some fs else None
    | File _, _ -> None
    | Dir { children; name; _ }, fragment :: path ->
      if String.equal name fragment
      then
        Option.bind (aux_dir path children) (fun (fs, path) ->
          match path with
          | [] -> Some fs
          | _ -> aux fs path)
      else None
    | _ -> None
  in
  aux fs path
;;

let log _ = ()
let fail message = Error message

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
    check (option fs_testable) "should be equal" (Some fs) (get_elt fs ".");
    check
      (option fs_testable)
      "should be equal"
      (Some (file "hello.txt" "Hello, World!"))
      (get_elt fs "./hello.txt");
    check
      (option fs_testable)
      "should be equal"
      None
      (get_elt fs "./asdsadasdsad");
    check
      (option fs_testable)
      "should be equal"
      (Some (file "foo.png" "an image"))
      (get_elt fs "./post/images/foo.png");
    check
      (option fs_testable)
      "should be equal"
      (Some (file "second.md" "second post"))
      (get_elt fs "./post/second.md");
    check
      (option fs_testable)
      "should be equal"
      None
      (get_elt fs "./post/secondz.md");
    check
      (option fs_testable)
      "should be equal"
      (Some
         (dir
            "post"
            [ file "index.md" "First post"
            ; file "second.md" "second post"
            ; dir "images" [ file "foo.png" "an image" ]
            ]))
      (get_elt fs "./post"))
;;

let test_cases = "Fake_file_system", [ test_get_elt ]
