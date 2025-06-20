# Next

- CID: struct, how to address the different serializations? from_str, to_str?
- clarify required indexes (according to ATProto XRPC features) and build persistence (sdk user supplies path)
- consider https://crates.io/crates/tsify for TS generation
- get rid of ipld-core
- disable strip profile in profile for target or fix memory optimization ins wasm-opt (see https://github.com/leptos-rs/cargo-leptos/issues/441)

# Tasks

## Targets

- add react native
- test dynamic libraries for various targets
- limits libs per target
- enable ditto compression for ios (https://rhonabwy.com/2023/02/10/creating-an-xcframework/)
- also generate a simple unit test à la swift pkg - currently we don't do that because we cannot simply provide an .so for Mac

## Namespaces

- unify namespaces for packages (aar: com.bignextthing.pdsdk)
- unify namespaces for apps (ios: example? swift: com.bignextthing.eurosky3000, android: com.bignextthing.eurosky3000)
