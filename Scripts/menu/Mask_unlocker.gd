extends RichTextLabel

func _ready() -> void:
    var mask_list = save_manager.getUnlocked()
    for mask_name in mask_list:
        if not mask_list[mask_name]:
            mask_list[mask_name] = true
            text = "You have unlocked a " + mask_name + " mask!"
            return
    text = "You have unlocked all masks, thx for playing ;))"