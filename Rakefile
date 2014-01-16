require "rake"

task :default => "install"

desc "Hook our dotfiles into system-standard positions."
task :install do
  linkables = Dir.glob("*/**/**{.symlink}")
  puts linkables

  skip_all = false
  overwrite_all = false
  backup_all = false

  linkables.each do |linkable|
    overwrite = false
    backup = false

    file = linkable.split('/').last.split('.').first
    target = "#{ENV["HOME"]}/.#{file}"

    if File.exists?(target) || File.symlink?(target)
      unless skip_all || overwrite_all || backup_all
        puts "File already exists: #{target}, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all"
        case STDIN.gets.chomp
        when 'o' then overwrite = true
        when 'b' then backup = true
        when 'O' then overwrite_all = true
        when 'B' then backup_all = true
        when 'S' then skip_all = true
        end
      end
      FileUtils.rm_rf(target) if overwrite || overwrite_all
      `mv "$HOME/.#{file}" "$HOME/.#{file}.backup"` if backup || backup_all
    end
    `ln -s "$PWD/#{linkable}" "#{target}"`
  end
end

desc "Install or update all vim plugins"
task :vim do
  plugins = {
    "vim-colors-solarized" => "git://github.com/altercation/vim-colors-solarized.git",
    "nerdcommenter"        => "git://github.com/scrooloose/nerdcommenter.git",
    "nerdtree"             => "git://github.com/scrooloose/nerdtree.git",
    "vim-coffee-script"    => "git://github.com/kchmck/vim-coffee-script.git",
    "vim-surround"         => "git://github.com/tpope/vim-surround.git",
    "vim-endwise"          => "git://github.com/tpope/vim-endwise.git",
    "vim-repeat"           => "git://github.com/tpope/vim-repeat.git",
    "vim-fugitive"         => "git://github.com/tpope/vim-fugitive.git",
    "vim-ctrlp"            => "https://github.com/kien/ctrlp.vim.git",

    # 'ZoomWin'              => 'git://github.com/vim-scripts/ZoomWin.git',
    # 'ack.vim'              => 'git://github.com/mileszs/ack.vim.git',
    # 'scss-syntax'          => 'https://github.com/cakebaker/scss-syntax.vim.git',
    # 'taglist.vim'          => 'git://github.com/vim-scripts/taglist.vim.git',

    # 'vim-indent-object'    => 'git://github.com/michaeljsmith/vim-indent-object.git',
    # 'vim-javascript'       => 'git://github.com/pangloss/vim-javascript.git',
    # 'vim-ragtag'           => 'https://github.com/tpope/vim-ragtag.git',
    # 'vim-rails'            => 'git://github.com/tpope/vim-rails.git',
    # 'vim-markdown'         => 'git://github.com/tpope/vim-markdown.git',
    # 'vim-align'            => 'git://github.com/tsaleh/vim-align.git',
    # 'syntastic'            => 'git://github.com/scrooloose/syntastic.git',
    # 'vim-arduino.vim'      => 'git@github.com:tclem/vim-arduino.git',
    # 'supertab.vim'         => 'git://github.com/ervandew/supertab.git',
    # 'xmledit'              => 'git://github.com/sukima/xmledit.git',
    # 'vim-unimpared'        => 'git://github.com/tpope/vim-unimpaired.git',
    # 'vim-puppet'           => 'git://github.com/rodjek/vim-puppet.git',

    # 'pyflakes-pathogen'    => 'https://github.com/mitechie/pyflakes-pathogen.git',
    # 'pydoc'                => 'https://github.com/fs111/pydoc.vim.git',
    # 'rope-vim'             => 'https://github.com/sontek/rope-vim.git',
    # 'vim-golang'           => 'https://github.com/jnwhiteh/vim-golang',

    # 'mustache.vim'         => 'git://github.com/juvenn/mustache.vim.git',
    # 'hammer.vim'           => 'git://github.com/matthias-guenther/hammer.vim.git',
    # 'vim-buffergator'      => 'git://github.com/jeetsukumaran/vim-buffergator.git',
    # 'vim-rspec'            => 'git://github.com/taq/vim-rspec.git',
  }

  # Install each plugin by cloning into pathogen's bundle dir
  plugins.each do |k, v|
    dest = "#{ENV["HOME"]}/.vim/bundle/#{k}"
    if File.directory?(dest) || File.exist?(dest)
      puts "### updating #{dest}"
      puts `cd #{dest} && git pull`
    else
      puts "### cloning #{k} to #{dest}"
      puts `git clone #{v} #{dest}`
    end
  end
end
