void RemovePotatOS() { DeleteEntity("sphere_entrance_lift_relay", false); }

void Fire(string cmd, float d = 0.0f) { 
    CBaseEntity@ c = EntityList().FindByName(null, "ap_init_cmd");
    if (c !is null) { Variant v; v.SetString(cmd); c.FireInput("Command", v, d, null, null, 0); }
}

void RemovePotatosFromGun() {
    Fire("ent_fire !player set_potatos_skin 0");
    Fire("ent_fire weapon_portalgun AddOutput \"showingpotatos 0\"", 0.05f);
    Fire("snd_setmixer potatosVO vol 0.0", 0.1f);
    CallVScript("MutePotatOSSubtitles(true)");
}

void RestorePotatosToGun() {
    Fire("upgrade_potatogun");
    Fire("snd_setmixer potatosVO vol 1.0", 0.1f);
    CallVScript("MutePotatOSSubtitles(false)");
}
