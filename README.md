# 🌳 SupraTree.vim

**SupraTree** is a "staging-first" file explorer for Vim 9.
Positioned between **Neo-tree** for its interface and **Oil.nvim** for its editing capabilities, it allows you to manipulate your file system like a simple text buffer.

<img width="755" height="750" alt="image" src="https://github.com/user-attachments/assets/7d73090c-b25c-4a4c-ae74-43ffd9b801e3" />



https://github.com/user-attachments/assets/18dee59a-0ac2-48cd-8fb7-9cfa0886c489


## ✨ The "Supra" Concept

Unlike traditional explorers that apply every change immediately, SupraTree works through **intentions**:
1. You modify the tree (rename, create, delete).
2. Changes are visually highlighted.
3. You commit all operations at once using `:w` or `<C-s>`.

## 🚀 Features

* **Direct Editing**: Rename (`i`), create (`o`), or delete (`dd`) files just like text.
* **Integrated VCS**: Asynchronous support for **Git** and **SVN**.
* **Smart Clipboard**: Yank/Paste (`y`/`p`) supporting visual selections for bulk operations.
* **Modern UI**: Automatic sidebar dimming (`DarkenColor`) and full icon font support.

## 📦 Installation

### 🧩 Dependencies

- **Vim 9.1.1110+**
- **VCS**: `git` or `svn`
- **Icons**: Use a compatible icon extension (e.g., `nda-cunh/SupraIcons`) for the best experience.
- **Palette**: Use a compatible palette extension (e.g., `nda-cunh/SupraIcons.vim` or `lambdalisue/vim-glyph-palette`) for perfect theme integration.

`vim
Plug 'nda-cunh/SupraTree.vim'
`

## 💻 Basic Commands

`:SupraTreeOpen`      # Opens the tree in a new window
`:SupraTreeClose`     # Closes the tree window
`:SupraTreeToggle`    # Opens or closes the tree depending on its state
`:SupraTreeRefresh`   # Syncs the tree with the file system


## ⌨️ Tree Buffer Mappings

### Navigation
| Key | Action |
| :--- | :--- |
| `<CR>` | Open file / Expand folder |
| `<C-t>` / `<C-h>` / `<C-v>` | Open in Tab / Split / VSplit |
| `-` / `<BS>` | Move up to parent directory |
| `P` | Jump to parent folder |
| `{` / `}` | Jump to previous / next sibling |
| `J` / `K` | Fast jump to first / last child |

### CRUD Operations (Editing)
| Key | Action |
| :--- | :--- |
| `i` | **Rename**: Modify the name of the node under the cursor |
| `o` / `O` | **New File**: Create a file (add `/` for a folder) |
| `dd` | **Delete**: Mark the file for deletion |
| `y` / `yy` | **Yank**: Add to the SupraTree clipboard |
| `p` | **Paste**: Paste copied files into the selected folder |
| `<C-s>` / `:w` | **Save**: Actually apply changes to the disk |
| `r` | **Refresh**: Sync the tree with the disk and VCS |

## ⚙️ Global Configuration

Add these variables to your `.vimrc` to customize your experience:

### Behavior & Layout
- `g:supratree_open_on_startup` (Default: `true`): Automatically opens the tree on Vim launch.
- `g:supratree_position` (Default: `'left'`): Window position (`'left'` or `'right'`).
- `g:supratree_width` (Default: `26`): Tree window width.
- `g:supratree_sortascending` (Default: `true`): Sorts files alphabetically.

### Filtering & Visibility
- `g:supratree_filter_files` (Default: `['*.o', '*.class', ...]`): List of file patterns to hide.
- `g:supratree_show_hidden` (Default: `true`): Show or hide hidden files (starting with `.`).

### Icons & Palette
- `g:supratree_icons_glyph_func`: Function to fetch the icon glyph (e.g., `WebDevIconsGetFileTypeSymbol`).
- `g:supratree_icons_glyph_palette_func`: Function to apply colors to icons (e.g., `SupraIcons#Palette#Apply`).


## 🎨 Design & Colors

- `g:supratree_darken_amount` (Default: `22`): Intensity of the tree column dimming (0-255).
- `g:supratree_force_color` (Default: `''`): Force a specific background color if defined.


### Why use SupraTree?
Because manipulating files shouldn't be any different from manipulating text. Stage your project structure, double-check the colors to avoid mistakes, and `:w`. That's it.
