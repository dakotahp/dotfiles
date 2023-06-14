# Sensible defaults for tweaking MacOS here and there.

echo "Setting some MacOS preferences…"

# Make key repeat speed much faster
defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

# Disable the press and hold functionality for diacritics characters
defaults write -g ApplePressAndHoldEnabled -bool false

echo "Done!"
