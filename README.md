# Read Me

This writeup corresponds to tag `v1.7.0` of the [TarSum Checksum Specification](https://github.com/docker/docker/blob/v1.7.0/pkg/tarsum/tarsum_spec.md).

**tl;dr** The `v1` specification of the TarSum algorithm is insecure and makes it trivial to construct multiple hash collisions. This is because TarSum can be viewed as a flawed implementation of a [Merkle–Damgård construction](https://en.wikipedia.org/wiki/Merkle%E2%80%93Damg%C3%A5rd_construction).

## Update

After contacting the security team at Docker with this result, I received the following response in early July, 2015:

> Thank you for your report. We understand and acknowledge that the TarSum algorithm is flawed. The v2 image format present in newer versions of Docker is designed not to be dependent on TarSum, but to use sha256 hashes of the tar itself. The TarSum algorithm is in the process of being on a track to depreciation with the v1 format.

followed by

> I'd like to point you to some resources regarding the effort to eliminate tarsum. We consider tarsum depreciated and are no longer seeking to spot-fix its various flaws and are committed to offering a quick and efficient replacement.
>
> https://github.com/docker/docker/issues/9719
> https://github.com/docker/distribution/pull/238
> https://github.com/docker/docker/pull/11271
> https://github.com/docker/docker/pull/14067

Another response a couple of weeks later said

> [...] it's not been a huge secret that TarSum is insecure. Folks at Docker just did not want to broadcast it because there wasn't a solution yet. As of today TarSum is only used for local build caching, not registry pushes and subsequent pulls.

So there you have it!

## More Detail

To a large extent, the insecurity of TarSum is best paraphrased by[this comment of Docker issue 9719](https://github.com/docker/docker/issues/9719#issuecomment-67922295).

> You're hoping to build a data-authentication scheme that first requires parsing the data to be authenticated. 

The underlying problem is that the TarSum algorithm attempts to build a collision-resistant cryptographic hash function (the final TarSum) from a set of collision-resistant one-way compression functions (SHA256 or SHA512). In principle, this is a [Merkle–Damgård construction](https://en.wikipedia.org/wiki/Merkle%E2%80%93Damg%C3%A5rd_construction) and is provably secure _if an appropriate padding scheme is used_.

Unfortunately, none of the basic blocks of the TarSum construction are properly padded or delimited. These blocks include the header and file data, and also include sub-blocks such as the file metadata (file name, ownership, date and times, and so on).

As a trivial example, the `demo.sh` shows three different `tar` files that have the same TarSum due to the fact that extended attributes are not appropriately padded nor delimited. It works because the attributes

- `a=bc`,
- `ab=c`, and
- `abc=` (null)

all have the same cryptographic hash under TarSum encoding.

Note that the overall attack is _**not**_ just limited to extended attributes because the chaining function "smears" this insecurity over the entire hash, making it vulnerable to a whole host of cryptographic attacks, most of which become _trivial_.

## Even Worse

If there's one thing that **decades** of experience with [X.509](https://en.wikipedia.org/wiki/X.509) has taught us, and most of that experience [has been mind-numbingly horrible](https://www.cs.auckland.ac.nz/~pgut001/pubs/x509guide.txt), is that creating a cryptographically-secure round-trip data serialization and de-serialization format is _really, really, really_ difficult.

Just don't do it.

To make things worse, there are _multiple_ attack vectors in the `tar` format. Dates and times are not unambiguously specified (for example, via number of decimal places or leading and trailing zeros). You _really, really, really_ do not want to get into [Unicode normalization and canonical equivalencee](https://en.wikipedia.org/wiki/Unicode_equivalence). And all three major OS flavours (Linux, MacOS, and Windows) all handle it _semantically differently_. See the [Rust Project](http://www.rust-lang.org/) for the hell that they went through dealing with this issue.

## Why This is Bad

Because humans are human, if a human sees "SHA256" or "SHA512" that person will almost alway assume that the cryptographic hash has, to a large extent, a one-to-one correspondence with a single piece of data. That's the basis of digital signature algorithms. However, the TarSum value **appears to promise collision resistance when there is none**.

So as is, the Docker system _appears_ to provide "strong crptography", but in reality it cannot even reliably implement digitally signed image layers.

## How To Fix It

There are two possible ways of proceeding. Th most obvious is to modify the TarSum algorithm to properly delimit and pad the blocks that are fed into the cryptographic hash. However, dates, times, and filename components all require normalization as well. This is a very non-trivial specification.

**The better way to go** for TarSum `v2` would be to replace the underlying cryptographic hash with a _standard_ hash function. In specific, [MurmurHash3](https://en.wikipedia.org/wiki/MurmurHash) (also see [here](https://code.google.com/p/smhasher/wiki/MurmurHash3) and [here](https://github.com/PeterScott/murmur3)) would be a fantastic choice as it comes in a 128-bit variant that is blazingly fast on 64-bit processors. This could be `tarsum.v2+murmur3/128`.

The use of a _non_-cryptographic hash keeps the benefits of the TarSum algorithm but deprecates the promise that archives with identical TarSums are semantically identical.

The use of a _cryptographic_ hash function, such as SHA256 or SHA512, should be reserved to specify the final archive itself, thus guaranteeing bit-exact equivalence when such a guarantee is needed.
