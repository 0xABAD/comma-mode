;;; comma-mode.el --- A modal editing minor-mode for Emacs

;; Copyright (c) 2017 Dan Abad

;; Author: Dan Abad
;; Version: 1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: editing modal keys keybinding
;; URL: https://github.com/0xABAD/comma-mode


;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.



;; This file is NOT part GNU Emacs.



;;; Commentary:

;; Comma-mode is simple modal editing mode for Emacs.  It is designed to
;; more aligned with how Emacs does things as opposed to other modal editing
;; modes or editors.  Many of the same commands that are used within emacs
;; are defined within the comma-mode but don't require holding the control
;; key.  For example, you can type 'f' or 'b' with comma-mode active to
;; perform the same command that the default bindings or C-f and C-b are
;; bound to, which is move forward and backward a character.
;;
;; To automatically activate comma-mode when visiting various files,
;; add this to your init.el:
;;
;; (require 'comma-mode)
;;
;; (dolist (hook '(emacs-lisp-mode-hook
;;                 org-mode-hook
;;                 prog-mode-hook
;;                 text-mode-hook))
;;   (add-hook hook 'comma-mode))
;;
;; This will load and _activate_ comma-mode when visiting any elisp, org,
;; text, or source code program file.  Add any other major-mode hooks to
;; the that list to have comma-mode load when that major mode is activated.
;;
;; Optionally, and highly recommended, is to bind comma-mode to a key in
;; the keymap.  The preferred key is the comma key:
;;
;; (global-set-key (kbd "C-,") 'comma-mode)
;;
;; Hence, the name of this mode.  When comma-mode is active you will see
;; a ',' in the mode list of the status bar.
;;
;; When comma mode is active you primarily navigate the buffer with the
;; h, j, k, l, f, b, n, and p keys.  The h and l keys will move forward
;; and backward a word, while the j and k keys move forward and backward
;; a paragraph.  The f, b, n, and p keys move forward and backward a single
;; character or line.  This is basic idea of comma mode, to alleviate the
;; use of always using the control key to navigate a buffer.
;;
;; To exit out of comma mode you type either i, I, C-g, or ESC ESC ESC.  This
;; will put you into the default emacs state.
;;
;; The x and c keys in the comma-mode key map are reserved as 'prefix' keys
;; to bind any command within the comma-mode key map.  For example,
;;
;; (define-key comma-mode-map (kbd "c t") 'transpose-chars)
;;
;; will allow you to enter "ct" while comma-mode is active to transpose the
;; characters at the point.  You see all of comma-mode's default keybindings
;; at the bottom of this file.  Override any of these keybindings in your
;; init.el file.

(require 'seq)
(require 'rect)
(require 'subword)
(require 'paren)


(defvar comma-mode-map (make-keymap))
(defvar comma-mode-cursor 'box)
(defvar comma-mode-insert-cursor 'bar)


(defun comma-mode--toggle-cursor ()
  "Toggles the cursor depending on status of comma-mode."
  (if comma-mode
      (setq cursor-type comma-mode-cursor)
    (setq cursor-type comma-mode-insert-cursor)))

(defun comma-mode--post-command-hook ()
  "Post command hook to check if the user is trying to escape
out of comma-mode or if the command is `comma-mode'."
  (when (eq this-command 'keyboard-escape-quit)
    (comma-mode-disable)))

(defun comma-mode--minibuffer-setup-hook ()
  "Ensures that comma-mode keymap is disabled when in the minibuffer.
Without this hook there are instances when the comma-mode keymap is
still active upon entering the mini-buffer.  Note this is pretty
brute force and another non-intrusive should be investigated."
  (setq overriding-terminal-local-map nil))

;;;###autoload
(define-minor-mode comma-mode
  "A modal editing mode for emacs."
  :lighter " ,"
  :keymap comma-mode-map
  :after-hook
  (progn
    (comma-mode--toggle-cursor)
    (if comma-mode
        (setq-local comma-mode-exit-map
                    (set-transient-map comma-mode-map t))
      (when (boundp 'comma-mode-exit-map)
        (funcall comma-mode-exit-map)))))


(add-hook 'post-command-hook                'comma-mode--post-command-hook)
(add-hook 'buffer-list-update-hook          'comma-mode--toggle-cursor)
(add-hook 'window-configuration-change-hook 'comma-mode--toggle-cursor)
(add-hook 'minibuffer-setup-hook            'comma-mode--minibuffer-setup-hook)


(defun comma-mode-disable ()
  "Disables comma-mode and ensures that its keymap is disabled."
  (interactive)
  (when comma-mode
    (comma-mode -1)))


(defun comma-mode-list-buffers ()
  "Like `list-buffers' but also switches to that buffer."
  (interactive)
  (list-buffers)
  (switch-to-buffer-other-window "*Buffer List*"))


(defun comma-mode-join-line-above ()
  "Like `join-line' but joins the line below instead of above."
  (interactive)
  (next-line)
  (join-line))


(defun comma-mode-insert-newline-below ()
  "Inserts a new line at the end of the of the current line of
where the point is and moves the point to the beginning of that
new line."
  (interactive)
  (move-end-of-line nil)
  (newline)
  (comma-mode-disable))


(defun comma-mode-insert-newline-above ()
  "Inserts a new line directly above the line of where the point is
and moves the point to beginning of that line."
  (interactive)
  (move-beginning-of-line nil)
  (open-line 1)
  (comma-mode-disable))


(defun comma-mode-search-forward-char (arg ch &optional no-save-search)
  "Searches forward for character `ch' and places the point on the
first occurrence of that character.

If `no-save-search' is nil then this command and `ch' will
be saved to the buffer local variables `comma-mode--last-search-command'
and `comma-mode--last-search-char', respectively.  These stored variables
allow the commands `comma-mode-repeat' and `comma-mode-reverse-repeat' to
repeat forward and backward searches and reverse the search if the user
overshot the destination on continuous repeats."
  (interactive "p\nc")
  (forward-char 1)
  (let ((previous-setting case-fold-search))
    (setq case-fold-search nil)
    (when (not no-save-search)
      (setq-local comma-mode--last-search-command 'comma-mode-search-forward-char)
      (setq-local comma-mode--last-search-char ch))
    (search-forward (string ch) nil t arg)
    (setq case-fold-search previous-setting))
  (backward-char))


(defun comma-mode-search-backward-char (arg ch &optional no-save-search)
  "Searches backward for character `ch' and places the point on the
first occurrence of that character.

If `no-save-search' is non-nil then this command and `ch' will
be saved to the buffer local variables `comma-mode--last-search-command'
and `comma-mode--last-search-char', respectively.  These stored variables
allow the commands `comma-mode-repeat' and `comma-mode-reverse-repeat' to
repeat forward and backward searches and reverse the search if the user
overshot the destination on continuous repeats."
  (interactive "p\nc")
  (let ((previous-setting case-fold-search))
    (setq case-fold-search nil)
    (when (not no-save-search)
      (setq-local comma-mode--last-search-command 'comma-mode-search-backward-char)
      (setq-local comma-mode--last-search-char ch))
    (search-forward (string ch) nil t (- (prefix-numeric-value arg)))
    (setq case-fold-search previous-setting)))


(defun comma-mode-repeat (&optional arg)
  "Repeats the last search command made by either `comma-mode-search-forward-char'
or `comma-mode-search-backward-char'.  It will perform the last search command
`arg' times if given, otherwise it will search just once."
  (interactive "p")
  (when comma-mode--last-search-char
    (dotimes (n (if arg arg 1))
      (funcall comma-mode--last-search-command 1 comma-mode--last-search-char t))))


(defun comma-mode-reverse-repeat (&optional arg)
  "Reverses the last search command by either `comma-mode-search-forward-char'
or `comma-mode-search-backward-char'.  It will perform the last search command
`arg' times if given, otherwise it will search just once."
  (interactive "p")
  (when (and comma-mode--last-search-command
             comma-mode--last-search-char)
    (let ((fn (cond ((eq comma-mode--last-search-command 'comma-mode-search-forward-char)
                     'comma-mode-search-backward-char)
                    ((eq comma-mode--last-search-command 'comma-mode-search-backward-char)
                     'comma-mode-search-forward-char))))
      (dotimes (n (if arg arg 1))
        (funcall fn 1 comma-mode--last-search-char t)))))


(defun comma-mode-yo-yo ()
  "Bounce around between to matching delimiter pairs.  Similar to VI's '%'
operator."
  (interactive)
  ;; Trying to create or copy and existing syntax table that includes
  ;; all delimeters doesn't work right.  In many cases it does what is
  ;; expected but for others it doesn't match the correct delimeter.  For
  ;; example, suppose the current buffer is in c-mode and there is a series
  ;; of nested statements, such as
  ;;
  ;;     if (foo) {
  ;;         if (bar) {
  ;;              for (...) {
  ;;              }
  ;;         }
  ;;     }
  ;;
  ;; then attempting to yo-yo with copied yo-yo-syntax-table on the last
  ;; curly brace will cause the jump to go to one of the opening parenthesis.
  ;; I'm not sure why but using the current mode's syntax-table works just
  ;; fine.  Okay, for now, but limits the yo-yo command to balanced parens
  ;; in the buffers syntax-table.
  ;; 
  ;; (unless (boundp 'comma-mode-yo-yo-syntax-table)
  ;;   (setq-local comma-mode-yo-yo-syntax-table
  ;;               (make-syntax-table (syntax-table)))
  ;;   (with-syntax-table comma-mode-yo-yo-syntax-table
  ;;     (modify-syntax-entry ?\( "()")
  ;;     (modify-syntax-entry ?\) ")(")
  ;;     (modify-syntax-entry ?\{ "(}")
  ;;     (modify-syntax-entry ?\} "){")
  ;;     (modify-syntax-entry ?\[ "(]")
  ;;     (modify-syntax-entry ?\] ")[")
  ;;     (modify-syntax-entry ?\< "(>")
  ;;     (modify-syntax-entry ?\> ")<")))
  ;;  (with-syntax-table comma-mode-yo-yo-syntax-table
    (let* ((start (point))
           (class (char-syntax (char-after start))))
      (cond ((equal ?\( class) (progn (forward-sexp) (backward-char)))
            ((equal ?\) class) (progn (forward-char) (backward-sexp)))
            ((let* ((end (line-beginning-position)))
               (let* ((p  (or (search-backward "(" end t) end))
                      (a  (or (search-backward "[" end t) end))
                      (b  (or (search-backward "<" end t) end))
                      (c  (or (search-backward "{" end t) end))
                      (pos (max p a b c)))
                 (if (equal ?\( (char-syntax (char-after pos)))
                     (goto-char pos)
                   (move-beginning-of-line nil))
                 (when (equal start (point))
                   (move-end-of-line nil))))))))


(defun comma-mode-swapcase-char (&optional arg)
  "Swaps the case of the character at the point.

If `arg' is non-nil then this command will swapcase the next `arg'
characters."
  (interactive "p")
  (dotimes (_ (if arg arg 1))
    (let* ((ch (char-after (point)))
           (up (upcase ch)))
      (if (equal ch up)
          (insert (downcase ch))
        (insert up))
      (delete-char 1))))


(defmacro comma-mode-call (fn)
  `(lambda () (interactive) ,fn))


;; ====================> BEGIN COMMA-MODE KEYMAP DEFINITIONS <====================

(seq-doseq (ch "-_)([]{}<>\"\\',;.:=|?/+&*^%$#@!")
  (let ((str (string ch)))
    (define-key comma-mode-map (kbd str)
      `(lambda (arg)
         (interactive "p")
         (comma-mode-search-forward-char arg ,ch)))))

(define-key comma-mode-map [?0] 'digit-argument)
(define-key comma-mode-map [?1] 'digit-argument)
(define-key comma-mode-map [?2] 'digit-argument)
(define-key comma-mode-map [?3] 'digit-argument)
(define-key comma-mode-map [?4] 'digit-argument)
(define-key comma-mode-map [?5] 'digit-argument)
(define-key comma-mode-map [?6] 'digit-argument)
(define-key comma-mode-map [?7] 'digit-argument)
(define-key comma-mode-map [?8] 'digit-argument)
(define-key comma-mode-map [?9] 'digit-argument)

(define-key comma-mode-map (kbd "m")   'comma-mode-repeat)
(define-key comma-mode-map (kbd "M")   'comma-mode-reverse-repeat)
(define-key comma-mode-map (kbd "C-m") 'pop-tag-mark)
(define-key comma-mode-map (kbd "M-m") 'pop-global-mark)
(define-key comma-mode-map (kbd "X")   'execute-extended-command)
(define-key comma-mode-map (kbd "C-g") 'comma-mode-disable)
(define-key comma-mode-map (kbd "i")   'comma-mode-disable)
(define-key comma-mode-map (kbd "I")   (comma-mode-call (progn (forward-char) (comma-mode-disable))))
(define-key comma-mode-map (kbd "C-j") 'comma-mode-join-line-above)
(define-key comma-mode-map (kbd "M-j") 'join-line)
(define-key comma-mode-map (kbd "d")   'delete-char)
(define-key comma-mode-map (kbd "~")   'comma-mode-swapcase-char)
(define-key comma-mode-map (kbd "o")   'comma-mode-insert-newline-below)
(define-key comma-mode-map (kbd "O")   'comma-mode-insert-newline-above)
(define-key comma-mode-map (kbd "s")   'comma-mode-search-forward-char)
(define-key comma-mode-map (kbd "r")   'comma-mode-search-backward-char)
(define-key comma-mode-map (kbd "Y")   'comma-mode-yo-yo)
(define-key comma-mode-map (kbd "y")   'yank)
(define-key comma-mode-map (kbd "w")   'kill-region)

(define-key comma-mode-map (kbd "u")   'universal-argument)
(define-key comma-mode-map (kbd "SPC") 'set-mark-command)

(define-key comma-mode-map (kbd "f")   'forward-char)
(define-key comma-mode-map (kbd "b")   'backward-char)
(define-key comma-mode-map (kbd "a")   'move-beginning-of-line)
(define-key comma-mode-map (kbd "e")   'move-end-of-line)
(define-key comma-mode-map (kbd "h")   'backward-word)
(define-key comma-mode-map (kbd "H")   'backward-sexp)
(define-key comma-mode-map (kbd "M-h") 'subword-backward)
(define-key comma-mode-map (kbd "l")   'forward-word)
(define-key comma-mode-map (kbd "L")   'forward-sexp)
(define-key comma-mode-map (kbd "M-l") 'subword-forward)
(define-key comma-mode-map (kbd "j")   'forward-paragraph)
(define-key comma-mode-map (kbd "k")   'backward-paragraph)
(define-key comma-mode-map (kbd "J")   'end-of-defun)
(define-key comma-mode-map (kbd "K")   'beginning-of-defun)
(define-key comma-mode-map (kbd "n")   'next-line)
(define-key comma-mode-map (kbd "N")   'next-error)
(define-key comma-mode-map (kbd "p")   'previous-line)
(define-key comma-mode-map (kbd "P")   'previous-error)
(define-key comma-mode-map (kbd "v")   'down-list)
(define-key comma-mode-map (kbd "V")   'up-list)
(define-key comma-mode-map (kbd "z")   'repeat)

(define-key comma-mode-map (kbd "x e")     'eval-last-sexp)
(define-key comma-mode-map (kbd "x s")     'save-buffer)
(define-key comma-mode-map (kbd "x f")     'ido-find-file)
(define-key comma-mode-map (kbd "x d")     'ido-dired)
(define-key comma-mode-map (kbd "x z")     'repeat)
(define-key comma-mode-map (kbd "x k")     'ido-kill-buffer)
(define-key comma-mode-map (kbd "x b")     'ido-switch-buffer)
(define-key comma-mode-map (kbd "x SPC")   'rectangle-mark-mode)
(define-key comma-mode-map (kbd "x x")     'exchange-point-and-mark)
(define-key comma-mode-map (kbd "x u")     'upcase-region)
(define-key comma-mode-map (kbd "x l")     'downcase-region)
(define-key comma-mode-map (kbd "x t")     'transpose-lines)
(define-key comma-mode-map (kbd "x h")     'mark-whole-buffer)
(define-key comma-mode-map (kbd "x :")     'eval-expression)
(define-key comma-mode-map (kbd "x !")     'async-shell-command)
(define-key comma-mode-map (kbd "x ^")     'enlarge-window)
(define-key comma-mode-map (kbd "x }")     'enlarge-window-horizontally)
(define-key comma-mode-map (kbd "x {")     'shrink-window-horizontally)
(define-key comma-mode-map (kbd "x +")     'balance-windows)
(define-key comma-mode-map (kbd "x B")     'comma-mode-list-buffers)
(define-key comma-mode-map (kbd "x o")     'other-window)
(define-key comma-mode-map (kbd "x 0")     'delete-window)
(define-key comma-mode-map (kbd "x 1")     'delete-other-windows)
(define-key comma-mode-map (kbd "x 2")     'split-window-below)
(define-key comma-mode-map (kbd "x 3")     'split-window-right)
(define-key comma-mode-map (kbd "x 8")     'insert-char)
(define-key comma-mode-map (kbd "x 4 o")   'ido-display-buffer)
(define-key comma-mode-map (kbd "x 4 f")   'ido-find-file-other-window)
(define-key comma-mode-map (kbd "x 4 b")   'ido-switch-buffer-other-window)
(define-key comma-mode-map (kbd "x 4 0")   'kill-buffer-and-window)
(define-key comma-mode-map (kbd "x r l")   'bookmark-bmenu-list)
(define-key comma-mode-map (kbd "x r m")   'bookmark-set)
(define-key comma-mode-map (kbd "x r SPC") 'point-to-register)
(define-key comma-mode-map (kbd "x r j")   'jump-to-register)
(define-key comma-mode-map (kbd "x r s")   'copy-to-register)
(define-key comma-mode-map (kbd "x r i")   'insert-register)
(define-key comma-mode-map (kbd "x r r")   'copy-rectangle-to-register)
(define-key comma-mode-map (kbd "x r w")   'window-configuration-to-register)
(define-key comma-mode-map (kbd "x r f")   'frameset-to-register)
(define-key comma-mode-map (kbd "x r n")   'number-to-register)
(define-key comma-mode-map (kbd "x r +")   'increment-register)

(define-key comma-mode-map (kbd "c g")   'grep)
(define-key comma-mode-map (kbd "c o")   'occur)
(define-key comma-mode-map (kbd "c w")   'toggle-truncate-lines)
(define-key comma-mode-map (kbd "c a")   'align)
(define-key comma-mode-map (kbd "c r")   'align-regexp)
(define-key comma-mode-map (kbd "c c")   'comment-region)
(define-key comma-mode-map (kbd "c u")   'uncomment-region)
(define-key comma-mode-map (kbd "c q")   'self-send-quit-other-window)

;; ====================> END COMMA-MODE KEYMAP DEFINITIONS <====================

(provide 'comma-mode)
;;; comma-mode.el ends here

