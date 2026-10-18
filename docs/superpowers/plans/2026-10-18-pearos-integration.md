# GoldenGate pearOS integration plan

Goal: deliver a Surface Laptop 5 live installer on the identified 16 GB USB with pearOS desktop polish and a safer, simple offline installation.
Architecture: retain Arch, linux-surface and Plasma; compile Pear Dock from a pinned upstream revision; keep stock Plasma fallbacks and KDE settings. Repair the existing native PyQt installer rather than ship a second installer.
Authorization: user requested full implementation and selected “use your judgment.” Execute in this session, on a feature branch in the existing clean checkout.

- [ ] Installer: reproduce failure-open disk detection and account input bugs with tests; exclude USB/removable/read-only media, require positive discovery, UEFI and payload preflight, validate credentials, avoid shell interpolation, clean up failures and remove live credentials. Add password confirmation, explicit erase acknowledgement, safe defaults, progress and retry.
- [ ] Desktop: build pinned GPL Pear Dock and install its dependencies; use it only when present, retain stock fallback; simplify launchers and keep real KDE settings available. Preserve upstream notices.
- [ ] Build verification: test extracted ISO contents, mandatory installer dependencies and UEFI boot in QEMU. Publish only after checks pass. Download and verify checksum.
- [ ] Documentation: record findings, provenance and actual install steps; distinguish supported features from optional missing tools.
- [ ] Delivery: re-identify the 16 GB USB, write only the verified build, read back and compare SHA-256. Administrator authorization may require the user's password in a native prompt.

Review focus: no detected disks; external drives; apostrophes/newlines in names/passwords; missing UEFI/kernel payload; errors after mounting; untested hardware claims.
