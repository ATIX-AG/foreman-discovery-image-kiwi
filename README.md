# Foreman Discovery Image

This repository contains KIWI image description(s) for Foreman Discovery Images
(FDI) based on various distributions. This is required on SecureBoot enabled
systems.

## Build

Local build:
```
localhost:~ # kiwi-ng --version
KIWI (next generation) version 9.24.36
localhost:~ # kiwi-ng --debug system build --description ubuntu/x86_64/ubuntu-focal --target-dir /tmp/ubuntu
```
