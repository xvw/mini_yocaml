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
  | File { name; content; mtime } ->
    Format.fprintf ppf "└─⟢ %s %d \"%s\"" name mtime content
  | Dir { name; children; _ } ->
    Format.fprintf
      ppf
      "└─⟤ %s/@[<v -10>@;%a@]"
      name
      (Format.pp_print_list pp_elt)
      children
;;

let pp ppf x = Format.fprintf ppf "@,%a@." (Format.pp_print_list pp_elt) x

let mtime = function
  | File { mtime; _ } | Dir { mtime; _ } -> mtime
;;

let name = function
  | File { name; _ } | Dir { name; _ } -> name
;;

let compare_fs a b =
  match a, b with
  | File { name = a; _ }, File { name = b; _ }
  | Dir { name = a; _ }, Dir { name = b; _ } -> String.compare a b
  | Dir _, File _ -> -1
  | File _, Dir _ -> 1
;;

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
let testable = Alcotest.testable pp equal
let elt_testable = Alcotest.testable pp_elt equal_elt
let file ?(mtime = 0) name content = File { name; mtime; content }

let dir name children =
  let mtime =
    List.fold_left (fun acc child -> max acc (mtime child)) 0 children
  in
  Dir { name; mtime; children = children |> List.sort compare_fs }
;;

let from_list x = x |> List.sort compare_fs

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

let extract_target path =
  let rec aux acc = function
    | [ x ] -> Some (List.rev acc, x)
    | x :: xs -> aux (x :: acc) xs
    | [] -> None
  in
  aux [] path
;;

let update_elt fs path_str f =
  let path = String.split_on_char '/' path_str in
  match extract_target path with
  | None -> fs
  | Some (path, target) ->
    let rec aux acc fs path =
      match fs, path with
      | [], [] ->
        (* We are in the right directory and the
           file does not exist, we must create it. *)
        f target None :: acc
      | (File { name; mtime; content } as current_file) :: fs_xs, [] ->
        (* We are in the right directory  *)
        if String.equal name target
        then (
          (* This is the file that needs to be modified *)
          let new_file = f target (Some (mtime, content)) in
          new_file :: (acc @ fs_xs))
        else (* This is not the right file *)
          aux (current_file :: acc) fs_xs []
      | (Dir { name; children; _ } as current_dir) :: fs_xs, fragment :: path_xs
        ->
        (* We enter a folder *)
        if String.equal name fragment
        then (
          (* You must enter the directory *)
          let new_dir = dir name (aux [] children path_xs) in
          new_dir :: (acc @ fs_xs))
        else (* This is not the right dir *)
          aux (current_dir :: acc) fs_xs path
      | [], fragment :: path_xs ->
        (* You must create a new directory *)
        let new_dir = dir fragment (aux [] [] path_xs) in
        new_dir :: acc
      | x :: fs_xs, path ->
        (* It is necessary to continue to go through the tree *)
        aux (x :: acc) fs_xs path
    in
    aux [] fs path |> List.sort compare_fs
;;

module Runtime = struct
  let log _ = ()
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

  let write_file ?at fs path content =
    update_elt fs path (fun target _ -> file ?mtime:at target content)
  ;;

  let filter_with kind predicate elt =
    match kind, elt with
    | `Both, (File { name; _ } | Dir { name; _ }) when predicate name ->
      Some name
    | `Files, File { name; _ } when predicate name -> Some name
    | `Directories, Dir { name; _ } when predicate name -> Some name
    | (`Both | `Files | `Directories), _ -> None
  ;;

  let read_dir fs path kind predicate =
    match get_elt fs path with
    | Some (Dir { children; _ }) ->
      List.filter_map (filter_with kind predicate) children
    | _ -> []
  ;;
end

(* Effect Handler *)

