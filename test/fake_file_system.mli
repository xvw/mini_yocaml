(** [Fake_file_system] allows to mount a virtual file system (controlled by the
    user) to test programs efficiently. It implements an effects manager to
    interpret YOCaml effects. *)

(** The type that describes a file system. *)
type t

(** A type that describes a file system element (can be a directory or a file). *)
type elt

(** [file ?mtime name content] builds a file. *)
val file : ?mtime:int -> string -> string -> elt

(** [dir name children] builds a directory. The [mtime] of the directory will be
    calculated as the maximum [mtime] of its children.*)
val dir : string -> elt list -> elt

(** Builds a virtual file system, for example:

    {[
      let a_filesystem =
        from_list
          [ dir
              "lib"
              [ file "dune" "(library (name my_lib))"
              ; file "my_lib.ml" "let f x = x + 1"
              ]
          ; dir
              "doc"
              [ file "intro.md" "Hello World"
              ; file "install.md" "Installation guide"
              ]
          ; file "README.md" "My library"
          ; file "LICENSE" "The MIT license"
          ]
      ;;
    ]} *)
val from_list : elt list -> t

(** [run ~fs ~time program x] executes the [program x] in the context of a
    virtual filesystem.

    As a file system is, by nature, imperative, so it is possible to initialize
    a virtual file system in a refeŕence, to allow it to be observed post-hoc. *)
val run : fs:t ref -> time:int ref -> ('a -> 'b Mini_yocaml.IO.t) -> 'a -> 'b

val equal : t -> t -> bool
val pp : Format.formatter -> t -> unit
val testable : t Alcotest.testable

(** Returns the list of test cases. *)
val test_cases : string * unit Alcotest.test_case list
