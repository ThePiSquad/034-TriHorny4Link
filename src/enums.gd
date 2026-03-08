class_name Enums
extends Resource

enum Direction {
	NORTH,
	SOUTH,
	WEST,
	EAST,
}

enum ColorType {
	WHITE,  # non-active
	BLACK,  # overloaded
	RED,
	BLUE,
	YELLOW,
	GREEN,
	ORANGE,
	PURPLE,
}

enum BulletAttributes {
	KINETIC,
	MAGIC,
}

enum ShapeType {
	CIRCLE,
	TRIANGLE,
	RECTANGLE,
}

enum StructureType {
	TURRET,
	MONO_CRYSTAL,
	CRYSTAL,
	CONDUIT,
}

enum ComponentState {
	ACTIVE,
	INACTIVE,
	OVERLOADED,
}

enum EnemyType {
	RECTANGLE,
	TRIANGLE,
	CIRCLE,
}
