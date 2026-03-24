;;; init.el -*- lexical-binding: t; -*-

;; 此文件控制启用哪些 Doom 模块以及它们的加载顺序。修改后请记住运行 'doom sync'！

;; 注意：按 'SPC h d h'（非 vim 用户按 'C-h d h'）访问 Doom 的文档。
;;      在那里你会找到 Doom 模块索引的链接，其中列出了我们所有的模块，包括它们支持的标志。

;; 注意：将光标移到模块名称（或其标志）上，按 'K'（非 vim 用户按 'C-c c k'）查看其文档。
;;      这也适用于标志（那些以加号开头的符号）。
;;
;;      或者，在模块上按 'gd'（或 'C-c c d'）浏览其目录（便于访问其源代码）。

(doom! :input
       ;;bidi              ; 帮你从右往左写（倒写注释）
       ;;chinese           ; 中文输入支持
       ;;japanese          ; 日文输入支持
       ;;layout            ; auie,ctsrnm 是更优的主行键位（替代键盘布局）

       :completion
       ;;company           ; 代码补全终极后端
       (corfu +orderless)  ; 用 cap(f)、cape 和飞翔的羽毛完成补全！
       ;;helm              ; 用于热爱与生活的*另一种*搜索引擎
       ;;ido               ; 另一种*另一种*搜索引擎...
       ;;ivy               ; 用于热爱与生活的搜索引擎
       vertico           ; 未来的搜索引擎

       :ui
       ;;deft              ; Emacs 的 Notational Velocity（快速笔记）
       doom              ; 让 DOOM 呈现当前外观的核心
       doom-dashboard    ; Emacs 的精美启动画面
       ;;doom-quit         ; 退出 Emacs 时的 DOOM 退出消息提示
       ;;(emoji +unicode)  ; 🙂
       hl-todo           ; 高亮 TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       ;;indent-guides     ; 高亮缩进列
       ;;ligatures         ; 连字和符号，让你的代码再次美观
       ;;minimap           ; 在侧边显示代码缩略图
       modeline          ; 时髦的、受 Atom 启发的状态栏，外加 API
       ;;nav-flash         ; 大幅移动后闪烁光标所在行
       ;;neotree           ; 项目文件树，类似 vim 的 NERDTree
       ophints           ; 高亮操作所作用的区域
       (popup +defaults) ; 驯服突然却不可避免的临时窗口
       ;;smooth-scroll     ; 如此顺滑，你会不相信它不是黄油
       ;;tabs              ; Emacs 的标签栏
       ;;treemacs          ; 项目文件树，类似 neotree 但更酷
       ;;unicode           ; 为各种语言提供扩展的 Unicode 支持
       (vc-gutter +pretty) ; 在边缘显示版本控制差异
       vi-tilde-fringe   ; 用边缘波浪号标记文件末尾之后
       ;;window-select     ; 可视化切换窗口
       workspaces        ; 标签页模拟、持久化和独立工作区
       zen               ; 无干扰的编程或写作

       :editor
       (evil +everywhere); 加入黑暗面，我们有饼干
       file-templates    ; 空文件的自动代码片段
       fold              ; （几乎）通用的代码折叠
       ;;god               ; 无需修饰键即可运行 Emacs 命令
       ;;
       ;;lispy             ; 给不喜欢 vim 的人用的 lisp 版 vim
       ;;multiple-cursors  ; 同时在多处编辑
       ;;objed             ; 为单纯者提供的文本对象编辑
       ;;parinfer          ; 某种程度上把 lisp 变成 python
       ;;rotate-text       ; 在光标处的文本候选间循环切换
       snippets          ; 我的小精灵。它们替我打字，这样我就不用打了
       (whitespace +guess +trim) ; 你的空白字符管家
       ;;word-wrap         ; 带语言感知缩进的软换行

       :emacs
       dired +icons +dirvish            ; 让 dired 美观[实用]
       electric          ; 更智能的、基于关键字的自动缩进
       ;;eww               ; 互联网很糟糕（浏览器）
       ;;ibuffer           ; 交互式缓冲区管理
       tramp             ; 在你关节炎的手指间轻松处理远程文件
       undo              ; 为你 inevitable 的错误提供持久、更智能的撤销
       vc                ; 版本控制与 Emacs，坐在树上

       :term
       ;;eshell            ; 随处可用的 elisp shell
       ;;shell             ; Emacs 的简单 shell REPL
       ;;term              ; Emacs 的基础终端模拟器
       vterm             ; Emacs 中最好的终端模拟

       :checkers
       syntax            ; 为你忘记的每个分号而电击你
       ;;(spell +flyspell) ; 为你拼写错误而电击你（注意 mispelling 本身就是拼写错误）
       ;;grammar           ; 为你犯的每个语法错误而电击你

       :tools
       ;;ansible           ; 配置管理工具
       ;;biblio            ; 为你写博士论文（需要引用）
       ;;collab            ; 与朋友共享缓冲区
       ;;debugger          ; FIXME 逐步调试代码，帮你添加 bug
       ;;direnv            ; 环境变量管理
       ;;docker            ; 容器化平台
       ;;editorconfig      ; 让别人去争论制表符 vs 空格
       ;;ein               ; 用 Emacs 驯服 Jupyter 笔记本
       (eval +overlay)   ; 运行代码，运行（还有 REPL）
       lookup            ; 导航你的代码及其文档
       ;;llm               ; 当我说你需要朋友时，我不是指...
       ;;(lsp +eglot)      ; M-x vscode
       magit             ; Emacs 的 git 瓷器（界面）
       ;;make              ; 从 Emacs 运行 make 任务
       ;;pass              ; 极客密码管理器
       ;;pdf               ; PDF 增强
       ;;terraform         ; 基础设施即代码
       ;;tmux              ; 与 tmux 交互的 API
       ;;tree-sitter       ; 语法和解析，坐在树上...
       ;;upload            ; 通过 ssh/ftp 将本地映射到远程项目

       :os
       (:if (featurep :system 'macos) macos)  ; 改善与 macOS 的兼容性
       ;;tty               ; 改善终端 Emacs 体验

       :lang
       ;;ada               ; 我们（盲目地）信任强类型
       ;;agda              ; 类型的类型的类型的类型...
       ;;beancount         ; 注意 GAAP（一般公认会计原则）
       (cc +lsp)         ; C 大于 C++ 等于 1
       ;;clojure           ; 带 lisp 的 java
       ;;common-lisp       ; 如果你见过一种 lisp，你就见过它们所有
       ;;coq               ; 证明即程序
       ;;crystal           ; 以 C 的速度运行的 ruby
       ;;csharp            ; unity、.NET 和 mono 的恶作剧
       ;;data              ; 配置/数据格式
       ;;(dart +flutter)   ; 绘制 UI，别的就不太行了
       ;;dhall             ; 配置语言
       ;;elixir            ; 正确实现的 erlang
       ;;elm               ; 想来杯 TEA 吗？（The Elm Architecture）
       emacs-lisp        ; 淹没在括号中
       ;;erlang            ; 更文明时代的优雅语言
       ;;ess               ; Emacs 说统计
       ;;factor            ; 编程语言
       ;;faust             ; 数字信号处理，但你保住了灵魂
       ;;fortran           ; 在 FORTRAN 中，上帝是真实的（除非声明为 INTEGER）
       ;;fsharp            ; ML 代表微软的语言（误）
       ;;fstar             ; （依赖）类型和（单子）效应和 Z3
       ;;gdscript          ; 你等待的语言
       (go +lsp)         ; 潮人方言
       ;;(graphql +lsp)    ; 让查询休息一下（双关：REST）
       ;;(haskell +lsp)    ; 比我更懒的语言
       ;;hy                ; scheme 的可读性 + python 的速度
       ;;idris             ; 你可以依赖的语言（双关：依赖类型）
       ;;json              ; 至少它不是 XML
       ;;janet             ; 有趣的事实：Janet 就是我！
       ;;(java +lsp)       ; 腕管综合征的典型代表
       ;;javascript        ; 一切希望（抛弃（你们（进入（这里）的）））（但丁《神曲》）
       ;;julia             ; 更好更快的 MATLAB
       ;;kotlin            ; 更好更顺滑的 Java(Script)
       ;;latex             ; 在 Emacs 中写论文从未如此有趣
       ;;lean              ; 给有太多东西要证明的人
       ;;ledger            ; 尽你所能审计（双关）
       ;;lua               ; 基于 1 的索引？基于 1 的索引（吐槽）
       markdown          ; 写文档给人们忽略
       ;;nim               ; python + lisp，以 C 的速度
       ;;nix               ; 我在此宣布"到此为止"！（德语谐音梗）
       ;;ocaml             ; 客观骆驼（双关：Object Caml）
       (org +roam2 +dragndrop +pretty) ; 用纯文本组织你的平凡生活
       ;;php               ; perl 的不安全弟弟
       ;;plantuml          ; 让人更困惑的图表
       ;;graphviz          ; 让你自己更困惑的图表
       ;;purescript        ; javascript，但是函数式
       ;;python            ; 美胜于丑（Python 之禅）
       ;;qt                ; 有史以来'最可爱'的 GUI 框架（谐音 cute）
       ;;racket            ; DSL 的 DSL
       ;;raku              ; 以前叫 perl6 的艺术家
       ;;rest              ; Emacs 作为 REST 客户端
       ;;rst               ; 安息吧（双关：ReStructuredText）
       ;;(ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       (rust +lsp)       ; Fe2O3.unwrap().unwrap().unwrap().unwrap()（不断解包）
       ;;scala             ; java，但是好
       ;;(scheme +guile)   ; 一个完全密谋的 lisp 家族
       sh                ; 她在 C 异或上卖 {ba,z,fi}sh 壳（双关：海贝壳）
       ;;sml               ; 标准 ML
       ;;solidity          ; 你需要区块链吗？不需要。
       ;;swift             ; 谁要表情符号变量了？
       ;;terra             ; 地球与月球对齐以获得性能
       ;;web               ; 管道（互联网）
       ;;yaml              ; JSON，但是可读
       ;;zig               ; C，但是更简单

       :email
       ;;(mu4e +org +gmail)
       ;;notmuch
       ;;(wanderlust +gmail)

       :app
       ;;calendar
       ;;emms              ; Emacs 多媒体系统
       ;;everywhere        ; *离开* Emacs！？你一定在开玩笑
       ;;irc               ; 极客如何社交
       ;;(rss +org)        ; Emacs 作为 RSS 阅读器

       :config
       ;;literate          ; 文学编程
       (default +bindings +smartparens))
