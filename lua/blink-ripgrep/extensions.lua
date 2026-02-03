local extensions = {}

local ns_id = vim.api.nvim_create_namespace("blink-ripgrep-extensions")
local divider_ns_id = vim.api.nvim_create_namespace("blink-ripgrep-divider")

---Gets styled file path text with icon (without applying highlights)
---@param file_path string The full file path to style
---@return string styled_text The formatted text with icon
function extensions.get_styled_file_path(file_path)
  local dir_path, file_name = file_path:match("^(.*/)(.*)")

  -- Handle files with no directory
  if not dir_path then
    dir_path = ""
    file_name = file_path
  end

  -- Get icon from mini.icons
  local icon = " "
  local has_mini_icons, mini_icons = pcall(require, "mini.icons")
  if has_mini_icons then
    local icon_val = mini_icons.get("file", file_name)
    icon = icon_val .. " "
  end

  return icon .. file_path
end

---Applies a divider line with proper highlighting that spans full window width
---@param bufnr number The buffer number
---@param line_num number The line number (0-indexed) where the divider appears
function extensions.apply_divider(bufnr, line_num)
  -- Clear previous divider extmarks
  vim.api.nvim_buf_clear_namespace(bufnr, divider_ns_id, line_num, line_num + 1)

  -- Use a very long divider string that will be trimmed by the window width
  -- This ensures it always spans the full width regardless of window size
  local divider_text = string.rep("─", 200)

  -- Apply divider as virtual text that replaces the line
  -- The window will automatically trim it to fit
  vim.api.nvim_buf_set_extmark(bufnr, divider_ns_id, line_num, 0, {
    virt_text = { { divider_text, "LineNr" } },
    virt_text_pos = "overlay",
    priority = 100,
  })
end

---Applies highlights to an already-written file path line
---@param file_path string The original file path (without icon)
---@param bufnr number The buffer number to apply highlights to
---@param line_num number The line number (0-indexed) where the path appears
---@param left_padding number|nil Number of cells padding on the left (default 0)
function extensions.apply_file_path_highlights(
  file_path,
  bufnr,
  line_num,
  left_padding
)
  left_padding = left_padding or 0
  local dir_path, file_name = file_path:match("^(.*/)(.*)")

  if not dir_path then
    dir_path = ""
    file_name = file_path
  end

  local icon = " "
  local icon_hl = ""
  local has_mini_icons, mini_icons = pcall(require, "mini.icons")
  if has_mini_icons then
    icon, icon_hl = mini_icons.get("file", file_name)
    icon = icon .. " "
  end

  local icon_byte_len = #icon
  local dir_byte_len = #dir_path
  local styled_text = icon .. file_path

  local buffer_lines =
    vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)
  local actual_line = buffer_lines[1] or ""

  if #actual_line == 0 then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_num, line_num + 1)

  if icon_hl ~= "" then
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, left_padding, {
      end_col = left_padding + icon_byte_len,
      hl_group = icon_hl,
      priority = 200,
    })
  end

  if dir_byte_len > 0 then
    vim.api.nvim_buf_set_extmark(
      bufnr,
      ns_id,
      line_num,
      left_padding + icon_byte_len,
      {
        end_col = left_padding + icon_byte_len + dir_byte_len,
        hl_group = "SnacksPickerDir",
        priority = 200,
      }
    )
  end

  vim.api.nvim_buf_set_extmark(
    bufnr,
    ns_id,
    line_num,
    left_padding + icon_byte_len + dir_byte_len,
    {
      end_line = line_num,
      end_col = left_padding + #styled_text,
      hl_group = "SnacksPickerFile",
      priority = 200,
    }
  )
end

return extensions