let run ~fs ~time program input =
  let handler =
    Effect.Deep.
      { effc =
          (fun (type a) (eff : a Effect.t) ->
            let open Mini_yocaml.Action in
            match eff with
            | Yocaml_log message ->
              Some
                (fun (k : (a, _) continuation) ->
                  let () = Runtime.log message in
                  continue k ())
            | Yocaml_fail message -> Some (fun _ -> failwith message)
            | Yocaml_file_exists path ->
              Some
                (fun (k : (a, _) continuation) ->
                  let result = Runtime.file_exists !fs path in
                  continue k result)
            | Yocaml_get_modification_time path ->
              Some
                (fun (k : (a, _) continuation) ->
                  match Runtime.get_modification_time !fs path with
                  | Ok mtime -> continue k mtime
                  | Error message -> failwith message)
            | Yocaml_read_file path ->
              Some
                (fun (k : (a, _) continuation) ->
                  match Runtime.read_file !fs path with
                  | Ok x -> continue k x
                  | Error message -> failwith message)
            | Yocaml_write_file (path, content) ->
              Some
                (fun (k : (a, _) continuation) ->
                  let () = incr time in
                  let () =
                    fs := Runtime.write_file ~at:!time !fs path content
                  in
                  continue k ())
            | Yocaml_read_dir (path, kind, pred) ->
              Some
                (fun (k : (a, _) continuation) ->
                  let children = Runtime.read_dir !fs path kind pred in
                  continue k children)
            | _ -> None)
      }
  in
  Mini_yocaml.IO.run handler program input
;;

(* Test *)

(* Since this module is present only for
   testing purpose, we can inline tests *)

let pipe_write_file ?at path content fs = Runtime.write_file fs ?at path content

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

let test_update_elt_1 =
  Alcotest.test_case "Some test using update_elt" `Quick (fun () ->
    let fs =
      [ dir
          "."
          [ file "hello.txt" "Hello, World!"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "second post"
              ; dir "images" [ file "foo.png" "an image" ]
              ]
          ]
      ]
    and expected =
      [ dir
          "."
          [ file "hello.txt" "Replaced"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "second post"
              ; dir "images" [ file "foo.png" "an image" ]
              ]
          ]
      ]
    in
    let computed = Runtime.write_file fs "./hello.txt" "Replaced" in
    Alcotest.check testable "should equal" expected computed)
;;

let test_update_elt_2 =
  Alcotest.test_case "Some test using update_elt" `Quick (fun () ->
    let fs =
      [ dir
          "."
          [ file "hello.txt" "Hello, World!"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "second post"
              ; dir "images" [ file "foo.png" "an image" ]
              ]
          ]
      ]
    and expected =
      [ dir
          "."
          [ file "hello.txt" "Hello, World!"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "Replaced"
              ; file "third.md" "Created"
              ; dir "images" [ file "foo.png" "an image" ]
              ]
          ]
      ]
    in
    let computed =
      fs
      |> pipe_write_file "./post/second.md" "Replaced"
      |> pipe_write_file "./post/third.md" "Created"
    in
    Alcotest.check testable "should equal" expected computed)
;;

let test_update_elt_3 =
  Alcotest.test_case "Some test using update_elt" `Quick (fun () ->
    let fs =
      [ dir
          "."
          [ file "hello.txt" "Hello, World!"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "second post"
              ; dir "images" [ file "foo.png" "an image" ]
              ]
          ]
      ]
    and expected =
      [ dir
          "."
          [ file "hello.txt" "Hello, World!"
          ; dir
              "post"
              [ file "index.md" "First post"
              ; file "second.md" "Replaced"
              ; file "third.md" "Created"
              ; dir
                  "images"
                  [ file "foo.png" "an image"
                  ; dir "avatar" [ file "xvw.png" "xvw" ]
                  ]
              ]
          ]
      ; dir "root" [ file "bla.ml" "print_endline" ]
      ]
    in
    let computed =
      fs
      |> pipe_write_file "./post/second.md" "Replaced"
      |> pipe_write_file "./post/third.md" "Created"
      |> pipe_write_file "root/bla.ml" "print_endline"
      |> pipe_write_file "./post/images/avatar/xvw.png" "xvw"
    in
    Alcotest.check testable "should equal" expected computed)
;;

let test_cases =
  ( "Fake_file_system"
  , [ test_get_elt; test_update_elt_1; test_update_elt_2; test_update_elt_3 ] )
;;
