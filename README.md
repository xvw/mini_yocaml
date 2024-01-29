# mini_yocaml

A dead simple implementation of a subset of YOCaml for teaching purpose.

[YOCaml](https://github.com/xhtmlboi/yocaml) is a generator of blog generators.
In a sense, a kind of DSL capable of describing tasks that interact with a file
system. Although its general operation is described in the [following
article](https://xhtmlboi.github.io/articles/yocaml.html), pair-programming a
subset of the overall system is a very good exercise, allowing you to experiment
with the use of OCaml 5's `user-defined-effects`, rather than using YOCaml's
venerable Freer Monad.

**The aim is not to end up with a YOCaml competitor.**

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
