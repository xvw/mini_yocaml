(lang dune 3.0)

(name mini_yocaml)
(version dev)
(generate_opam_files true)

(source (github xvw/mini_yocaml))
(license MIT)
(authors "Hakim Baaloudj" "Xavier Van de Woestyne")
(maintainers "Hakim Baaloudj" "Xavier Van de Woestyne")

(package
 (name mini_yocaml)
 (synopsis "A dead simple implementation of a subset of YOCaml for teaching purpose")
 (description "A dead simple implementation of a subset of YOCaml for teaching purpose")
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0.0))
  (preface (>= 1.0.0))
  (odoc :with-doc)
  (alcotest :with-test)))
