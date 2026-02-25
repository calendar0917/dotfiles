;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; 在此处放置你的私有配置！请记住，修改此文件后无需运行 'doom sync'！

;; 某些功能使用此信息来识别你的身份，例如 GPG 配置、邮件客户端、
;; 文件模板和代码片段。这是可选的。
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom 提供了五个（可选的）变量用于控制字体：
;;
;; - `doom-font' -- 主字体
;; - `doom-variable-pitch-font' -- 非等宽字体（在适用处使用）
;; - `doom-big-font' -- 用于 `doom-big-font-mode'；适用于演示或直播
;; - `doom-symbol-font' -- 用于符号
;; - `doom-serif-font' -- 用于 `fixed-pitch-serif' 面
;;
;; 查看 'C-h v doom-font' 获取文档和更多示例。例如：
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; 如果你或 Emacs 找不到字体，使用 'M-x describe-font' 查找，
;; `M-x eval-region' 执行 elisp 代码，'M-x doom/reload-font' 刷新字体设置。
;; 如果 Emacs 仍然找不到字体，可能是安装不正确。字体问题很少是 Doom 的问题。

;; 加载主题有两种方式。两者都假设主题已安装且可用。
;; 你可以设置 `doom-theme' 或使用 `load-theme' 函数手动加载主题。
;; 这是默认设置：

;; 1. 设置主题 (Doom 自带了多种 tokyo-night 变体)
(setq doom-theme 'doom-tokyo-night)

;; 2. 设置 Maple Mono NF CN
;; :size 是字号，根据你的屏幕分辨率调整
(setq doom-font (font-spec :family "Maple Mono NF CN" :size 16 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "Maple Mono NF CN" :size 15))

;; 3. 开启行号 (类似 LazyVim 的相对行号)
;; 这决定了生效的行号样式。如果设为 `nil'，则禁用行号。
;; 如需相对行号，请设为 `relative'。
(setq display-line-numbers-type 'relative)

;; 如果你使用 `org' 且不想将 org 文件放在下面的默认位置，
;; 请修改 `org-directory'。必须在 org 加载前设置！
;; === org 配置 ===
(after! org
  (setq org-directory "~/org/")
  (setq org-agenda-files '("~/org/inbox.org"
                         "~/org/projects.org"
                         "~/org/tickler.org"))
  (setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "STRT(s)" "WAIT(w)" "|" "DONE(d)" "KILL(k)")))
  (setq org-capture-templates
      '(("t" "Personal todo" entry
         (file+headline "~/org/inbox.org" "Inbox")
         "* TODO %?\n%i\n%a" :prepend t)
        ("n" "Notes" entry
         (file+headline "~/org/inbox.org" "Notes")
         "* %?\n%U" :prepend t)))
  )

(after! org-roam
  (setq org-roam-directory "~/org/notes")
  (org-roam-db-autosync-mode)) ; 自动同步数据库，确保搜索能搜到新笔记

;; === 输入法配置 ==
(use-package! sis
  :config
  ;; 配置输入法前缀，fcitx5 默认通常是 "fcitx5-remote"
  (sis-ism-lazyman-config "1" "2" 'fcitx5)

  ;; 启用常用的切换功能
  (sis-global-cursor-color-mode t) ; 根据输入法状态改变光标颜色（很直观！）
  (sis-global-respect-mode t)       ; 退出 insert 模式时恢复英文
  (sis-global-context-mode t)       ; 根据上下文记忆输入法状态

  ;; 解决 Wayland 特有的延迟或失灵问题
  (setq sis-default-cursor-color "ivory"
        sis-other-cursor-color "orange")
)

;; 每当你重新配置一个包时，确保将配置包裹在 `with-eval-after-load' 块中，
;; 否则 Doom 的默认设置可能会覆盖你的配置。例如：
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; 此规则的例外情况：
;;
;;   - 设置文件/目录变量（如 `org-directory'）
;;   - 设置那些明确告知需在包加载前设置的变量（查看 'C-h v VARIABLE'）
;;   - 设置 doom 变量（以 'doom-' 或 '+' 开头）
;;
;; 以下是一些额外的函数/宏，可帮助你配置 Doom：
;;
;; - `load!' 用于加载相对于此文件的外部 *.el 文件
;; - `add-load-path!' 用于将目录添加到相对于此文件的 `load-path'。
;;   Emacs 在使用 `require' 或 `use-package' 加载包时会搜索 `load-path'。
;; - `map!' 用于绑定新按键
;;
;; 要获取这些函数/宏的信息，将光标移到高亮符号上并按 'K'
;;（非 evil 用户需按 'C-c c k'）。这将打开相关文档，包括使用示例。
;; 或者，使用 `C-h o' 查找符号（函数、变量、面等）。
;;
;; 你也可以尝试 'gd'（或 'C-c c d'）跳转到它们的定义并查看实现方式。
