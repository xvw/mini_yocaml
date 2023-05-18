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

let log message = IO.perform @@ Yocaml_log message
let fail message = IO.perform @@ Yocaml_fail message
let file_exists path = IO.perform @@ Yocaml_file_exists path
let get_mtime path = IO.perform @@ Yocaml_get_modification_time path
let read_file path = IO.perform @@ Yocaml_read_file path
let write_file path content = IO.perform @@ Yocaml_write_file (path, content)
let read_dir_with k path p = IO.perform @@ Yocaml_read_dir (path, k, p)
let read_dir = read_dir_with `Both
let read_files = read_dir_with `Files
let read_directories = read_dir_with `Directories
