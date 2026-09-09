return {
  "AlexandrosAlexiou/intellij-server.nvim",
  ft = { "kotlin" },
  dependencies = { "mfussenegger/nvim-dap" },
  build = ":IntellijServerInstall",
  opts = {
    -- fixed initial heap avoids JVM resize pauses mid-session; ceiling stays generous
    filetypes = { "kotlin" },
    jvm_args = { "-Xms2g", "-Xmx8g" },

    code_lens = { enabled = false }, -- competes with completion for analysis threads

    -- SPECULATIVE — confirm these keys exist in the plugin's opts type before relying on them:
    inlay_hints = { enabled = false },                      -- extra analysis pass, disable if unneeded
    diagnostics = { on_type = false },                      -- if it supports deferring diagnostics off the typing path
    indexing = { exclude = { "build", ".gradle", "out" } }, -- narrow project scope if supported
  },
}
