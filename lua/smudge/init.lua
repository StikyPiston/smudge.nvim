local M = {}

local ns = vim.api.nvim_create_namespace("smudge")

M.config = {
  char = "░",        -- smear character
  hl = "SmudgeCursor",
  max_age = 80,      -- ms before smear disappears
  length = 2,        -- max trail length
}

local last_pos = nil

local function place_smear(buf, row, col)
  -- Guard against invalid positions
  if row < 0 or col < 0 then
    return
  end

  local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
    virt_text = {
      { M.config.char, M.config.hl },
    },
    virt_text_pos = "overlay",
    hl_mode = "blend",
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

  -- Horizontal movement
  if row == lr then
    local dx = col - lc
    local adx = math.abs(dx)

    if adx > 0 then
      local step = dx > 0 and -1 or 1
      local count = math.min(M.config.length, adx)

      for i = 1, count do
        place_smear(buf, row, col + step * i)
      end
    end
  end

  -- Vertical movement
  if col == lc then
    local dy = row - lr
    local ady = math.abs(dy)

    if ady > 0 then
      local step = dy > 0 and -1 or 1
      local count = math.min(M.config.length, ady)

      for i = 1, count do
        place_smear(buf, row + step * i, col)
      end
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
  pcall(vim.api.nvim_del_augroup_by_name, "Smudge")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  last_pos = nil
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  M.enable()
end

return M
