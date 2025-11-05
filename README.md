# print-debug.nvim

Simple plugin that makes it easy to print debug statements without typing so much. When invoked (default `<leader>dp`) an input window opens. In a python file, typing `test_list` into that window results in a new line directly below the current line reading

```python
    print(f"test_list = {test_list}")
```

In the case of an index variable it will be printed verbatim unless a `mark` is added in front of it. By default the `mark` is `"`. This is, typing `test_list[i]` results in

```python
    print(f"test_list[i] = {test_list[i]}")
```

But typing `test_list["i]` results in

```python
    print(f"test_list[{i}] = {test_list[i]}")
```

The plugin is language sensitive. For example, in c++ typing `test_array["i]` results in

```cpp
  std::cout << "test_array[" << i << "] = " << test_array[i] << std::endl;
```

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your package manager:

```lua
  {
    'AndresYague/print-debug.nvim',
    opts = {
      mark = '"',
      keymap_above = '<leader>dP',
      keymap_below = '<leader>dp',
    },
  }
```

## Configuration

The `mark` and the `keymap` are the two configurable options right now. These must be in a table passed to `setup`. Such as:

```lua
    require('print-debug').setup { mark = '"', keymap_above = '<leader>dP', keymap_below = '<leader>dp' }
```

## Currently supported languages

    cpp
    lua
    python

## Known issues

*Autopairs* style plugins may interact negatively with this plugin, so it may be better to disable them when actively using the plugin. Currently, `nvim-autopairs` is compatible with this plugin so long as it is *not* lazy loaded.
