val testable : Mini_yocaml.Deps.t Alcotest.testable

(** Returns the list of test cases. *)
val test_cases : string * unit Alcotest.test_case list
