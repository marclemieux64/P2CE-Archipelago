// =============================================================
// ARCHIPELAGO SPLIT STRING
// =============================================================

/**
 * SplitString - Simple helper to split a string by a delimiter into an array.
 */
void SplitString(const string&in input, const string&in delimiter, array<string>& outArray) {
    outArray.resize(0);
    if (input.length() == 0) return;

    int start = 0;
    int delimLen = delimiter.length();
    
    for (int i = 0; i <= int(input.length() - delimLen); i++) {
        if (input.substr(i, delimLen) == delimiter) {
            string sub = input.substr(start, i - start);
            outArray.insertLast(sub);
            start = i + delimLen;
            i = start - 1;
        }
    }
    
    outArray.insertLast(input.substr(start));
}
