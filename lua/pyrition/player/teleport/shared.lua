--locals
local teleport_history = PYRITION.PlayerTeleportHistory or {}
local teleport_history_length = 7
local teleport_history_length_bits = PYRITION._Bits(teleport_history_length + 1)

--globals
PYRITION.PlayerTeleportHistory = teleport_history
PYRITION.PlayerTeleportHistoryLength = teleport_history_length
PYRITION.PlayerTeleportHistoryLengthBits = teleport_history_length_bits