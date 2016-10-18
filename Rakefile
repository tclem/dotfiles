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

    file = linkable.split('/').last.split('.')[0..-2].join(".")
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
  `mkdir -p ~/.vim/autoload ~/.vim/bundle && \
  curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim`
  plugins = {
    "vim-colors-solarized" => "https://github.com/altercation/vim-colors-solarized",
    "nerdcommenter"        => "https://github.com/scrooloose/nerdcommenter",
    "nerdtree"             => "https://github.com/scrooloose/nerdtree",
    # "vim-coffee-script"    => "https://github.com/kchmck/vim-coffee-script",
    "vim-surround"         => "https://github.com/tpope/vim-surround",
    "vim-endwise"          => "https://github.com/tpope/vim-endwise",
    "vim-repeat"           => "https://github.com/tpope/vim-repeat",
    "vim-fugitive"         => "https://github.com/tpope/vim-fugitive",
    # "vim-ctrlp"            => "https://github.com/kien/ctrlp.vim",
    # "vim-markdown"         => "https://github.com/plasticboy/vim-markdown",
    # "vim-rails"            => "https://github.com/tpope/vim-rails",
    "vim-ragtag"           => "https://github.com/tpope/vim-ragtag",
    # "vim-json"             => "https://github.com/elzr/vim-json",
    "supertab"             => "https://github.com/ervandew/supertab",
    # "vim-golang"           => "https://github.com/jnwhiteh/vim-golang",
    "vim-dispatch"         => "https://github.com/tpope/vim-dispatch",
    # "ag.vim"               => "https://github.com/rking/ag.vim",
    "vim-align"            => "https://github.com/tsaleh/vim-align",

    #"ack.vim"              => "https://github.com/mileszs/ack.vim",
    #"vim-pencil"           => "https://github.com/reedes/vim-pencil.git",
    #"vim-colors-pencil"    => "https://github.com/reedes/vim-colors-pencil",
    # 'ZoomWin'              => 'git://github.com/vim-scripts/ZoomWin.git',
    # 'scss-syntax'          => 'https://github.com/cakebaker/scss-syntax.vim.git',
    # 'taglist.vim'          => 'git://github.com/vim-scripts/taglist.vim.git',

    # 'vim-indent-object'    => 'git://github.com/michaeljsmith/vim-indent-object.git',
    # 'vim-javascript'       => 'git://github.com/pangloss/vim-javascript.git',
    # 'syntastic'            => 'git://github.com/scrooloose/syntastic.git',
    # 'vim-arduino.vim'      => 'git@github.com:tclem/vim-arduino.git',
    # 'xmledit'              => 'git://github.com/sukima/xmledit.git',
    # 'vim-unimpared'        => 'git://github.com/tpope/vim-unimpaired.git',
    # 'vim-puppet'           => 'git://github.com/rodjek/vim-puppet.git',

    # 'pyflakes-pathogen'    => 'https://github.com/mitechie/pyflakes-pathogen.git',
    # 'pydoc'                => 'https://github.com/fs111/pydoc.vim.git',
    # 'rope-vim'             => 'https://github.com/sontek/rope-vim.git',

    # 'mustache.vim'         => 'git://github.com/juvenn/mustache.vim.git',
    # 'hammer.vim'           => 'git://github.com/matthias-guenther/hammer.vim.git',
    # 'vim-buffergator'      => 'git://github.com/jeetsukumaran/vim-buffergator.git',
    # 'vim-rspec'            => 'git://github.com/taq/vim-rspec.git',
  }

  # Install each plugin by cloning into pathogen's bundle dir
  plugins.reverse_each do |k, v|
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
