extends Tween
class_name ExTween

enum TransitionType {LINEAR, SINE, QUINT, QUART, QUAD, EXPO, ELASTIC, CUBIC, CIRC, BOUNCE, BACK}
enum EaseType {IN, OUT, IN_OUT, OUT_IN}

export(TransitionType) var ExTransition: int
export(EaseType) var ExEase: int
