#!/bin/bash
# macOS Headless Inference Server Hardening Script
# Requires SIP to be disabled first:
#   1. Boot into Recovery Mode (hold power button)
#   2. Run: csrutil disable
#   3. Reboot and run this script
#   4. Boot into Recovery Mode again
#   5. Run: csrutil enable
#   6. Reboot
#
# Run as: sudo bash macos-headless.sh

echo "==> Disabling Spotlight..."
launchctl disable system/com.apple.metadata.mds || true
launchctl disable system/com.apple.metadata.mds.index || true
launchctl disable system/com.apple.metadata.mds.scan || true
launchctl disable system/com.apple.metadata.mds.spindump || true
mdutil -a -i off || true

echo "==> Disabling Bluetooth..."
launchctl disable system/com.apple.bluetoothd || true
launchctl disable system/com.apple.BTServer.le || true
launchctl disable system/com.apple.BlueTool || true

echo "==> Disabling Find My..."
launchctl disable system/com.apple.findmymacd || true
launchctl disable system/com.apple.icloud.findmydeviced || true
launchctl disable system/com.apple.findmy.findmybeaconingd || true

echo "==> Disabling iCloud..."
launchctl disable system/com.apple.cloudd || true
launchctl disable system/com.apple.icloud.searchpartyd || true
launchctl disable system/com.apple.xartstorageremoted || true

echo "==> Disabling Analytics & Telemetry..."
launchctl disable system/com.apple.analyticsd || true
launchctl disable system/com.apple.ecosystemanalyticsd || true
launchctl disable system/com.apple.osanalytics.osanalyticshelper || true
launchctl disable system/com.apple.wifianalyticsd || true
launchctl disable system/com.apple.audioanalyticsd || true
launchctl disable system/com.apple.triald.system || true
launchctl disable system/com.apple.rtcreportingd || true
launchctl disable system/com.apple.SubmitDiagInfo || true
launchctl disable system/com.apple.ReportCrash.Root || true
launchctl disable system/com.apple.spindump || true
launchctl disable system/com.apple.sysdiagnose || true
launchctl disable system/com.apple.tailspind || true
launchctl disable system/com.apple.symptomsd-diag || true
launchctl disable system/com.apple.eligibilityd || true

echo "==> Disabling Location Services..."
launchctl disable system/com.apple.locationd || true

echo "==> Disabling Time Machine..."
launchctl disable system/com.apple.backupd || true
launchctl disable system/com.apple.backupd-helper || true

echo "==> Disabling AirPlay & Continuity..."
launchctl disable system/com.apple.AirPlayXPCHelper || true
launchctl disable system/com.apple.rapportd || true
launchctl disable system/com.apple.nearbyd || true
launchctl disable system/com.apple.sharingd || true
launchctl disable system/com.apple.wifip2pd || true

echo "==> Disabling Game Center..."
launchctl disable system/com.apple.GameController.gamecontrollerd || true
launchctl disable system/com.apple.gamepolicyd || true

echo "==> Disabling Music..."
launchctl disable system/com.apple.musicd || true

echo "==> Disabling NFC..."
launchctl disable system/com.apple.nfcd || true

echo "==> Disabling NFS & SMB..."
launchctl disable system/com.apple.nfsd || true
launchctl disable system/com.apple.nfsconf || true
launchctl disable system/com.apple.netbiosd || true
launchctl disable system/com.apple.smb.preferences || true
launchctl disable system/com.apple.NetworkSharing || true

echo "==> Disabling Family Controls / Screen Time..."
launchctl disable system/com.apple.familycontrols || true

echo "==> Disabling App Store daemon..."
launchctl disable system/com.apple.appstored || true

echo "==> Disabling Contacts sync..."
launchctl disable system/com.apple.contactsd || true

echo "==> Disabling Postfix (mail)..."
launchctl disable system/com.apple.postfix.master || true
launchctl disable system/com.apple.postfix.newaliases || true

echo "==> Disabling Beta Enrollment..."
launchctl disable system/com.apple.betaenrollmentd || true

echo "==> Disabling Audio..."
launchctl disable system/com.apple.audio.coreaudiod || true
launchctl disable system/com.apple.audiomxd || true
launchctl disable system/com.apple.audio.AudioComponentRegistrar || true
launchctl disable system/com.apple.audio.systemsoundserverd || true

echo "==> Disabling Camera & Media IO..."
launchctl disable system/com.apple.cmio.registerassistantservice || true
launchctl disable system/com.apple.attentionawarenessd || true

echo "==> Disabling Accessories..."
launchctl disable system/com.apple.accessoryupdaterd || true
launchctl disable system/com.apple.mediaremoted || true

echo "==> Disabling Siri Intelligence..."
launchctl disable system/com.apple.coreduetd || true
launchctl disable system/com.apple.contextstored || true
launchctl disable system/com.apple.biomed || true

echo "==> Disabling Push Notifications..."
launchctl disable system/com.apple.apsd || true

echo "==> Disabling Captive Portal..."
launchctl disable system/com.apple.captiveagent || true

echo "==> Disabling Software Update..."
launchctl disable system/com.apple.softwareupdated || true
launchctl disable system/com.apple.mobileassetd || true

echo "==> Disabling Accessibility..."
launchctl disable system/com.apple.universalaccessd || true

echo "==> Disabling Performance Metrics..."
launchctl disable system/com.apple.PerfPowerServices || true

echo "==> Disabling Duet Activity Scheduler..."
launchctl disable system/com.apple.dasd || true

echo "==> Disabling Mobile Activation..."
launchctl disable system/com.apple.mobileactivationd || true

echo "==> Setting privacy/telemetry defaults..."
defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false
defaults write com.apple.CrashReporter DialogType none
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
defaults write com.apple.commerce AutoUpdate -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true

echo ""
echo "==> Done!"
echo ""
echo "Next steps:"
echo "  1. Reboot into Recovery Mode"
echo "  2. Run: csrutil enable"
echo "  3. Reboot"
echo ""
echo "To re-enable any service: sudo launchctl enable system/<service-name>"
