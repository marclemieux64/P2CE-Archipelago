// =============================================================
// ARCHIPELAGO PARSE MATH
// =============================================================

/**
 * ParseMath - Handles simple inline math like "320-65".
 */
float ParseMath(string val) {
    if (val.length() == 0) return 0.0f;
    uint m = val.locate("-", 1);
    if (m != uint(-1)) return val.substr(0, int(m)).toFloat() - val.substr(int(m + 1)).toFloat();
    uint p = val.locate("+", 1);
    if (p != uint(-1)) return val.substr(0, int(p)).toFloat() + val.substr(int(p + 1)).toFloat();
    return val.toFloat();
}
