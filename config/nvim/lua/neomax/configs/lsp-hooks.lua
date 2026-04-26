local map = vim.keymap.set

local M = {}

M.compose_hook = function(hooks)
  return function(client, bufnr)
    for _, hook in ipairs(hooks) do
      if hook ~= nil then
        hook(client, bufnr)
      end
    end
  end
end

M.on_init = function(client, _)
  -- if client.supports_method("textDocument/semanticTokens") then
  -- 	client.server_capabilities.semanticTokensProvider = nil
  -- end
end

M.on_attach = function(client, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = desc }
  end
  -- lsp_status.on_attach(client)

  map("n", "gD", vim.lsp.buf.declaration, opts("Lsp Go to declaration"))
  map("n", "gd", ":Telescope lsp_definitions theme=cursor<CR>", opts("Lsp Go to definition"))
  map("n", "gwd", ":vsplit | lua vim.lsp.buf.definition()<CR>", opts("Lsp Go to definition in new vertical split"))
  map("n", "gwD", ":vsplit | lua vim.lsp.buf.declaration()<CR>", opts("Lsp Go to declaration in new vertical split"))
  map("n", "gWd", ":split | lua vim.lsp.buf.definition()<CR>", opts("Lsp Go to definition in new horizontal split"))
  map("n", "gWD", ":split | lua vim.lsp.buf.declaration()<CR>", opts("Lsp Go to declaration in new horizontal split"))
  map("n", "gr", ":Telescope lsp_references theme=cursor<CR>", opts("Lsp References"))
  map("n", "gi", ":Telescope lsp_implementations theme=cursor<CR>", opts("Lsp Go to implementation"))

  -- map("n", "K", "<cmd>Lspsaga hover_doc<CR>")

  map("n", "<leader>sh", vim.lsp.buf.signature_help, opts("Lsp Show signature help"))
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts("Lsp Add workspace folder"))
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Lsp Remove workspace folder"))

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts("Lsp List workspace folders"))

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Lsp Go to type definition"))
  map("n", "<leader>ra", vim.lsp.buf.rename, opts("Lsp Rename"))

  -- map("n", "<leader>ra", "<cmd>Lspsaga rename ++project<CR>", opts("Rename code symbol"))

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Lsp Code action"))
  -- map("n", "gr", "<cmd>Lspsaga finder<CR>")

  map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "Lsp floating diagnostics" })
  map("n", "]d", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, { desc = "Lsp prev diagnostic" })
  map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, { desc = "Lsp next diagnostic" })
  map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Lsp diagnostic loclist" })
end

M.config_servers = function(servers, capabilities)
  local blink = require("blink.cmp")

  for _, lsp in ipairs(servers) do
    local config = {}
    if type(lsp) == "table" then
      config = lsp[2]
      lsp = lsp[1]
    end

    local attach_hook = M.on_attach
    local init_hook = M.on_init

    if vim.lsp.config[lsp] ~= nil and vim.lsp.config[lsp].on_attach ~= nil then
      attach_hook = M.compose_hook({ vim.lsp.config[lsp].on_attach, attach_hook })
    end

    if vim.lsp.config[lsp] ~= nil and vim.lsp.config[lsp].on_init ~= nil then
      init_hook = M.compose_hook({ vim.lsp.config[lsp].on_init, init_hook })
    end

    if config.on_attach ~= nil then
      attach_hook = M.compose_hook({ config.on_attach, attach_hook })
    end
    if config.on_init ~= nil then
      init_hook = M.compose_hook({ config.on_init, init_hook })
    end

    config = vim.tbl_deep_extend("force", vim.lsp.config[lsp] or {}, { capabilities = capabilities }, config)

    if lsp == "ts_ls" then
      print(lsp .. " " .. vim.inspect(config.capabilities))
    end

    config.on_attach = attach_hook
    config.on_init = init_hook

    config.capabilities = blink.get_lsp_capabilities(config.capabilities)

    vim.lsp.config(lsp, config)
    vim.lsp.enable(lsp)
  end
end

return M
