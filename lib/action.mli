(** Here we describe all the effects that can be propagated by the generator. It
    is, in broad terms, a set of primitives to interact with the file system.

    The main difference with YOCaml is that, for the purposes of the exercise,
    it is assumed that there is only one runtime (in YOCaml, it is necessary to
    distinguish the target from the source, for example, to be able to read from
    UNIX and write to Git, for the needs of Mirage). *)

(** We have to re-export the effects, even if they are packed in [IO] by means
    of functions, to be able to interpret them afterwards. *)
type _ Effect.t +=
  | Yocaml_log : string -> unit Effect.t
  | Yocaml_fail : string -> 'a Effect.t
  | Yocaml_file_exists : string -> bool Effect.t
  | Yocaml_get_modification_time : string -> int Effect.t
  | Yocaml_read_file : string -> string Effect.t
  | Yocaml_write_file : string * string -> unit Effect.t
  | Yocaml_read_dir :
      string * [< `Files | `Directories | `Both ] * (string -> bool)
      -> string list Effect.t

(** [log message] performs the effect Log, used for displaying stuff on STDout. *)
val log : string -> unit IO.t

(** [fail message] fail with a message. One could imagine a more sophisticated
    error management but for the purpose of the exercise, it is more than
    enough.*)
val fail : string -> 'a IO.t

(** [file_exists path] produces an effect returning [true] if the target exists,
    [false] otherwise.*)
val file_exists : string -> bool IO.t

(** [get_mtime path] produces an effect that returns the modification date of a
    target. The function can fail, however, it is assumed that it must succeed
    and it is the handler's responsibility to stop the program execution if the
    target does not exist (or is unreadable). *)
val get_mtime : string -> int IO.t

(** [read_file path] produces an effect that returns the contents of a file. The
    function can fail, however, it is assumed that it must succeed and it is the
    responsibility of the handler to interrupt the execution of the program if
    the target does not exist (or is unreadable).*)
val read_file : string -> string IO.t

(** [write_file path content] produces an effect that writes [content] in a
    target. The function can fail, however, it is assumed that it must succeed
    and it is the responsibility of the handler to interrupt the execution of
    the program if the target does not exist (or is unreadable). *)
val write_file : string -> string -> unit IO.t

(** [read_dir target predicate] produces an effect that returns a list of
    children that satisfies [predicate]. If the target does not exists, the
    function will returns an empty list. *)
val read_dir : string -> (string -> bool) -> string list IO.t

(** [read_files target predicate] produces an effect that returns a list of
    children (files) that satisfies [predicate]. If the target does not exists,
    the function will returns an empty list. *)
val read_files : string -> (string -> bool) -> string list IO.t

(** [read_directories target predicate] produces an effect that returns a list
    of children (directories) that satisfies [predicate]. If the target does not
    exists, the function will returns an empty list. *)
val read_directories : string -> (string -> bool) -> string list IO.t
