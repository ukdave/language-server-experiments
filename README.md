# Language Server Experiments

A playground for messing about with Language Servers.

For more info check out these resources:

* [Official page for Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
* [Language Server Extension Guide | Visual Studio Code Extension API](https://code.visualstudio.com/api/language-extensions/language-server-extension-guide)
* [Ruby LSP](https://github.com/Shopify/ruby-lsp)

Also check out these videos:

* [RubyConf 2022: Improving the development experience with language servers by Vinicius Stock](https://youtu.be/kEfXPTm1aCI)
* [RailsConf 2023 - Keynote: Aaron Patterson](https://youtu.be/LcDNedD-8mU)


## Vim Setup

This instructions assume you haven't configured Vim in any way.

First, install the [vim-lsp](https://github.com/prabirshrestha/vim-lsp) plugin:

```bash
mkdir -p ~/.vim/pack/lsp/start
git clone https://github.com/prabirshrestha/vim-lsp ~/.vim/pack/lsp/start/vim-lsp
```

Then edit `~/.vimrc` and enable filetype detection, syntax highlighting, and configure a language-server for ruby files:

```vim
filetype on
filetype plugin on
filetype indent on

syntax on

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')

au User lsp_setup call lsp#register_server({
      \      'name': 'LSP Test',
      \      'cmd': {server_info->["/Users/david/language-server-experiments/server/lsp_rubocop.rb"]},
      \      'allowlist': ['ruby'],
      \ })
```

Now edit `app/app.rb`, save the file, and see the rubocop violations appear:

![Screenshot of rubocop violations in Vim](/screenshot.png?raw=true "Screenshot")


## Testing from the command-line

Language servers use `STDIN` and `STDOUT` to communicate with an editor. This means you can also test them directly
from the command-line by piping a message into them using `echo`, e.g:

```bash
echo 'Content-Length: 128\r\n\r\n{"method":"textDocument/didSave","params":{"textDocument":{"uri":"file:///Users/david/language-server-experiments/app/app.rb"}}}' | server/lsp_rubocop.rb
```

response:

```json
{"method":"textDocument/publishDiagnostics","params":{"uri":"file:///Users/david/language-server-experiments/app/app.rb","diagnostics":[{"range":{"start":{"character":0,"line":0},"end":{"character":9,"line":0}},"message":"Missing top-level documentation comment for `class App`.","severity":2},{"range":{"start":{"character":0,"line":0},"end":{"character":1,"line":0}},"message":"Missing frozen string literal comment.","severity":2},{"range":{"start":{"character":9,"line":2},"end":{"character":16,"line":2}},"message":"Prefer double-quoted strings unless you need single quotes to avoid extra backslashes for escaping.","severity":2}]},"jsonrpc":"2.0"}
```
