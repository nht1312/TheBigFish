class_name App
extends RefCounted
## Static access to the "Game" autoload. Scripts use App.ctx() instead of the Game
## identifier so they also compile in headless tool/test runs (-s), where autoload
## names are not registered as globals.


static func game() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Game")


static func ctx() -> GameContext:
	return game().ctx


static func data() -> DataRegistry:
	return game().data


static func config() -> Dictionary:
	return game().config
