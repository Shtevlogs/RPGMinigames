class_name GameBootstrap
extends Node2D

# Bootstrap scene - redirects to main menu
func _ready() -> void:
    SceneManager.go_to_main_menu()
