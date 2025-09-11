{
  pkgs,
  lib-mine,
  vendor,
  ...
}: let
  obsidian-remote-cli = vendor.obsidian-remote.default;
  monoFont = "Aporetic Sans Mono";
in
  lib-mine.mkFeature "features.application-support.obsidian" {
    config = {
      home.packages = with pkgs; [
        obsidian
        obsidian-remote-cli
        fira-code
      ];

      programs.obsidian = {
        enable = true;
        vaults = [
          "Notes/maxnotes"
        ];
        config = {
          appearance = {
            enable = true;
            interfaceFontFamily = monoFont;
            textFontFamily = monoFont;
            monospaceFontFamily = monoFont;
            baseFontSize = 18;
          };
          vimrc = ''
            exmap followlink obcommand editor:follow-link
            exmap back obcommand app:go-back
            exmap forward obcommand app:go-forward
            exmap openswitcher obcommand switcher:open
            exmap insertlink obcommand editor:insert-link
            exmap surround_wiki surround [[ ]]
            exmap surround_double_quotes surround " "
            exmap surround_single_quotes surround ' '
            exmap surround_backticks surround ` `
            exmap surround_brackets surround ( )
            exmap surround_square_brackets surround [ ]
            exmap surround_curly_brackets surround { }

            set clipboard=unnamed

            unmap <Space>

            " NOTE: must use 'map' and not 'nmap'
            nunmap O
            vunmap O

            nmap j gj
            nmap k gk
            nmap gd :followlink<CR>
            vmap gd :insertlink<CR>
            nmap <C-o> :back<CR>
            nmap - :back<CR>
            nmap <C-i> :forward<CR>
            nmap <Space><Space> :openswitcher<CR>
            map [[ :surround_wiki<CR>
            map O" :surround_double_quotes<CR>
            map O' :surround_single_quotes<CR>
            map O` :surround_backticks<CR>
            map Ob :surround_brackets<CR>
            map O( :surround_brackets<CR>
            map O) :surround_brackets<CR>
            map O[ :surround_square_brackets<CR>
            map O] :surround_square_brackets<CR>
            map O{ :surround_curly_brackets<CR>
            map O} :surround_curly_brackets<CR>
          '';
        };
      };
    };
  }
