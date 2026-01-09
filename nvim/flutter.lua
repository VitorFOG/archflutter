-- Flutter/Dart development plugins for LazyVim
-- File: lua/plugins/flutter.lua

return {
  -- flutter-tools.nvim - main Flutter development plugin
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for improved UI
    },
    config = function()
      require("flutter-tools").setup({
        ui = {
          border = "rounded",
          notification_style = "native",
        },
        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = false,
          },
        },
        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
          register_configurations = function(paths)
            require("dap").configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter",
                dartSdkPath = vim.fn.expand("~/.local/flutter/bin/cache/dart-sdk"),
                flutterSdkPath = vim.fn.expand("~/.local/flutter"),
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              },
              {
                type = "dart",
                request = "attach",
                name = "Attach Flutter",
                dartSdkPath = vim.fn.expand("~/.local/flutter/bin/cache/dart-sdk"),
                flutterSdkPath = vim.fn.expand("~/.local/flutter"),
                cwd = "${workspaceFolder}",
              },
            }
          end,
        },
        flutter_path = vim.fn.expand("~/.local/flutter/bin/flutter"),
        flutter_lookup_cmd = nil,
        fvm = false,
        widget_guides = {
          enabled = true,
        },
        closing_tags = {
          highlight = "Comment",
          prefix = " // ",
          priority = 0,
          enabled = true,
        },
        dev_log = {
          enabled = true,
          filter = nil,
          notify_errors = true,
          open_cmd = "tabedit",
        },
        dev_tools = {
          autostart = false,
          auto_open_browser = false,
        },
        outline = {
          open_cmd = "30vnew",
          auto_open = false,
        },
        lsp = {
          color = {
            enabled = true,
            background = true,
            foreground = false,
            virtual_text = true,
            virtual_text_str = "  ",
          },
          on_attach = function(client, bufnr)
            -- Standard LSP keymaps are handled by LazyVim
            -- Add Flutter-specific keymaps here
            local opts = { buffer = bufnr, silent = true }
            vim.keymap.set("n", "<leader>Fs", "<cmd>FlutterRun<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Run" }))
            vim.keymap.set("n", "<leader>Fd", "<cmd>FlutterDevices<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Devices" }))
            vim.keymap.set("n", "<leader>Fe", "<cmd>FlutterEmulators<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Emulators" }))
            vim.keymap.set("n", "<leader>Fr", "<cmd>FlutterReload<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Hot Reload" }))
            vim.keymap.set("n", "<leader>FR", "<cmd>FlutterRestart<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Hot Restart" }))
            vim.keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Quit" }))
            vim.keymap.set("n", "<leader>Fl", "<cmd>FlutterDevLog<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Dev Log" }))
            vim.keymap.set("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", vim.tbl_extend("force", opts, { desc = "Flutter Outline" }))
            vim.keymap.set("n", "<leader>Fp", "<cmd>FlutterPubGet<cr>", vim.tbl_extend("force", opts, { desc = "Pub Get" }))
            vim.keymap.set("n", "<leader>FP", "<cmd>FlutterPubUpgrade<cr>", vim.tbl_extend("force", opts, { desc = "Pub Upgrade" }))
          end,
          capabilities = function(config)
            -- Merge with LazyVim's LSP capabilities
            local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
            if ok then
              config.capabilities = vim.tbl_deep_extend(
                "force",
                config.capabilities or {},
                cmp_nvim_lsp.default_capabilities()
              )
            end
            return config
          end,
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
          },
        },
      })
    end,
  },

  -- DAP (Debug Adapter Protocol) support
  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
      local dap = require("dap")
      -- Dart/Flutter adapter configuration
      dap.adapters.dart = {
        type = "executable",
        command = vim.fn.expand("~/.local/flutter/bin/flutter"),
        args = { "debug_adapter" },
      }
    end,
  },

  -- DAP UI for better debugging experience
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },

  -- Treesitter support for Dart
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "dart" })
      end
    end,
  },

  -- Which-key group for Flutter commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>F", group = "Flutter", icon = "" },
      },
    },
  },
}
