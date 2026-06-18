# Changelog

## [1.1.0](https://github.com/jrjohn/arcana-ios/compare/v1.0.0...v1.1.0) (2026-06-18)


### Features

* **tests:** boost iOS coverage toward 80% ([4beb125](https://github.com/jrjohn/arcana-ios/commit/4beb125a16127061cd66e2a9f25b08ee03ce5458))
* update bundle ID to com.arcana.example for TestFlight ([2341601](https://github.com/jrjohn/arcana-ios/commit/23416011a912d059bc29d04496ed9729a29960c6))


### Bug Fixes

* add async to UserFormViewModelTests functions using await withDependencies ([f4582fc](https://github.com/jrjohn/arcana-ios/commit/f4582fc1cd84019c7a75d6f2206e3b032c6e432c))
* **arch-qube:** rename OfflineFirstUserRepository → Impl (impl-naming rule) ([9add363](https://github.com/jrjohn/arcana-ios/commit/9add3637a09e11497a5daaa90a0ced202513faca))
* caffeinate + 40min shell timeout + simulator pre-boot for iOS test stage ([9f18134](https://github.com/jrjohn/arcana-ios/commit/9f181346bd1e35611a15446cedbc6b36550d3600))
* **ci:** switch Sonar to direct CLI via withSonarQubeEnv; drop leaked token ([e7fe4c9](https://github.com/jrjohn/arcana-ios/commit/e7fe4c9285f1a2df8efe1c4bd13bc5d94e192add))
* complete OfflineFirstUserRepository → Impl rename at missed call sites ([a594923](https://github.com/jrjohn/arcana-ios/commit/a594923dd316b9cb38f6bb9c1cffe842dd27fdec))
* **coverage:** exclude non-unit-testable files from coverage XML ([9b2dffc](https://github.com/jrjohn/arcana-ios/commit/9b2dffcb84d30ff4251bb7380ec21e0de59a4cd0))
* explicit xcresult path + better debug logging ([4c6c512](https://github.com/jrjohn/arcana-ios/commit/4c6c51290de366bbff5f8ce681b3eb4d10ecfa46))
* Groovy parse error in sed backslash + caffeinate cleanup ([ebff636](https://github.com/jrjohn/arcana-ios/commit/ebff636fb5d981dbf82791c9b116abb095c8ebb2))
* increase timeout to 60min + persistent DerivedData + SPM pre-resolve ([cf1a600](https://github.com/jrjohn/arcana-ios/commit/cf1a600506c478525d3751347e1255677d7b705b))
* iPhone 17 simulator + full sonar-scanner path ([138e4bc](https://github.com/jrjohn/arcana-ios/commit/138e4bca1112cbdcbb686c4a33c2a75f6d94112e))
* MainViewModelTests API mismatch + add SonarQube coverage infrastructure ([acb04da](https://github.com/jrjohn/arcana-ios/commit/acb04dafc2dd9e1c3f7e38883c5f96cb18b05a36))
* nohup xcodebuild with heartbeat poll loop (survives Mac Mini disconnects) ([75bb85a](https://github.com/jrjohn/arcana-ios/commit/75bb85ad573b8e9c17eb1ce32f732a6f4444d6f6))
* redirect xcodebuild to file (SIGPIPE) + use sonar-scanner-cli:11 ([4eaf2f3](https://github.com/jrjohn/arcana-ios/commit/4eaf2f39c62b5a93b981bbcf35b35e7c4b133691))
* remaining UserListViewModelTests compile errors ([b771653](https://github.com/jrjohn/arcana-ios/commit/b7716536abc4cd58a14ebc81c807d580add3db79))
* remove await from sync withDependencies in UserFormViewModelTests ([f510953](https://github.com/jrjohn/arcana-ios/commit/f51095325a095e1ea9a4d5d2bdb755750d46bbc4))
* remove duplicate UserRemoteDaoImpl.swift (causes Xcode build error) ([bde0d23](https://github.com/jrjohn/arcana-ios/commit/bde0d2331faeaa3a7a9429206741cfd5d4800139))
* remove GNU timeout (not on macOS) from xcodebuild test command ([7e50cc9](https://github.com/jrjohn/arcana-ios/commit/7e50cc9c8c2d3f82ffafd83751e7f50f8c164f89))
* remove misplaced UserRemoteDaoMockImpl.swift from xcodeproj dir ([a6cb557](https://github.com/jrjohn/arcana-ios/commit/a6cb557053dcd4454c969425af1b5951baf18cd5))
* rewrite Presentation tests for @Observable output pattern ([13e2c49](https://github.com/jrjohn/arcana-ios/commit/13e2c491657effb7b9e4f703d8fa6c981344dd5f))
* **sonar:** remove unused _UnusedMockAnalyticsTracker class in UserListView ([bfbc2f0](https://github.com/jrjohn/arcana-ios/commit/bfbc2f02bfe1912b4530620d703ccfbe4140a86b))
* test failures and xcresult coverage script ([4439eea](https://github.com/jrjohn/arcana-ios/commit/4439eea886b36d04c424a38e9ef2161b21f53fec))
* update DEVELOPMENT_TEAM to 89YYRF88M3 ([7da5c40](https://github.com/jrjohn/arcana-ios/commit/7da5c4090d66e8dc6b4f7fb70c906f030cf5869e))
* use /opt/homebrew/bin/sonar-scanner (just installed via brew) ([15f659f](https://github.com/jrjohn/arcana-ios/commit/15f659f475a80da648210a7c4b9a1c01daac9b33))
