open Alcotest

let () =
  run
    "Mini YOCaml's test"
    [ Fake_file_system.test_cases; Deps_test.test_cases; Rule_test.test_cases ]
;;
