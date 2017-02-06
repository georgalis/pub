;; ~/.emacs

;;(load "~/.emacs.local") ; this lines points emacs to local user configurations
(load "/usr/pkg/share/emacs/site-lisp/ess/ess-site.el")
(setq comint-scroll-to-bottom-on-output t) ; this line tells R to automatically scroll  the buffer after commands are executed
(setq column-number-mode t); automatically display column numbers
;;Allows svn usage from emacs
;;(require 'psvn)
;; Enable backup files.
;;(setq make-backup-files t)
;; Save all backup file in this directory.
;;(setq backup-directory-alist (quote ((".*" . "~/.emacs.tmp/"))))

;;Highlight function stuff
(global-font-lock-mode 1)
(setq show-paren-mode t )
(setq transient-mark-mode t)

