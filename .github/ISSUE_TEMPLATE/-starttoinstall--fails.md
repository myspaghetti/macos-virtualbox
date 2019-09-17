---
name: '"starttoinstall" fails'
about: Helpful troubleshooting information when "starttoinstall" fails
title: ''
labels: bug
assignees: myspaghetti

---

**Troubleshooting information**
Installer log can be uploaded from the guest machine with the following Terminal command:
```
curl -F 'f:1=@/var/log/install.log' ix.io
```

Checksum of `InstallESD.dmg` can be computed on the guest machine with the following Terminal command:
```
md5 /Install*/Contents/SharedSupport/InstallESD.dmg
```

Checksums for the files split from `InstallESD.dmg` on the host machine can be computed by executing the following command at the script's working directory:
```
for part in *.part*; do md5sum "${part}"; done
```
