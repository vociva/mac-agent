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
launchctl disable system/com.apple.metadata.mds
launchctl disable system/com.apple.metadata.mds.index
launchctl disable system/com.apple.metadata.mds.scan
launchctl disable system/com.apple.metadata.mds.spindump
mdutil -a -i off

echo "==> Disabling Bluetooth..."
launchctl disable system/com.apple.bluetoothd
launchctl disable system/com.apple.BTServer.le
launchctl disable system/com.apple.BlueTool

echo "==> Disabling Find My..."
launchctl disable system/com.apple.findmymacd
launchctl disable system/com.apple.icloud.findmydeviced
launchctl disable system/com.apple.findmy.findmybeaconingd

echo "==> Disabling iCloud..."
launchctl disable system/com.apple.cloudd
launchctl disable system/com.apple.icloud.searchpartyd
launchctl disable system/com.apple.xartstorageremoted

echo "==> Disabling Analytics & Telemetry..."
launchctl disable system/com.apple.analyticsd
launchctl disable system/com.apple.ecosystemanalyticsd
launchctl disable system/com.apple.osanalytics.osanalyticshelper
launchctl disable system/com.apple.wifianalyticsd
launchctl disable system/com.apple.audioanalyticsd
launchctl disable system/com.apple.triald.system
launchctl disable system/com.apple.rtcreportingd
launchctl disable system/com.apple.SubmitDiagInfo
launchctl disable system/com.apple.ReportCrash.Root
launchctl disable system/com.apple.spindump
launchctl disable system/com.apple.sysdiagnose
launchctl disable system/com.apple.tailspind

echo "==> Disabling Location Services..."
launchctl disable system/com.apple.locationd

echo "==> Disabling Time Machine..."
launchctl disable system/com.apple.backupd
launchctl disable system/com.apple.backupd-helper

echo "==> Disabling AirPlay & Continuity..."
launchctl disable system/com.apple.AirPlayXPCHelper
launchctl disable system/com.apple.rapportd
launchctl disable system/com.apple.nearbyd
launchctl disable system/com.apple.sharingd

echo "==> Disabling Game Center..."
launchctl disable system/com.apple.GameController.gamecontrollerd
launchctl disable system/com.apple.gamepolicyd

echo "==> Disabling Music..."
launchctl disable system/com.apple.musicd

echo "==> Disabling NFC..."
launchctl disable system/com.apple.nfcd

echo "==> Disabling NFS & SMB..."
launchctl disable system/com.apple.nfsd
launchctl disable system/com.apple.nfsconf
launchctl disable system/com.apple.netbiosd
launchctl disable system/com.apple.smb.preferences
launchctl disable system/com.apple.NetworkSharing

echo "==> Disabling Family Controls / Screen Time..."
launchctl disable system/com.apple.familycontrols

echo "==> Disabling App Store daemon..."
launchctl disable system/com.apple.appstored

echo "==> Disabling Contacts sync..."
launchctl disable system/com.apple.contactsd

echo "==> Disabling Postfix (mail)..."
launchctl disable system/com.apple.postfix.master
launchctl disable system/com.apple.postfix.newaliases

echo "==> Disabling Beta Enrollment..."
launchctl disable system/com.apple.betaenrollmentd

echo "==> Disabling attention awareness (camera)..."
launchctl disable system/com.apple.attentionawarenessd

echo "==> Setting privacy/telemetry defaults..."
defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false
defaults write com.apple.CrashReporter DialogType none
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
defaults write com.apple.commerce AutoUpdate -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true

echo "==> Disabling Core Audio"
launchctl disable system/com.apple.audio.coreaudiod
launchctl disable system/com.apple.audiomxd
launchctl disable system/com.apple.audio.AudioComponentRegistrar
launchctl disable system/com.apple.audio.systemsoundserverd

echo ""
echo "==> Done!"
echo ""
echo "Next steps:"
echo "  1. Reboot into Recovery Mode"
echo "  2. Run: csrutil enable"
echo "  3. Reboot"
echo ""
echo "To re-enable any service: sudo launchctl enable system/<service-name>"
