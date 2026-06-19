namespace Archipelago {

float DegToRad(float degrees) {
    return degrees * (3.14159f / 180.0f);
}

Vector AnglesToForward(QAngle angles) {
    Vector forward;
    AngleVectors(angles, forward);
    return forward;
}

Vector AnglesToRight(QAngle angles) {
    Vector forward, right, up;
    AngleVectors(angles, forward, right, up);
    return right;
}

Vector AnglesToUp(QAngle angles) {
    Vector forward, right, up;
    AngleVectors(angles, forward, right, up);
    return up;
}

} // namespace Archipelago
