return {
  "ariedov/android-nvim",
  cmd = {
    "AndroidRun",
    "AndroidBuildRelease",
    "AndroidClean",
    "AndroidNew",
    "AndroidRefreshDependencies",
    "AndroidUninstall",
    "LaunchAvd",
  },
  config = function()
    vim.env.ANDROID_AVD_HOME = vim.fn.expand("~/.config/.android/avd")
    vim.g.android_sdk = vim.fn.expand("~/Android/Sdk")
    require("android-nvim").setup()
  end,
}
