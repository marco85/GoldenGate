# Install GoldenGate OS on Surface Laptop 5

Back up your Windows files and save your BitLocker recovery key before changing firmware or installing. This installer replaces the entire selected internal drive, including Windows. It does not offer dual boot.

1. Connect the prepared 16 GB USB and plug the laptop into power.
2. Shut down the Surface. Hold Volume Up while pressing Power to open Surface UEFI. Disable Secure Boot for this unsigned image. Leave it disabled; enrolling a kernel key alone does not establish a signed boot chain.
3. Shut down. Hold Volume Down while pressing and releasing Power to boot USB. Keep holding Volume Down until spinning dots appear below the logo. Choose GoldenGate OS. If needed, put USB Storage first in UEFI boot configuration.
4. Try the live desktop before installing. Test typing, trackpad, touch, Wi-Fi, sound, brightness and sleep/wake. Tick the checklist only after each works. The desktop uses the linux-surface kernel, but hardware behavior still needs testing on this laptop.
5. Open **Install GoldenGate OS**. Select the internal SSD by its model and capacity. If no safe disk appears, stop and check the drive; the installer will not guess.
6. Enter full name, username, computer name and a password of at least 8 characters. Confirm the password. Automatic login is optional and starts off.
7. Acknowledge that your files are backed up. Click **Erase Disk & Install**, review the selected disk and account, then confirm. The base system installs offline from USB; Wi-Fi is needed for online apps and later updates.
8. Keep the USB connected and wait for the completion message. On an error, keep the log visible and correct the problem before retrying. When successful, choose **Restart**, removing the USB as the laptop restarts.
9. Log in with the password you created. Use the network menu for Wi-Fi and System Settings for hardware, language and appearance. Face unlock requires additional software and tested camera support; use password login. LocalSend and some gesture/remapping tools are optional and are not bundled. The browser-based local sharing helper is not Apple's AirDrop protocol.

The image includes Chromium and LibreOffice. AI web launchers require internet access; a launcher does not mean a native desktop client or CLI is installed.

If the button sequence is awkward, Windows 11 can start the USB through **Settings → System → Recovery → Advanced startup → Restart now → Use a device → USB Storage**. In Surface UEFI, ensure **Enable Boot from USB devices** is on. You can also place **USB Storage** first in the boot order. These boot options follow [Microsoft's Surface USB instructions](https://support.microsoft.com/en-us/surface/drivers-firmware/boot-surface-from-a-usb-device).

## Recreate the USB on this Mac

From the project folder, run `sh tools/make-boot-usb.sh --download`. Select only the separate 16 GB USB. The writer refuses internal drives and the 250 GB SANDISK archive drive, erases the selected USB, and verifies its contents after writing. Administrator access is required. Do not interrupt writing or checksum verification.
