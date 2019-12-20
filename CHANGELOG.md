# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased] Unreleased
### Added
- Multi-thread processing for consumer.
- Temporarily disables throttling.

## [0.2.1] 2019-08-27
### Fixed:
- Keep set name for main topic

## [0.2.0] 2019-08-26
### Changed:
- retry logic

## [0.1.7] 2019-07-31
### Changed:
- Setting logger level to debug on processor

## [0.1.6] 2019-07-30
### Added:
- Log received messages on tasks

## [0.1.5] 2019-07-24
### Fixed
- CLI options
- Error when running process with a single stage

## [0.1.4] 2019-07-24
### Fixed
- Reliable Auto Retries & Auto Seeks.

## [0.1.3] 2019-07-19
### Fixed:
- Flusher execution.

## [0.1.2] 2019-07-17
### Fixed:
- Newline character for exception backtraces.

## [0.1.1] 2019-07-17
### Fixed:
- Log exception backtraces.

## [0.1.0] 2019-07-16
### Fixed:
- Retry topic naming to include the Task Group ID.

### Added:
- Flux::Task: task handlers.
- Flux::Reactor: consumption framework.
- Flux::Producer: producer framework.
- Flux::CLI.
