local M = {}

local ns = vim.api.nvim_create_namespace("smudge")

M.config = {
  char = "█",        -- smear character
  hl = "SmudgeCursor",
  max_age = 80,      -- ms before smear disappears
  length = 2,        -- how many cells behind cursor
}

local last_pos = nil

local function place_smear(buf, row, col)
  local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
    virt_text = {
      { M.config.char, M.config.hl },
    },
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })

  vim.defer_fn(function()
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, id)
  end, M.config.max_age)
end

local function on_move()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]

  if not last_pos then
    last_pos = { row, col }
    return
  end

  local lr, lc = last_pos[1], last_pos[2]

  -- Only smear if cursor actually moved
  if row ~= lr or col ~= lc then
    -- Horizontal smear
    local dx = col - lc
    if row == lr and dx ~= 0 then
      local step = dx > 0 and -1 or 1
      for i = 1, M.config.length do
        place_smear(buf, row, col + step * i)
      end
    end

    -- Vertical smear (simpler)
    if col == lc and row ~= lr then
      place_smear(buf, lr, lc)
    end
  end

  last_pos = { row, col }
end

function M.enable()
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = vim.api.nvim_create_augroup("Smudge", { clear = true }),
    callback = on_move,
  })
end

function M.disable()
  vim.api.nvim_del_augroup_by_name("Smudge")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  M.enable()
end

return M
