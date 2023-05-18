val log : string -> unit IO.t
val fail : string -> 'a IO.t
val file_exists : string -> bool IO.t
val get_mtime : string -> int IO.t
val read_file : string -> string IO.t
val write_file : string -> string -> unit IO.t
val read_dir : string -> (string -> bool) -> string list IO.t
val read_files : string -> (string -> bool) -> string list IO.t
val read_directories : string -> (string -> bool) -> string list IO.t
