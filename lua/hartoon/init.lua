local M = {}

local session_file = vim.fn.stdpath('config') .. '/hartoon_tmux_sessions.txt'

local function read_sessions()
    local sessions = {}
    local f = io.open(session_file, 'r')
    if f then
        for line in f:lines() do
            if line ~= '' then
                table.insert(sessions, line)
            end
        end
        f:close()
    end
    return sessions
end

local function write_sessions(sessions)
    local f = io.open(session_file, 'w')
    if f then
        for _, s in ipairs(sessions) do
            f:write(s .. '\n')
        end
        f:close()
    end
end

-- Helper function to switch to a tmux session
local function switch_to_tmux_session(session_name)
    if not session_name or session_name == '' then
        return
    end
    
    -- Check if tmux is running
    local tmux_running = vim.fn.system('pgrep tmux')
    local in_tmux = vim.env.TMUX ~= nil
    
    -- Check if session exists
    local session_exists = vim.fn.system('tmux list-sessions -F "#{session_name}" | grep -Fx "' .. session_name .. '"')
    
    if session_exists == '' then
        -- Session doesn't exist, create it
        vim.fn.jobstart('tmux new-session -ds "' .. session_name .. '"', { detach = true })
    end
    
    -- Switch to session
    if in_tmux then
        -- We're inside tmux, switch client
        vim.fn.jobstart('tmux switch-client -t "' .. session_name .. '"', { detach = true })
    else
        -- We're outside tmux, attach to session
        vim.fn.jobstart('tmux attach-session -t "' .. session_name .. '"', { detach = true })
    end
end

function M.pin_current_tmux_session()
    local handle = io.popen("tmux display-message -p '#S'")
    local session = handle:read("*l")
    handle:close()
    if not session or session == '' then
        vim.notify('No tmux session found', vim.log.levels.ERROR)
        return
    end
    local sessions = read_sessions()
    for _, s in ipairs(sessions) do
        if s == session then
            vim.notify('Session already pinned', vim.log.levels.INFO)
            return
        end
    end
    table.insert(sessions, session)
    write_sessions(sessions)
    vim.notify('Pinned tmux session: ' .. session)
end

function M.edit_pinned_sessions()
    -- Read sessions
    local sessions = read_sessions()
    -- Check if a buffer with the session file name exists
    local bufname = session_file
    local buf = nil
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(b) == bufname then
            buf = b
            break
        end
    end
    if not buf then
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        vim.api.nvim_buf_set_option(buf, 'filetype', 'hartoon_tmux')
        vim.api.nvim_buf_set_name(buf, bufname)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, sessions)
    else
        -- If buffer exists, ensure it's modifiable before setting lines
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, sessions)
    end
    -- Floating window
    local width = math.floor(vim.o.columns * 0.4)
    local height = math.max(5, #sessions)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        title = 'Hartoon - Pinned Tmux Sessions',
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })
    -- Save on write
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            write_sessions(lines)
            vim.notify('Pinned tmux sessions updated!')
        end,
        once = true,
    })
    -- Map <CR> to swap to the session under the cursor and close the popup
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        if line and line ~= '' then
            switch_to_tmux_session(line)
        end
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, desc = 'Swap to tmux session and close popup' })
end

function M.telescope_tmux_sessions()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    -- Get tmux sessions
    local handle = io.popen('tmux list-sessions -F "#{session_name}"')
    local result = handle:read("*a")
    handle:close()
    local sessions = {}
    for s in result:gmatch("[^\n]+") do
        table.insert(sessions, s)
    end

    pickers.new({}, {
        prompt_title = 'Tmux Sessions',
        finder = finders.new_table {
            results = sessions,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection and selection[1] then
                    switch_to_tmux_session(selection[1])
                end
            end)
            return true
        end,
    }):find()
end

function M.jump(idx)
    local sessions = read_sessions()
    local session = sessions[idx]
    if session and session ~= '' then
        switch_to_tmux_session(session)
    else
        vim.notify('No session at index ' .. tostring(idx), vim.log.levels.ERROR)
    end
end

function M.setup()
    vim.api.nvim_create_user_command('HartoonTmuxSessions', M.telescope_tmux_sessions, {})
    vim.api.nvim_create_user_command('HartoonPinTmuxSession', M.pin_current_tmux_session, {})
    vim.api.nvim_create_user_command('HartoonEditPinnedTmux', M.edit_pinned_sessions, {})
    vim.api.nvim_create_user_command('HartoonJumpTo1', function() M.jump(1) end, {})
    vim.api.nvim_create_user_command('HartoonJumpTo2', function() M.jump(2) end, {})
    vim.api.nvim_create_user_command('HartoonJumpTo3', function() M.jump(3) end, {})
end

return M 