# Next

- WASM support

# Tasks

## Low hanging fruits

- re-enable just LS, run just fmt

## Targets

- add wasm
- add react native
- test dynamic libraries for various targets
- limits libs per target
- enable ditto compression for ios (https://rhonabwy.com/2023/02/10/creating-an-xcframework/)
- also generate a simple unit test à la swift pkg - currently we don't do that because we cannot simply provide an .so for Mac

## Namespaces

- unify namespaces for packages (aar: com.bignextthing.pdsdk)
- unify namespaces for apps (ios: example? swift: com.bignextthing.eurosky3000, android: com.bignextthing.eurosky3000)

## Testing / Reproducing

- Build a VM to test the first-time setup (including all Android & iOS dependencies)
