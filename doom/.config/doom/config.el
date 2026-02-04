;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates, and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 25))
;; 专门设置中文字体
(defun my-setup-chinese-font ()
  (set-fontset-font t 'han (font-spec :family "Noto Sans CJK SC")) ; Linux 推荐
  )
;; 在字体加载后应用中文设置
(add-hook 'after-setting-font-hook #'my-setup-chinese-font)
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and `M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
;;There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-tokyo-night)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
(setq org-roam-directory "~/org/roam/")
;; org-agenda-files is configured later with detailed file list


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path` when you load packages with
;;   `require` or `use-package`.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions, move the cursor over
;; the highlighted symbol and press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how to use them.
;; Alternatively, use 'C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! org
  (setq org-babel-load-languages
        (append org-babel-load-languages
                '((C . t)))))

(set-frame-parameter nil 'undecorated t)

;; zen 模式，居中显示
(use-package! olivetti
  :config
  (setq-default olivetti-body-width 60) ; 设置文字区域宽度，100 或 120 比较舒适
  )

;; 设置全局滚动边距
(setq scroll-margin 8)
;; 让滚动更加平滑（逐行滚动，而不是一下跳很多行）
(setq scroll-step 1
      scroll-conservatively 10000
      auto-window-vscroll nil)

;; 鼠标滚动设置
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse 't)

;; lsp 补全配置
(setq lsp-completion-provider :capf) ; 强制使用 Emacs 的标准补全接口
(after! c-mode
  (set-company-backend! 'c-mode
    '(:separate company-capf company-yasnippet company-files)))
(after! lsp-clangd
  (setq lsp-clients-clangd-args
        '(
          ;; 1. 基础性能优化
          "-j=4"                         ; 限制多线程占用
          "--background-index"           ; 允许后台索引
          "--clang-tidy"                 ; 开启静态检查

          ;; 2. 补全行为优化 (LazyVim 风格)
          "--completion-style=detailed"  ; 显示详细补全信息
          "--header-insertion=never"     ; 禁止自动插入头文件 (内核开发中自动插入往往会乱)
          "--header-insertion-decorators"

          ;; 3. 增强补全的"宽容度" (关键！)
          "--all-scopes-completion"      ; 允许补全不在当前 scope 的符号
          "--limit-results=20"           ; 限制结果数，提高速度

          ;; 4. 强制指定位置 (如果你的 compile_commands.json 找不到)
          "--compile-commands-dir=."
          )))
;; 强制让补全弹窗在输入 1 个字符时就跳出来 (复刻 LazyVim 体验)
(after! company
  (setq company-idle-delay 0
        company-minimum-prefix-length 1))

;; 可视行跳转
(map! :nv "j" #'evil-next-visual-line
      :nv "k" #'evil-previous-visual-line)

;; wikilink
(setq markdown-enable-wiki-links t)

;; 中文输入法切换问题
(use-package! sis
  :config
  ;; 1. 配置后端（根据你第一步的测试结果选择）
  ;; 如果是 fcitx5，使用 'fcitx5；如果是 ibus，使用 'ibus-client
  (sis-ism-lazyman-config "1" "2" 'fcitx5)

  ;; 2. 开启 Evil 模式的自动切换
  ;; 退出 insert 模式时，自动切回英文（状态 1）
  (sis-global-cursor-color-mode t) ; 还可以根据输入法改变光标颜色，视觉提醒
  (sis-global-respect-mode t)      ; 核心功能：退出 insert 模式切换输入法

  ;; 3. 开启 Context 记忆
  ;; 当你回到 insert 模式时，恢复上次在该 Buffer 使用的输入法（非常人性化）
  (sis-global-context-mode t)

  ;; 4. 优化：在特定的命令后强制切回英文
  ;; 比如按下 SPC 后通常是要输入命令，强制切英文
  (add-hook 'doom-first-input-hook #'sis-global-respect-mode))

;; 强制定义一个完全不依赖日历的函数
(defun my/quick-insert-time ()
  "直接在光标处插入当前的精确时间，不弹出任何窗口"
  (interactive)
  (insert (format-time-string "[%Y-%m-%d %a %H:%M]")))

;; 绑定到一个你绝对不会按错的组合键
(map! :leader
      :desc "Quick timestamp" "i T" #'my/quick-insert-time)

;; ============================
;; Org-mode 核心路径与 GTD
;; ============================
(setq org-agenda-files
      (list "~/org/inbox.org"    ; 收集箱
            "~/org/todo.org"     ; 待办
            "~/org/projects.org" ; 项目
            "~/org/tickler.org"  ; 备忘
            "~/org/journal/"))   ; 日记

;; ============================
;; Org-modern 美化
;; ============================
(use-package! org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("◉" "○" "◈" "◇" "✳" "◆" "□" "▪" "▫")))

;; ============================
;; GPTel AI 配置 (NewAPI)
;; ============================
(use-package! gptel
  :config
  ;; 连接到本地 NewAPI
  (setq gptel-model "glm-4.7"
        gptel-backend (gptel-make-openai "NewAPI"
                        :host "localhost:3000"
                        :key "sk-kBSBKQQHlXHNNzSUVTNdubISw8n0T52rqXnf7xgqdjHEHP6W"
                        :stream t
                        :protocol "http"
                        :curl-args '("--noproxy" "localhost,127.0.0.1")
                        :models '("gemini-3-pro-preview" "glm-4.7" "deepseek-v3" "deepseek-r1")))
  ;; 使用 curl 而不是 url-retrieve (更稳定)
  (setq gptel-use-curl t)
  ;; 绑定快捷键到 leader key
  (map! :leader
        :desc "GPTel Menu" "o a" #'gptel-menu
        :desc "GPTel Send" "o s" #'gptel-send))

;; ============================
;; GPTel Advanced Context Functions
;; ============================

(defun my/gptel-add-project-files ()
  "Interactively select and add multiple files from current project to gptel context."
  (interactive)
  (if-let ((project (project-current))
           (files (project-files project)))
      (let ((selected (completing-read-multiple "Add files to context: " files)))
        (if selected
            (progn
              (dolist (file selected)
                (gptel-add-file file))
              (message "Added %d files to gptel context" (length selected)))
          (message "No files selected")))
    (message "Not in a project")))

(defun my/gptel-add-git-diff ()
  "Add files modified in git to gptel context."
  (interactive)
  (let* ((default-directory (if-let ((proj (project-current)))
                               (project-root proj)
                             default-directory))
         (changed-files (split-string 
                         (shell-command-to-string 
                          "git diff --name-only 2>/dev/null")
                         "\n" t)))
    (if changed-files
        (progn
          (dolist (file changed-files)
            (when (file-exists-p file)
              (gptel-add-file file)))
          (message "Added %d changed files to context" (length changed-files)))
      (message "No changed files found"))))

(defun my/gptel-add-directory-files (dir)
  "Add files from DIR to gptel context.
Excludes common junk directories (node_modules, .git, .env, dist, build).
Prompts for confirmation if more than 20 files would be added."
  (interactive "DAdd directory: ")
  (let* ((excluded-dirs '("node_modules" ".git" ".env" "dist" "build" "target" "__pycache__" ".venv" "venv"))
         (files (directory-files-recursively dir ""))
         (filtered (seq-filter 
                   (lambda (file)
                     (and (not (string-match-p "/\\." (file-relative-name file dir))) ; hidden files
                          (not (seq-some (lambda (excl) (string-match-p excl file)) excluded-dirs))))
                   files)))
    (if filtered
        (let ((count (length filtered)))
          (if (and (> count 20)
                   (not (y-or-n-p (format "Add %d files from %s? " count dir))))
              (message "Cancelled: too many files")
            (dolist (file filtered)
              (when (file-regular-p file)
                (gptel-add-file file)))
            (message "Added %d files from %s to context" count dir)))
      (message "No files found in %s" dir))))

;; ============================
;; GPTel Advanced Context Keybindings
;; ============================
;; Usage:
;;   SPC o c f - Add project files (multi-select)
;;   SPC o c g - Add git-modified files
;;   SPC o c d - Add directory files
(map! :leader
      :prefix ("o c" . "gptel context")
      :desc "Add project files" "f" #'my/gptel-add-project-files
      :desc "Add git changed files" "g" #'my/gptel-add-git-diff
      :desc "Add directory files" "d" #'my/gptel-add-directory-files)