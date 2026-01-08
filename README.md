# smudge.nvim

https://github.com/StikyPiston/smudge.nvim/raw/refs/heads/main/assets/demo.mp4

**smudge.nvim** is a performant cursor animation plugin for Neovim!

## Installation (lazy.nvim)

```lua
{
    "stikypiston/smudge.nvim",
    opts = {
        -- These are the default options. Leave the table blank (as in opts = {}) for this config, or customise it yourself!
        char = "░",        -- smear character
        hl = "SmudgeCursor",
        max_age = 80,      -- ms before smear disappears
        length = 2,        -- max trail length
    }
}
```
