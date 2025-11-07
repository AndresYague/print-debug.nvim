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

  return 'print(f"' .. p_mark .. " = {" .. unmark .. '}")<ESC>'
end

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@param unmark string String without the mark present
---@return string new_input
local new_input_cpp = function(input, mark, unmark)
  -- Find where the mark is and print the word after it
  local p_mark = surround_mark(input, mark, '" << ', ' << "')

  return 'std::cout << "'
    .. p_mark
    .. ' = " << '
    .. unmark
    .. " << std::endl;<ESC>"
end

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@param unmark string String without the mark present
---@return string new_input
local new_input_lua = function(input, mark, unmark)
  -- Find where the mark is and print the word after it
  local p_mark = surround_mark(input, mark, '" .. ', ' .. "')

  return 'print("' .. p_mark .. ' = " .. ' .. unmark .. ")<ESC>"
end

---Debug print for python code, uses a mark to indicate where to
---print a variable (such as an index)
---@param mark string String that marks what has to be outputed as variable
---@param above? boolean Default false. Put line above current (otherwise it will be below)
---@param new_input_func function new_input_func(input: string, mark: string, unmark: string): string
local print_debug = function(mark, new_input_func, above)
  above = above or false
  vim.ui.input({ prompt = "What to print" }, function(input)
    -- If empty input, do nothing
    if not input then
      return nil
    end

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
    if above then
      new_input = "O" .. new_input
    else
      new_input = "o" .. new_input
    end

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
---@param new_input_func function new_input_func(input: string, mark: string, unmark: string): string
---@param callable function callable(mark: string, new_input_func: function, above: boolean)
---@param opts table Table with options for function
local map = function(pattern, new_input_func, callable, opts)
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = "print-debug-augroup",
    pattern = pattern,
    callback = function()
      vim.keymap.set("n", opts.keymap_below, function()
        callable(opts.mark, new_input_func, false)
      end, { silent = true, desc = "Debug: Print Variable Below" })
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = "print-debug-augroup",
    pattern = pattern,
    callback = function()
      vim.keymap.set("n", opts.keymap_above, function()
        callable(opts.mark, new_input_func, true)
      end, { silent = true, desc = "Debug: Print Variable Above" })
    end,
  })
end

---@param opts table?
M.setup = function(opts)
  opts = opts or {}
  opts.mark = opts.mark or '"'
  opts.keymap_above = opts.keymap_above or "<leader>dP"
  opts.keymap_below = opts.keymap_below or "<leader>dp"

  map({ "*.py" }, new_input_py, print_debug, opts)
  map({ "*.lua" }, new_input_lua, print_debug, opts)
  map({ "*.cpp", "*.cc", "*.hh" }, new_input_cpp, print_debug, opts)
end

return M
