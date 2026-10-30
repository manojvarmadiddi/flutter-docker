# flutter-docker

Docker images for the Flutter **stable** channel, with the Android SDK and web tooling (Chromium) included, one image per Flutter version. Unofficial, not affiliated with Google.

```
ghcr.io/manojvarmadiddi/flutter:<version>
```

## Tags

| Tag | Meaning |
|---|---|
| `3.44.0` | Exactly that Flutter release |
| `3.44` | Newest patch release of the 3.44 line |
| `stable`, `latest` | Newest stable release |

Pin an exact version in your projects so builds stay reproducible.

## Usage

```dockerfile
FROM ghcr.io/manojvarmadiddi/flutter:3.44.0 AS builder
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build web --release
```

Or in CI:

```
docker run --rm -v "$PWD":/app -w /app ghcr.io/manojvarmadiddi/flutter:3.44.0 flutter build apk
```

The image runs as root, has Flutter on `PATH`, and also provides `/sdks/flutter`.

## Platforms

Images are multi-arch: `linux/amd64` and `linux/arm64`. Docker picks the right one, so no `--platform` flag is needed.

| Build | linux/amd64 | linux/arm64 (e.g. Apple Silicon) |
|---|---|---|
| `flutter build web` | yes | yes |
| `flutter build apk` / `appbundle` | yes | **no** |

Google's Android build tools (CMake, parts of the NDK) are x86-64 Linux binaries, so Android builds fail on arm64 Linux. Build APKs on amd64, or run with `--platform linux/amd64` (emulated, slower).

## Building manually

```
./scripts/build.sh --version 3.44.0 --image ghcr.io/<owner>/flutter --push
./scripts/build.sh --version stable --dry-run
```

`--version` takes a release such as `3.44.0` or `stable`. Without `--push` the image is built for your machine's platform only.
