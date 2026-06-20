// =============================================================
// MATH UTILITY FUNCTIONS
// =============================================================

namespace Archipelago {

/**
 * Converts degrees to radians.
 */
float DegToRad(float degrees) {
    return degrees * (3.14159f / 180.0f);
}

/**
 * Computes the forward directional vector for the given angles.
 */
Vector AnglesToForward(QAngle angles) {
    Vector forward;
    AngleVectors(angles, forward);
    return forward;
}

/**
 * Computes the right directional vector for the given angles.
 */
Vector AnglesToRight(QAngle angles) {
    Vector forward, right, up;
    AngleVectors(angles, forward, right, up);
    return right;
}

/**
 * Computes the up directional vector for the given angles.
 */
Vector AnglesToUp(QAngle angles) {
    Vector forward, right, up;
    AngleVectors(angles, forward, right, up);
    return up;
}

} // namespace Archipelago
