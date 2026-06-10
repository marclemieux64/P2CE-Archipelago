namespace Archipelago {

void SafeAddOutput(CBaseEntity@ ent, string output, string target, string input, string param = "", float delay = 0.0f, int maxTimes = -1) {
        if (ent is null) return;
        
        // Format: "target:input:parameter:delay:maxTimes"
        Variant v;
        v.SetString(output + " " + target + ":" + input + ":" + param + ":" + delay + ":" + maxTimes);
        ent.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }

} // namespace Archipelago
