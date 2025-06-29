# Reference implementations

This file contains reference implementations for relevant ATProto components.

## PDS

The reference [PDS server](https://github.com/bluesky-social/atproto/tree/main/packages/pds) from bluesky-social. This is not using the (derived) [PDS project](https://github.com/bluesky-social/pds/tree/main) to make it easier to patch / modify the underlying source code.

Start and stop the PDS server using `just pds-build` and then `just pds-run`.

Notes:

- This setup assumes anything under the .localhost TLD is generally resolved to localhost
- This setup currently does not (yet) utilizes a TLS reverse proxy
- Due to an long standing [issue](https://github.com/docker/cli/issues/3630) of standalone Docker with quotes, the [example .env](https://github.com/bluesky-social/atproto/blob/76367f8a94602cd4b89f6d1d2c4956fdc1b2ba7b/packages/pds/example.env) does not work and needs modification
- In the current version of the example `.env`, the OAUTH specific `PDS_DPOP_SECRET` is missing; the full list can be found at [here](https://github.com/bluesky-social/atproto/blob/main/packages/pds/src/config/env.ts)
