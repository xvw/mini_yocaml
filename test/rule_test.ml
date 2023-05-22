open Mini_yocaml

let dummy_file_system =
  let open Fake_file_system in
  from_list
    [ dir
        "pages"
        [ file "index.md" "Index"
        ; file "about.md" "About"
        ; file "contact.md" "Contact"
        ]
    ; dir "templates" [ file "header.md" "Header"; file "footer.md" "Footer" ]
    ]
;;

let test_create_file_1 =
  Alcotest.test_case "create_file" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 0 in
    let program () =
      let open Rule in
      let open IO.Syntax in
      let* () = create_file "index.html" (read_file "pages/index.md") in
      let* () = create_file "about.html" (read_file "pages/about.md") in
      create_file "contact.html" (read_file "pages/contact.md")
    in
    let () = Fake_file_system.run ~fs ~time program () in
    let expected =
      let open Fake_file_system in
      from_list
        [ dir
            "pages"
            [ file "index.md" "Index"
            ; file "about.md" "About"
            ; file "contact.md" "Contact"
            ]
        ; dir
            "templates"
            [ file "header.md" "Header"; file "footer.md" "Footer" ]
        ; file ~mtime:1 "index.html" "Index"
        ; file ~mtime:2 "about.html" "About"
        ; file ~mtime:3 "contact.html" "Contact"
        ]
    in
    Alcotest.check Fake_file_system.testable "should be equal" expected !fs)
;;

let test_create_file_2 =
  Alcotest.test_case "create_file" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 0 in
    let program () =
      let open Rule in
      let open IO.Syntax in
      let* () = Action.write_file "about.html" "Up to date" in
      let* () = create_file "index.html" (read_file "pages/index.md") in
      let* () = create_file "about.html" (read_file "pages/about.md") in
      create_file "contact.html" (read_file "pages/contact.md")
    in
    let () = Fake_file_system.run ~fs ~time program () in
    let expected =
      let open Fake_file_system in
      from_list
        [ dir
            "pages"
            [ file "index.md" "Index"
            ; file "about.md" "About"
            ; file "contact.md" "Contact"
            ]
        ; dir
            "templates"
            [ file "header.md" "Header"; file "footer.md" "Footer" ]
        ; file ~mtime:2 "index.html" "Index"
        ; file ~mtime:1 "about.html" "Up to date"
        ; file ~mtime:3 "contact.html" "Contact"
        ]
    in
    Alcotest.check Fake_file_system.testable "should be equal" expected !fs)
;;

let test_create_file_3 =
  Alcotest.test_case "create_file" `Quick (fun () ->
    let fs = ref dummy_file_system in
    let time = ref 0 in
    let rule =
      Rule.(
        read_file "templates/header.md"
        >>> concat_file ~separator:"|" "pages/index.md"
        >>> concat_file ~separator:"|" "templates/footer.md"
        >>^ String.uppercase_ascii)
    in
    let program () = Rule.create_file "index.html" rule in
    let () = Fake_file_system.run ~fs ~time program () in
    let expected_deps =
      Deps.from_list
        [ "templates/header.md"; "pages/index.md"; "templates/footer.md" ]
    in
    let expected =
      let open Fake_file_system in
      from_list
        [ dir
            "pages"
            [ file "index.md" "Index"
            ; file "about.md" "About"
            ; file "contact.md" "Contact"
            ]
        ; dir
            "templates"
            [ file "header.md" "Header"; file "footer.md" "Footer" ]
        ; file ~mtime:1 "index.html" "HEADER|INDEX|FOOTER"
        ]
    in
    Alcotest.check Fake_file_system.testable "should be equal" expected !fs;
    Alcotest.check
      Deps_test.testable
      "should be equal"
      expected_deps
      (Rule.deps_of rule))
;;

let test_cases =
  "Rule", [ test_create_file_1; test_create_file_2; test_create_file_3 ]
;;
