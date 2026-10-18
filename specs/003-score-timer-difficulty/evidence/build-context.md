# Build context

2026-10-18, repository-root working directory. Discovery only, no tests/services launched.

- Xcode 27.0, build 27A266a; Swift5 language mode, deployment iOS26.
- dotnet --version: 10.0.401, root global.json latestPatch. Existing API/test csproj packages retained.
- Existing shared schemes: DonkeyTrump3D, Local, DEV, PROD, AppStoreCapture.
- Compile-only destinations: generic/platform=iOS Simulator; schemes Local Debug Local and DonkeyTrump3D Release. No signing, no simulator boot.
- Existing root .gitignore and backend .dockerignore/Dockerfile.dockerignore cover Swift/.NET, Python helpers, credentials/local settings, emulator/build outputs. No additional publishing/tool ignore file needed.
- xcrun simctl list devices available inspected: iPhone13 iOS26.5/27 simulators available. No physical-device evidence.
- Build/test targets and phases will be inspected before compilation; no test action authorized.
