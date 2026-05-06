// =============================================================
// ARCHIPELAGO EXTRACT FLOATS
// =============================================================

/**
 * ExtractFloats - Snatches all float-like values from a string.
 */
array<float> ExtractFloats(string raw) {
    string clean = raw.replace("Vector", " ").replace("QAngle", " ").replace("(", " ").replace(")", " ").replace(",", " ").replace("\x22", " ");
    array<string>@ parts = clean.split(" ");
    array<float> results;
    for (uint i = 0; i < parts.length(); i++) {
        string t = parts[i].trim();
        if (t.length() > 0) results.insertLast(ParseMath(t));
    }
    return results;
}
