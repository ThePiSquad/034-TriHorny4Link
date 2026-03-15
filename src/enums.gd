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
	GREEN_BLUE,
	GREEN_YELLOW,
	ORANGE_RED,
	ORANGE_YELLOW,
	PURPLE_RED,
	PURPLE_BLUE,
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
