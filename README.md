Polyfill for `:checkhealth` in Vim
==================================

[vim-healthcheck][] is a polyfill plugin for Vim to use a health-check feature in [Neovim][]. Neovim's
health-check feature is a minimal framework to help with troubleshooting user configuration.
[vim-healthcheck][] provides the same feature for Vim.

Plugin authors can write health-checks for their plugins using the APIs. And plugin users can check
if the installation is healthy. By this polyfill, plugin authors can write common health-checks for
both Neovim and Vim. And plugin users can check their configuration using the health-checks which
was written for Neovim. It would be useful for troubleshooting or triaging issues.

This plugin is just a port of Neovim's health-check implementation.

## Usage

Instead of Neovim's standard `:checkhealth` command, it provides `:CheckHealth` command on Vim.
If no argument is given, it runs all health-checks and show the results.

```
:CheckHealth
```

If some plugin names are specified as arguments, it runs health-checks for them.

```
:CheckHealth {plugin1} {plugin2} ...
```

For example, `:CheckHealth vim` runs health-checks for Vim itself.

To know the detail of the command behavior or to know how to implement health-checks for your plugins,
please read a help document.

```
:help health
```

## Installation

If you use a plugin manager, please follow the instruction. Please note that this plugin is needed
only on Vim because Neovim supports health-check feature by default.

### vim-plug

```vim
if !has('nvim')
    Plug 'rhysd/vim-healthcheck'
endif
```

### dein.vim

```vim
if !has('nvim')
    call dein#add('rhysd/vim-healthcheck')
endif
```

### minpac

```vim
if !has('nvim')
    call minpac#add('rhysd/vim-healthcheck')
endif
```

## License

This plugin was created by porting the implementation of health-check feature for Neovim. So this
plugin is distributed under the same license as Neovim. Please read [LICENSE](LICENSE) for the
details.

[vim-healthcheck]: https://github.com/rhysd/vim-healthcheck
[Neovim]: https://github.com/neovim/neovim
