return {
  "j-hui/fidget.nvim",
  event = "User CocStatusChange",
  opts = {
    progress = {
      display = {
        done_ttl = 3, -- How long completed tasks remain visible (in seconds)
      },
    },
    notification = {
      window = {
        winblend = 0, -- Background opacity (0 = opaque)
      },
    },
  },
  config = function(_, opts)
    local fidget = require("fidget")
    fidget.setup(opts)

    local coc_handle = nil
    local timer = nil

    vim.api.nvim_create_autocmd("User", {
      pattern = "CocStatusChange",
      callback = function()
        -- 1. Trim whitespace to catch "empty" status strings
        local status = vim.trim(vim.g.coc_status or "")

        -- Helper function to cleanly kill the Fidget notification
        local clear_progress = function()
          if coc_handle then
            coc_handle:finish()
            coc_handle = nil
          end
          if timer then
            timer:stop()
            if not timer:is_closing() then timer:close() end
            timer = nil
          end
        end

        if status ~= "" then
          -- Create or update the Fidget notification
          if not coc_handle then
            coc_handle = fidget.progress.handle.create({
              title = "coc.nvim",
              message = status,
              lsp_client = { name = "coc.nvim" },
            })
          else
            coc_handle:report({ message = status })
          end

          -- 2. Reset the kill timer every time we get an active update
          if timer then
            timer:stop()
            if not timer:is_closing() then timer:close() end
          end

          timer = vim.uv.new_timer() -- Note: Use vim.loop.new_timer() if on Neovim < 0.10
          -- Automatically dismiss after 2000ms (2 seconds) of silence
          timer:start(2000, 0, vim.schedule_wrap(clear_progress))
        else
          -- If status is legitimately empty, clear immediately
          clear_progress()
        end
      end,
    })
  end,
}
