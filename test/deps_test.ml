open Mini_yocaml

let dummy_file_system =
  let open Fake_file_system in
  from_list
    [ dir
        "pages"
        [ file ~mtime:1 "index.md" "Index"
        ; file ~mtime:2 "about.md" "About"
        ; file ~mtime:3 "contact.md" "Contact"
        ]
    ; file ~mtime:4 "index.html" "<body>Hello</body>"
    ]
;;

let test_need_update_1 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 0 in
    let deps = Deps.from_list [] in
    let program (deps, target) = Deps.need_update deps target in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    Alcotest.(check bool) "should be equal" false result)
;;

let test_need_update_2 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 0 in
    let deps = Deps.from_list [ "pages/index.md" ] in
    let program (deps, target) = Deps.need_update deps target in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    Alcotest.(check bool) "should be equal" false result)
;;

let test_need_update_3 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 5 in
    let deps = Deps.from_list [ "pages/index.md" ] in
    let program (deps, target) =
      let open IO.Syntax in
      let* () = Action.write_file "pages/index.md" "New content" in
      Deps.need_update deps target
    in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    let () = Format.printf "%a\n\n" Fake_file_system.pp !fs in
    Alcotest.(check bool) "should be equal" true result)
;;

let test_need_update_4 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 5 in
    let deps = Deps.from_list [ "pages/index.md"; "pages/about.md" ] in
    let program (deps, target) = Deps.need_update deps target in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    Alcotest.(check bool) "should be equal" false result)
;;

let test_need_update_5 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 5 in
    let deps = Deps.from_list [ "pages/index.md"; "pages/about.md" ] in
    let program (deps, target) =
      let open IO.Syntax in
      let* () = Action.write_file "pages/about.md" "foo" in
      let* () = Action.write_file "pages/index.md" "bar" in
      let* () = Action.write_file "index.html" "baz" in
      Deps.need_update deps target
    in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    Alcotest.(check bool) "should be equal" false result)
;;

let test_need_update_6 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 5 in
    let deps = Deps.from_list [ "pages/index.md"; "pages/about.md" ] in
    let program (deps, target) =
      let open IO.Syntax in
      let* () = Action.write_file "pages/about.md" "foo" in
      let* () = Action.write_file "pages/index.md" "bar" in
      Deps.need_update deps target
    in
    let result = Fake_file_system.run ~fs ~time program (deps, "index.html") in
    Alcotest.(check bool) "should be equal" true result)
;;

let test_need_update_7 =
  Alcotest.test_case "need_update" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 5 in
    let deps = Deps.from_list [] in
    let program (deps, target) = Deps.need_update deps target in
    let result = Fake_file_system.run ~fs ~time program (deps, "about.html") in
    Alcotest.(check bool) "should be equal" true result)
;;

let test_cases =
  ( "Deps"
  , [ test_need_update_1
    ; test_need_update_2
    ; test_need_update_3
    ; test_need_update_4
    ; test_need_update_5
    ; test_need_update_6
    ; test_need_update_7
    ] )
;;
