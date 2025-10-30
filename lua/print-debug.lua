local M = {}

--- Find where the mark is and print the word after it
---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@param left string String to suround the marked word on the left
---@param right string String to suround the marked word on the right
---@return string
local surround_mark = function(input, mark, left, right)
  -- This takes the first value out of gsub
  local subbed = string.gsub(input, mark .. "([%w%.:]+)", left .. "%1" .. right)
  return subbed
end

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@param unmark string String without the mark present
---@return string new_input
local new_input_py = function(input, mark, unmark)
  -- Find where the mark is and print the word after it
  local p_mark = surround_mark(input, mark, "{", "}")

  return 'oprint(f"' .. p_mark .. " = {" .. unmark .. '}")<ESC>'
end

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@param unmark string String without the mark present
---@return string new_input
local new_input_cpp = function(input, mark, unmark)
  -- Find where the mark is and print the word after it
  local p_mark = surround_mark(input, mark, '" << ', ' << "')

  return 'ostd::cout << "'
    .. p_mark
    .. ' = " << '
    .. unmark
    .. " << std::endl;<ESC>"
end

---Debug print for python code, uses a mark to indicate where to
---print a variable (such as an index)
---@param mark string String that marks what has to be outputed as variable
---@param new_input_func function new_input_func(input: string, mark: string, unmark: string): string
local print_debug = function(mark, new_input_func)
  vim.ui.input({ prompt = "What to print" }, function(input)
    -- Deactivate autopairs if loaded
    local enabled_autopairs = false
    if package.loaded["nvim-autopairs"] then
      if not require("nvim-autopairs").state.disabled then
        enabled_autopairs = true
        require("nvim-autopairs").disable()
      end
    end

    -- First, remove the mark character from the "real" input
    local unmark = string.gsub(input, mark, "")

    -- Manipulate input for debug print
    local new_input = new_input_func(input, mark, unmark)

    -- Replace the special characters
    new_input = vim.api.nvim_replace_termcodes(new_input, true, true, true)

    -- Actually carry out the commands
    vim.api.nvim_feedkeys(new_input, "tx", false)

    if enabled_autopairs then
      require("nvim-autopairs").enable()
    end
  end)
end

-- Group for the autocmd
vim.api.nvim_create_augroup("print-debug-augroup", { clear = true })

---@param pattern table Table of string patterns indicating which extension it affects
---@param callable function callable(mark: string, new_input_func: function)
---@param new_input_func function new_input_func(input: string, mark: string, unmark: string): string
---@param mark string String that marks what has to be outputed as variable
---@param keymap string What keymap to use for the debug print
local map = function(pattern, callable, new_input_func, mark, keymap)
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = "print-debug-augroup",
    pattern = pattern,
    callback = function()
      vim.keymap.set("n", keymap, function()
        callable(mark, new_input_func)
      end, { silent = true, desc = "Debug: Print Variable" })
    end,
  })
end

---@param opts table?
M.setup = function(opts)
  opts = opts or {}
  opts.mark = opts.mark or '"'
  opts.keymap = opts.keymap or "<leader>dp"

  map({ "*.py" }, print_debug, new_input_py, opts.mark, opts.keymap)
  map({ "*.cpp", "*.hh" }, print_debug, new_input_cpp, opts.mark, opts.keymap)
end

return M
