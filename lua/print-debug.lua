local M = {}

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@return string new_input
local new_input_py = function(input, mark)
  -- First, remove the pipe character from the "real" input
  local unmark = string.gsub(input, mark, "")

  -- Find where the mark is and print the word after it
  local p_mark = string.gsub(input, mark .. "(%w+)", "{%1}")

  return 'oprint(f"' .. p_mark .. " = {" .. unmark .. '}")<ESC>'
end

---@param input string String to "debug print"
---@param mark string String that marks what has to be outputed as variable
---@return string new_input
local new_input_cpp = function(input, mark)
  -- First, remove the pipe character from the "real" input
  local unmark = string.gsub(input, mark, "")

  -- Find where the mark is and print the word after it
  local p_mark = string.gsub(input, mark .. "(%w+)", '" << %1 << "')

  return 'ostd::cout << "'
    .. p_mark
    .. ' = " << '
    .. unmark
    .. " << std::endl;<ESC>"
end

---Debug print for python code, uses a mark to indicate where to
---print a variable (such as an index)
---@param mark string String that marks what has to be outputed as variable
---@param new_input_func function new_input_func(input: string, mark: string): string
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

    -- Manipulate input for debug print
    local new_input = new_input_func(input, mark)

    -- Replace the special characters
    new_input = vim.api.nvim_replace_termcodes(new_input, true, true, true)

    -- Actually carry out the commands
    vim.api.nvim_feedkeys(new_input, "tx", false)

    if enabled_autopairs then
      require("nvim-autopairs").enable()
    end
  end)
end

---@param pattern string Pattern indicating which FileType it affects
---@param callable function callable(mark: string, new_input_func: function)
---@param new_input_func function new_input_func(input: string, mark: string): string
---@param mark string String that marks what has to be outputed as variable
---@param keymap string What keymap to use for the debug print
local map = function(pattern, callable, new_input_func, mark, keymap)
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { pattern },
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
  opts.keymap = opts.keymap or '<leader>dp'

  map("python", print_debug, new_input_py, opts.mark, opts.keymap)
  map("cpp", print_debug, new_input_cpp, opts.mark, opts.keymap)
end

return M
