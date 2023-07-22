local derma_default_font = system.IsOSX() and "Helvetica" or "Tahoma"

PYRITION:FontRegister("PyritionDermaHuge", {extended = true, font = derma_default_font, size = 42})
PYRITION:FontRegister("PyritionDermaLarge", {extended = true, font = derma_default_font, size = 36})
PYRITION:FontRegister("PyritionDermaMedium", {extended = true, font = derma_default_font, size = 20})
PYRITION:FontRegister("PyritionDermaSmall", {extended = true, font = derma_default_font, size = 16})
PYRITION:FontRegister("PyritionDermaTiny", {extended = true, font = derma_default_font, size = 12})