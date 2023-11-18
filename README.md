# The Bureaucrat

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

The Service which takes care of the redis cache.

## Purpose

- Receives Waypoints via `grpc`
- manages the current state of the transport network in the redis cache

## Service Configuration

Following Environment Variables are read by there service

- **BUREAUCRAT_HOST** Where the service accepts grpc data
- **RUST_LOG** log level
- **RUST_BACKTRACE** stack traces
- **REDIS_HOST** host of the redis server
- **REDIS_PORT** port of the redis server
