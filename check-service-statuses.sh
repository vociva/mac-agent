#!/bin/bash
# Check which services from our disable list are still running

SERVICES=(
    "com.apple.metadata.mds"
    "com.apple.metadata.mds.index"
    "com.apple.metadata.mds.scan"
    "com.apple.bluetoothd"
    "com.apple.BTServer.le"
    "com.apple.BlueTool"
    "com.apple.findmymacd"
    "com.apple.icloud.findmydeviced"
    "com.apple.findmy.findmybeaconingd"
    "com.apple.cloudd"
    "com.apple.icloud.searchpartyd"
    "com.apple.xartstorageremoted"
    "com.apple.analyticsd"
    "com.apple.ecosystemanalyticsd"
    "com.apple.osanalytics.osanalyticshelper"
    "com.apple.wifianalyticsd"
    "com.apple.audioanalyticsd"
    "com.apple.triald.system"
    "com.apple.rtcreportingd"
    "com.apple.SubmitDiagInfo"
    "com.apple.ReportCrash.Root"
    "com.apple.spindump"
    "com.apple.sysdiagnose"
    "com.apple.tailspind"
    "com.apple.symptomsd-diag"
    "com.apple.eligibilityd"
    "com.apple.locationd"
    "com.apple.backupd"
    "com.apple.backupd-helper"
    "com.apple.AirPlayXPCHelper"
    "com.apple.rapportd"
    "com.apple.nearbyd"
    "com.apple.sharingd"
    "com.apple.wifip2pd"
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
    "com.apple.audio.coreaudiod"
    "com.apple.audiomxd"
    "com.apple.audio.AudioComponentRegistrar"
    "com.apple.audio.systemsoundserverd"
    "com.apple.cmio.registerassistantservice"
    "com.apple.attentionawarenessd"
    "com.apple.accessoryupdaterd"
    "com.apple.mediaremoted"
    "com.apple.coreduetd"
    "com.apple.contextstored"
    "com.apple.biomed"
    "com.apple.apsd"
    "com.apple.captiveagent"
    "com.apple.softwareupdated"
    "com.apple.mobileassetd"
    "com.apple.universalaccessd"
    "com.apple.PerfPowerServices"
    "com.apple.dasd"
    "com.apple.mobileactivationd"
)

echo "Checking service status..."
echo ""

RUNNING=0
STOPPED=0
for service in "${SERVICES[@]}"; do
    pid=$(sudo launchctl list 2>/dev/null | grep "$service" | awk '{print $1}')
    if [ ! -z "$pid" ] && [ "$pid" != "-" ]; then
        echo "RUNNING: $service (pid $pid)"
        RUNNING=$((RUNNING + 1))
    else
        STOPPED=$((STOPPED + 1))
    fi
done

echo ""
echo "Results: $STOPPED disabled, $RUNNING still running"

if [ $RUNNING -eq 0 ]; then
    echo "All services disabled successfully!"
else
    echo "Reboot may be needed to fully apply changes."
fi
