extends Node

# Player Signals
signal player_died(body)
signal player_entered_pit(body)
signal player_exited_pit(body)
signal player_entered_pit_danger_area(body)
signal player_exited_pit_danger_area(body)
signal player_entered_ring(body)
signal player_exited_ring(body)

# Enemy Signals
signal enemy_created(object)
signal enemy_died(object)

# Map Signals
signal tilemap_regenerate
signal tilemap_complete
signal minimap_object_created
signal minimap_object_removed
