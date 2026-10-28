-- git_grep_parser.parse_output over git grep's raw stdout, resolving each
-- file's language on first read: every completion request parses every hit,
-- but only a documentation draw reads the language
local GitGrepLazyParser = {}

-- One record per line: path, line, column and match, NUL-separated (--null)
local RECORD_PATTERN = "([^%z\n]*)%z(%d+)%z(%d+)%z([^\n]*)"

---@class blink-ripgrep.LazyGitgrepFile : blink-ripgrep.GitgrepFile
---@field filename string the path as git grep printed it, to resolve the language from

local file_mt = {
  ---@param file blink-ripgrep.LazyGitgrepFile
  ---@param key string
  __index = function(file, key)
    if key ~= "language" then
      return nil
    end

    local filename = file.filename
    local ft = vim.filetype.match({ filename = filename })
    local ext = vim.fn.fnamemodify(filename, ":e")
    local language = ft
      or vim.treesitter.language.get_lang(ext or "text")
      or ext
    rawset(file, "language", language)
    return language
  end,
}

---@param stdout string
---@param cwd string
---@return blink-ripgrep.GitgrepOutput
function GitGrepLazyParser.parse_output(stdout, cwd)
  ---@type blink-ripgrep.GitgrepOutput
  local output = { files = {} }

  for filename, line_number, column, text in stdout:gmatch(RECORD_PATTERN) do
    local relative_filename = filename
    if filename:sub(1, #cwd) == cwd then
      relative_filename = filename:sub(#cwd + 2)
    end

    local file = output.files[relative_filename]
    if not file then
      file = setmetatable({
        type = "gitgrep",
        filename = filename,
        matches = {},
        path = relative_filename,
      }, file_mt) --[[@as blink-ripgrep.LazyGitgrepFile]]
      output.files[relative_filename] = file
    end
    if not file.matches[text] then
      local start_col = assert(tonumber(column)) - 1
      file.matches[text] = {
        match = { text = text },
        start_col = start_col,
        end_col = start_col + #text,
        line_number = assert(tonumber(line_number)),
      }
    end
  end

  return output
end

return GitGrepLazyParser
