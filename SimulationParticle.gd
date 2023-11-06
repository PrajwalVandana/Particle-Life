class_name SimulationParticle
extends Object


var type: int;
var position: Vector2;
var velocity: Vector2;


func dist_to(other: SimulationParticle) -> float:
	return position.distance_to(other.position)

func dir_to(other: SimulationParticle) -> Vector2:
	return (other.position - position).normalized()
