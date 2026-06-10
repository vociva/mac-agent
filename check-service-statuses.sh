#!/bin/bash
# Check which services from our disable list are still running

SERVICES=(
    "com.apple.metadata.mds"
    "com.apple.metadata.mds.index"
    "com.apple.metadata.mds.scan"
    "com.apple.bluetoothd"
    "com.apple.findmymacd"
    "com.apple.icloud.findmydeviced"
    "com.apple.findmy.findmybeaconingd"
    "com.apple.cloudd"
    "com.apple.icloud.searchpartyd"
    "com.apple.analyticsd"
    "com.apple.ecosystemanalyticsd"
    "com.apple.osanalytics.osanalyticshelper"
    "com.apple.wifianalyticsd"
    "com.apple.audioanalyticsd"
    "com.apple.triald.system"
    "com.apple.rtcreportingd"
    "com.apple.locationd"
    "com.apple.backupd"
    "com.apple.backupd-helper"
    "com.apple.AirPlayXPCHelper"
    "com.apple.rapportd"
    "com.apple.nearbyd"
    "com.apple.sharingd"
    "com.apple.GameController.gamecontrollerd"
    "com.apple.gamepolicyd"
    "com.apple.musicd"
    "com.apple.nfcd"
    "com.apple.nfsd"
    "com.apple.netbiosd"
    "com.apple.NetworkSharing"
    "com.apple.familycontrols"
    "com.apple.appstored"
    "com.apple.contactsd"
    "com.apple.postfix.master"
    "com.apple.betaenrollmentd"
    "com.apple.attentionawarenessd"
    "com.apple.spindump"
    "com.apple.SubmitDiagInfo"
    "com.apple.ReportCrash.Root"
)

echo "Checking service status..."
echo ""

RUNNING=0
for service in "${SERVICES[@]}"; do
    pid=$(sudo launchctl list | grep "$service" | awk '{print $1}')
    if [ ! -z "$pid" ] && [ "$pid" != "-" ]; then
        echo "RUNNING: $service (pid $pid)"
        RUNNING=$((RUNNING + 1))
    fi
done

if [ $RUNNING -eq 0 ]; then
    echo "All services disabled successfully!"
else
    echo ""
    echo "$RUNNING service(s) still running — reboot may be needed"
fi
