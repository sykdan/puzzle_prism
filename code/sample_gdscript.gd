extends Node # Kod pripojitelny k uzlu musi dedit tridu Node (nebo tridu, ktera ma Node nekde ve sve objektove hierarchii)

# Deklarace funkce
func ahoj_svete():
    print("Ahoj, svete!")

# Funkce zacinajici podtrzitkem jsou virtualni (lze je nahradit)
# _ready() je automaticky spusteno po zavedeni uzlu (a dcerinnych uzlu) do stromu.
func _ready():
    ahoj_svete():

# _process() je automaticky spusteno pri vykresleni snimku
# Parametr delta je cas, ktery uplynul od posledniho snimku (prevracena hodnota FPS)
func _process(delta: float):
    pass # Telo funkce lze vynechat klicovym slovem pass