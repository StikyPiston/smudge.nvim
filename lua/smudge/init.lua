---@class Smudge
---@field last_pos? { [1]: integer, [2]: integer }
---@field augroup? integer
---@field opts? SmudgeOpts
local M = {}

local ns = vim.api.nvim_create_namespace("smudge")

--Default options (lazy.nvim style)
---@class SmudgeOpts
---@field char? string smear character
---@field hl? string
---@field max_age? integer ms before smear disappears
---@field length? integer max trail length
local defaults = {
	char = "░",
	hl = "SmudgeCursor",
	max_age = 80,
	length = 2,
}

---@param buf integer Buffer ID
---@param row integer Selected row
---@param col integer Selected column
local function place_smear(buf, row, col)
	-- Validate row
	if row < 0 or row >= vim.api.nvim_buf_line_count(buf) then
		return
	end

	-- Validate column against line length
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
	if not line then
		return
	end

	local max_col = line:len()
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

	if not M.last_pos then
		M.last_pos = { row, col }
		return
	end

	local lr, lc = M.last_pos[1], M.last_pos[2]

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

	M.last_pos = { row, col }
end

function M.enable()
	if M.augroup then
		return
	end

	M.augroup = vim.api.nvim_create_augroup("Smudge", { clear = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = M.augroup,
		callback = on_move,
	})
end

function M.disable()
	if M.augroup then
		pcall(vim.api.nvim_del_augroup_by_id, M.augroup)
		M.augroup = nil
	end

	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	M.last_pos = nil
end

---@param opts? SmudgeOpts
function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
	M.enable()
end

return M
-- vim: set ts=4 sts=4 sw=0 noet ai si sta:
