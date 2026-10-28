local git_grep_parser =
  require("blink-ripgrep.backends.git_grep.git_grep_parser")
local git_grep_lazy_parser =
  require("blink-ripgrep.backends.git_grep.git_grep_lazy_parser")
local assert = require("luassert")

local cwd = "/home/user/project"

-- One line of `git grep --null` output
---@param path string
---@param line_number number
---@param column number
---@param text string
local function record(path, line_number, column, text)
  return table.concat({ path, line_number, column, text }, "\0")
end

local stdout = table.concat({
  record("other-file.lua", 3, 14, "Hippopotamus234"),
  record("other-file.lua", 5, 1, "Hippopotamus234"),
  record("other-file.lua", 7, 2, "hippo_dino"),
  record("docs/README.md", 1, 1, "hippo"),
  record("Makefile", 2, 5, "hippo-target"),
  record("LICENSE", 1, 9, "hippocratic"),
  record(cwd .. "/src/absolute.ts", 10, 3, "hippoLike"),
  "",
}, "\n")

---@param tbl table
local function sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl)
  table.sort(keys)
  return keys
end

describe("git_grep_lazy_parser", function()
  it("parses the same output as git_grep_parser", function()
    local expected = git_grep_parser.parse_output(vim.split(stdout, "\n"), cwd)
    local actual = git_grep_lazy_parser.parse_output(stdout, cwd)

    assert.same(sorted_keys(expected.files), sorted_keys(actual.files))
    for path, expected_file in pairs(expected.files) do
      -- every field git_grep_parser sets, so a field added upstream fails here
      for key, value in pairs(expected_file) do
        assert.same(value, actual.files[path][key], path .. "." .. key)
      end
    end
  end)

  it("resolves a file's language on first read", function()
    local file =
      git_grep_lazy_parser.parse_output(stdout, cwd).files["other-file.lua"]

    assert.is_nil(rawget(file, "language"))
    assert.equal("lua", file.language)
    assert.equal("lua", rawget(file, "language"))
  end)
end)
