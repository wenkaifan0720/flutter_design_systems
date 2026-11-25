# Contributing

Issues are welcome. For a bug, give the smallest code that shows it, what you expected, the package's version, the
Flutter version (`flutter --version`) and the platform. For an idea, say what the app needs it for.

## Running the checks

From the repository root, for a package such as `ui_core`:

```sh
flutter pub get
dart analyze --fatal-infos packages/ui_core
(cd packages/ui_core && flutter test --exclude-tags goldens)
```

The pixel goldens were recorded on macOS and run there (`flutter test --tags goldens` in a package). The looks'
golden images aren't kept in this repository, so their golden tests skip themselves.

## Pull requests

The packages are generated from a source tree outside this repository, so a pull request is not merged as it stands:
its change is carried into that source and lands in a release. Keep a pull request to one change, with a test that
fails without it. Code passes `dart analyze --fatal-infos` with the package's analysis options and is formatted with
`dart format`.

## Licence

By contributing, you agree that your contribution is licensed under the BSD 3-Clause licence in [LICENSE](LICENSE).
