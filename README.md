# mini_yocaml

A dead simple implementation of a subset of YOCaml for teaching purpose

## Setting up the development environment

Setting up a development environment is quite common. We recommend setting up a
local switch to collect dependencies locally. Here are the commands to enter to
initiate the environment:

```shellsession
opam update
opam switch create . ocaml-base-compiler.5.0.0 --deps-only -y
eval $(opam env)
```

After initializing the switch, you can collect the development and project
dependencies using `make`:

```shellsession
make dev-deps
make deps
```
