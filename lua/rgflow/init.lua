local utils = require("rgflow.utils")
local ui = require("rgflow.ui")
local quickfix = require("rgflow.quickfix")
local search = require("rgflow.search")
local get_state = require("rgflow.state").get_state

local M = {}

-- Exposed API
M.setup = require("rgflow.settingslib").setup

-- open UI - Pass in args: pattern, flags, path
-- Unsupplied args will default to:
--  pattern = blank
--  flags = previously used
--  path = PWD
-- e.g. require('rgflow').open('foo', '--smart-case --no-ignore', '/home/bob/stuff')
M.open = ui.open

-- open UI - search pattern = blank
M.open_blank = ui.open

-- open UI - search pattern = <cword>
M.open_cword = function()
    ui.open(vim.fn.expand("<cword>"))
end

-- open UI - search pattern = Previous search pattern that was executed
M.open_again = function()
    ui.open(require("rgflow.state").get_state().pattern)
end

-- open UI - search pattern = First line of unnamed register as the search pattern
M.open_paste = function()
    ui.open(vim.fn.getreg())
end

-- open UI - search pattern = current visual selection
M.open_visual = function()
    local content = utils.get_visual_selection(vim.fn.mode())
    local first_line = utils.get_first_line(content)
    ui.open(first_line)
end

-- With the UI pop up open, start searching with the currently filled out fields
M.start = function()
    if vim.fn.pumvisible() == 0 then
        ui.start()
    end
end

-- Close the current UI window
M.close = ui.close

-- Skips the UI and executes the search immediately
-- Call signature: run(pattern, flags, path)
-- e.g. require('rgflow').search('foo', '--smart-case --no-ignore', '/home/bob/stuff')
M.search = search.run

-- Aborts - Closes the UI if open, if searching will stop, if adding results will stop
M.abort = function()
    local STATE = get_state()
    if STATE.mode == "aborting" then
        print("Still aborting ...")
    elseif STATE.mode == "" then
        print("RgFlow not running.")
    elseif STATE.mode == "open" then
        M.close()
        STATE.mode = ""
        print("Aborted UI.")
    elseif STATE.mode == "searching" then
        local uv = vim.loop
        uv.process_kill(STATE.handle, "SIGTERM")
        STATE.mode = ""
        STATE.results = {} -- Free up memory
        print("Aborted searching.")
    elseif STATE.mode == "adding" then
        STATE.mode = "aborting"
    -- Handed in quickfix.lua
    end
end

M.show_rg_help = ui.show_rg_help

-- No operation
M.nop = function()
end

M.qf_delete = function()
    quickfix.delete_operator(vim.fn.mode())
end

M.qf_delete_line = function()
    quickfix.delete_operator("line")
end

M.qf_delete_visual = function()
    quickfix.delete_operator(vim.fn.mode())
end

M.qf_mark = function()
    quickfix.mark_operator(true, "line")
end

M.qf_mark_visual = function()
    quickfix.mark_operator(true, vim.fn.mode())
end

M.qf_unmark = function()
    quickfix.mark_operator(false, "line")
end

M.qf_unmark_visual = function()
    quickfix.mark_operator(false, vim.fn.mode())
end

-- Auto complete with rgflags or buffer words or filepaths depending on the input box they are on
M.auto_complete = require("rgflow.autocomplete").auto_complete

return M
