

function MutePotatOSSubtitles(mute) {
    if (mute) {
        SendToPanorama("MutePotatos", "1");
        // CORRECTION : On utilise le + pour ne faire qu'une seule phrase
        printl("MutePotatos: 1"); 
    } else {
        SendToPanorama("MutePotatos", "0");
        // CORRECTION : On utilise le + pour ne faire qu'une seule phrase
        printl("MutePotatos: 0"); 
    }
}