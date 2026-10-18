# GoldenGate pearOS integration plan

Goal: deliver a Surface Laptop 5 live installer on the identified 16 GB USB with pearOS desktop polish and a safer, simple offline installation.
Architecture: retain Arch, linux-surface and Plasma; compile Pear Dock from a pinned upstream revision; keep stock Plasma fallbacks and KDE settings. Repair the existing native PyQt installer rather than ship a second installer.
Authorization: user requested full implementation and selected “use your judgment.” Execute in this session, on a feature branch in the existing clean checkout.

- [x] Installer: reproduce failure-open disk detection and account input bugs with tests; exclude USB/removable/read-only media, require positive discovery, UEFI and payload preflight, validate credentials, avoid shell interpolation, clean up failures and remove live credentials. Add password confirmation, explicit erase acknowledgement, safe defaults, progress and retry.
- [x] Desktop: build pinned GPL Pear Dock and install its dependencies; use it only when present, retain stock fallback; simplify launchers and keep real KDE settings available. Preserve upstream notices.
- [ ] Build verification: test extracted ISO contents, mandatory installer dependencies and UEFI boot in QEMU. Publish only after checks pass. Download and verify checksum.
- [x] Documentation: record findings, provenance and actual install steps; distinguish supported features from optional missing tools.
- [ ] Delivery: re-identify the 16 GB USB, write only the verified build, read back and compare SHA-256. Administrator authorization may require the user's password in a native prompt.

Review focus: no detected disks; external drives; apostrophes/newlines in names/passwords; missing UEFI/kernel payload; errors after mounting; untested hardware claims.

## Execution ledger

- Image source commit: `b666e9b`. Full build: GitHub Actions `39153050337`; corrected serial-console verification reuses exactly matching image sources.
- Configuration/installer/sharing suite: 33 checks pass on Linux; local suite also checks an existing image size (34 total).
- Original ISO boot tested locally under QEMU. Discovered and corrected terminal firstboot prompt, incomplete Aurorae decoration, live welcome overlay, unset wallpaper and dock compatibility defects.
- Disposable VM proved compiled backend readiness (`DOCK_QML_VALID`) and complete applet construction (`GOLDENGATE_DOCK_READY`) after the plugin prefix, obsolete preview and Qt style fixes. Final image still needs fresh CI verification.
- Independent review found no remaining concrete source blocker.
- USB is external removable USB 2.0 FD, disk5, 16,079,781,888 bytes. Archive disk4 (250 GB SANDISK USB) is protected. Recheck identity before writing. Administrator access must be obtained through the native macOS prompt; never ask for a password in chat.
- No current-image USB write has occurred yet. Complete boot/install/installed-login gate, download and checksum verification, then flash and compare readback hash.
