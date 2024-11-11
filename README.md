# Foreman Discovery Image - KIWI

This repository contains KIWI image description(s) for Foreman Discovery Images
(FDI) based on various distributions and is a combination of:

- https://github.com/OSInside/kiwi-descriptions
- https://github.com/theforeman/foreman-discovery-image

This can be useful for SecureBoot enabled systems.

# SecureBoot

With shim 15.7 Canonical revoked all currently used keys basically.

- https://lists.ubuntu.com/archives/ubuntu-devel/2023-January/042419.html
- https://lists.ubuntu.com/archives/focal-changes/2023-February/038753.html

Revoked certificates:

- CN = Canonical Ltd. Secure Boot Signing
- CN = Canonical Ltd. Secure Boot Signing (2017)
- CN = Canonical Ltd. Secure Boot Signing (ESM 2018)
- CN = Canonical Ltd. Secure Boot Signing (2019)
- CN = Canonical Ltd. Secure Boot Signing (Ubuntu Core 2019)
- CN = Canonical Ltd. Secure Boot Signing (2021 v1)
- CN = Canonical Ltd. Secure Boot Signing (2021 v2)
- CN = Canonical Ltd. Secure Boot Signing (2021 v3)

kexec only works with kernels signed with new 2022v1 signing key, starting with
Ubuntu 20.04.6 and Ubuntu 22.04.2.

# Versioning

Please set tags in the following format `major.minor-atix`. Example:
```
2.1-atix
```

## Build

Local build:
```
root@ubuntu:~# . /etc/os-release ; echo $PRETTY_NAME
Ubuntu 22.04.4 LTS
root@ubuntu:~# kiwi-ng --version
KIWI (next generation) version 9.25.22
root@ubuntu:~/kiwi-descriptions# kiwi-ng system build --description ubuntu/x86_64/ubuntu-jammy/ --target-dir /tmp/ubuntu
```

### Ubuntu 20.04 Build

Ubuntu 20.04 repositories in OBS have been removed.
Can't be build anymore.

### Ubuntu 22.04 Build

See https://github.com/OSInside/kiwi/issues/2675 for more information regarding "Failed to start Switch Root" issue.
This has been hot fixed in the KIWI description.
