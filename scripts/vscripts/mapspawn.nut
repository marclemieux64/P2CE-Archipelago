
::MutePotatOSSubtitles <- function(mute) {
    ::ap_potatos_muted = mute;
    ::SafeSendToConsole("ap_potatos_muted " + (mute ? "1" : "0"));
    if (::ap_player_connected) {
        SendToPanorama("ArchipelagoMutePotatos", mute ? "1" : "0");
    }
}

