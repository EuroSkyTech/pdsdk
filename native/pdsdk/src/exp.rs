// just some experiements, please ignore

use futures::TryStreamExt;
use futures::{AsyncReadExt, AsyncSeekExt, Stream, future, io::Cursor, stream};
use ipld_core::cid::multihash::{self, Multihash};
use minicbor::{Decoder, bytes::ByteSlice, data::Tagged};
use tracing::{debug, trace};
use unsigned_varint::aio as varint;

#[derive(Debug, thiserror::Error)]
pub enum CidError {
    #[error("cid hash mismatch")]
    InvalidCid { have: Vec<u8>, want: Vec<u8> },

    #[error("invalid multihash")]
    InvalidMultihash(#[from] multihash::Error),

    #[error("read error")]
    ReadError(#[from] std::io::Error),

    #[error("unsupported cid version {0}")]
    UnsupportedCidVersion(u64),

    #[error("unsupported multihash code {0}")]
    UnsupportedMultihashCode(u64),

    #[error("read error while parsing varint")]
    VarintReadError(#[from] unsigned_varint::io::ReadError),
}

#[derive(Debug, PartialEq)]
pub struct Cid(ipld_core::cid::Cid);

impl Cid {
    pub async fn read<'a, R: AsyncReadExt + Unpin>(mut reader: R) -> Result<Cid, CidError> {
        let version = varint::read_u64(&mut reader).await?;

        if version != 1 {
            return Err(CidError::UnsupportedCidVersion(version));
        }

        // 0x71 (113) == Merkle DAG CBOR
        let multicodec = varint::read_u64(&mut reader).await?;

        let hash_code = varint::read_u64(&mut reader).await?;
        let hash_size = varint::read_usize(&mut reader).await?;

        let mut hash_digest = vec![0; hash_size];
        reader.read_exact(&mut hash_digest).await?;

        // FIXME: seems we don't really need ipld_core and re-exports
        let multihash = Multihash::<64>::wrap(hash_code, &hash_digest)?;

        let cid = ipld_core::cid::Cid::new_v1(multicodec, multihash);

        debug!(
            version,
            multicodec,
            ?multihash,
            hash_code,
            "cid parse parsed"
        );

        Ok(Cid(cid))
    }

    fn verify(&self, data: &[u8]) -> Result<(), CidError> {
        const SHA256: u64 = 0x12;

        match self.0.hash().code() {
            SHA256 => {
                let have = self.0.hash().digest();
                let want = ring::digest::digest(&ring::digest::SHA256, data);
                let want = want.as_ref();

                if have != want {
                    return Err(CidError::InvalidCid {
                        have: have.to_vec(),
                        want: want.to_vec(),
                    });
                }
            }
            _ => {
                return Err(CidError::UnsupportedMultihashCode(self.0.hash().code()));
            }
        }

        Ok(())
    }
}

#[derive(Debug)]
pub struct Section {
    pub cid: Cid,
    pub data: Vec<u8>,
}

#[derive(Debug, thiserror::Error)]
pub enum CarError {
    #[error(transparent)]
    CidError(#[from] CidError),

    #[error("decoding error")]
    EncodingError(#[from] minicbor::decode::Error),

    #[error("read error")]
    ReadError(#[from] std::io::Error),

    #[error("roots map has infinite length")]
    RootsMapInfinite,

    #[error("unexpected element name {have}, expected {want}")]
    UnexpectedElementName { have: String, want: &'static str },

    #[error("unexpected multibase prefix (not identity) {0}")]
    UnexpectedMultibasePrefix(u8),

    #[error("read error while parsing varint")]
    VarintReadError(#[from] unsigned_varint::io::ReadError),
}

pub struct Car<R: AsyncReadExt + AsyncSeekExt + Unpin> {
    pub roots: Vec<Cid>,
    pub version: u8,
    reader: R,
}

impl<R: AsyncReadExt + AsyncSeekExt + Unpin> Car<R> {
    async fn open(mut reader: R) -> Result<Self, CarError> {
        let size = varint::read_usize(&mut reader).await?;
        trace!(size, "header size");

        let mut buf = vec![0; size];
        reader.read_exact(&mut buf).await?;

        let mut decoder = Decoder::new(&buf);

        let size = decoder.map()?.ok_or(CarError::RootsMapInfinite)?;
        trace!(size, "header map items");

        let name = decoder.str()?;

        if name != "roots" {
            return Err(CarError::UnexpectedElementName {
                have: name.to_owned(),
                want: "roots",
            });
        }

        let roots = decoder.array_iter()?.map(|root| async move {
            const TAG_CID: u64 = 42;
            let cid: Tagged<TAG_CID, &ByteSlice> = root?;

            let mut reader = Cursor::new(*cid.value());

            // multibase identity prefix (https://github.com/ipld/cid-cbor)
            let prefix = varint::read_u8(&mut reader).await?;

            if prefix != 0 {
                return Err(CarError::UnexpectedMultibasePrefix(prefix));
            }

            Ok(Cid::read(&mut reader).await?)
        });

        let roots = future::try_join_all(roots).await?;

        let name = decoder.str()?;

        if name != "version" {
            return Err(CarError::UnexpectedElementName {
                have: name.to_owned(),
                want: "version",
            });
        }

        let version = decoder.u8().unwrap();

        Ok(Self {
            reader,
            roots,
            version,
        })
    }

    async fn data(self) -> impl Stream<Item = Result<Section, CarError>> {
        stream::unfold(self, |mut car| async move {
            let size = match varint::read_usize(&mut car.reader).await {
                Ok(size) => size,
                Err(_) => return None,
            };

            match car.read_section(size).await {
                Ok(section) => Some((Ok(section), car)),
                Err(e) => Some((Err(e), car)),
            }
        })
    }

    async fn read_section(&mut self, size: usize) -> Result<Section, CarError> {
        let before_cid = self.reader.stream_position().await?;
        let cid = Cid::read(&mut self.reader).await?;
        let after_cid = self.reader.stream_position().await?;

        let n = after_cid - before_cid;
        let size = size - n as usize;
        let mut data = vec![0; size];

        self.reader.read_exact(&mut data).await?;
        cid.verify(&data)?;

        debug!(?cid, "section parsed");

        Ok(Section { cid, data })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use smol::{fs::File, io::BufReader};

    #[test]
    fn test_fixtures() {
        let result = smol::block_on(async {
            let file = "../fixtures/seabass.bsky.social.20250617001719.car";

            let file = File::open(file).await.unwrap();
            let reader = BufReader::new(file);

            let car = Car::open(reader).await.unwrap();

            car.data()
                .await
                .try_for_each(|section| async move { Ok(()) })
                .await
        });

        result.unwrap();
    }
}

fn main() {}
