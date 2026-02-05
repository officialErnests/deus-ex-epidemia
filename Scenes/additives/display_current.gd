extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if modifiers.getCurentMask()=="whale":
		$LitCandle4.visible=true
	if modifiers.getCurentMask()=="dragon":
		$LitCandle3.visible=false
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$LitCandle.visible=Game.global_card.variable["Candles"]>0
	$LitCandle2.visible=Game.global_card.variable["Candles"]>1
	$LitCandle3.visible=Game.global_card.variable["Candles"]>2
	$LitCandle4.visible=Game.global_card.variable["Candles"]>3
