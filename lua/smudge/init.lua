local M = {}

local ns = vim.api.nvim_create_namespace("smudge")

-- Default options (lazy.nvim style)
local defaults = {
	char = "░", -- smear character
	hl = "SmudgeCursor",
	max_age = 80, -- ms before smear disappears
	length = 2, -- max trail length
}

M.opts = {}
local last_pos = nil
local augroup = nil

local function place_smear(buf, row, col)
	-- Validate row
	local line_count = vim.api.nvim_buf_line_count(buf)
	if row < 0 or row >= line_count then
		return
	end

	-- Validate column against line length
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
	if not line then
		return
	end

	local max_col = #line
	if max_col == 0 then
		return
	end

	if col < 0 then
		col = 0
	elseif col > max_col - 1 then
		col = max_col - 1
	end

	local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
		virt_text = {
			{ M.opts.char, M.opts.hl },
		},
		virt_text_pos = "overlay",
		hl_mode = "blend",
	})

	vim.defer_fn(function()
		pcall(vim.api.nvim_buf_del_extmark, buf, ns, id)
	end, M.opts.max_age)
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
			local count = math.min(M.opts.length, adx)

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
			local count = math.min(M.opts.length, ady)

			for i = 1, count do
				place_smear(buf, row + step * i, col)
			end
		end
	end

	last_pos = { row, col }
end

local function enable()
	if augroup then
		return
	end

	augroup = vim.api.nvim_create_augroup("Smudge", { clear = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		callback = on_move,
	})
end

local function disable()
	if augroup then
		pcall(vim.api.nvim_del_augroup_by_id, augroup)
		augroup = nil
	end

	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	last_pos = nil
end

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
	enable()
end

M.enable = enable
M.disable = disable

return M
