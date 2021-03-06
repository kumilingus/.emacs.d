;;; defuns-popups.el

(defvar doom-last-popup nil
  "The last popup buffer open (or group thereof).")

(defvar-local doom-popup-rule nil
  "A list of rules applied to this popup.")

(defvar doom-popup-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap doom/kill-real-buffer] 'doom/popup-close)
    (define-key map [remap evil-window-delete]    'doom/popup-close)
    (define-key map [remap evil-window-move-very-bottom] 'ignore)
    (define-key map [remap evil-window-move-very-top]    'ignore)
    (define-key map [remap evil-window-move-far-left]    'ignore)
    (define-key map [remap evil-window-move-far-right]   'ignore)
    (define-key map [remap evil-window-split]  'ignore)
    (define-key map [remap evil-window-vsplit] 'ignore)
    (define-key map [remap evil-force-normal-state] 'doom/popup-close-maybe)
    (define-key map [escape] 'doom/popup-close-maybe)
    (define-key map (kbd "ESC") 'doom/popup-close-maybe)
    map)
   "Active keymap in popup windows.")

;;;###autoload
(define-minor-mode doom-popup-mode
  "Minor mode for pop-up windows. Enables local keymaps and sets state
variables."
  :global nil
  :init-value nil
  :keymap doom-popup-mode-map
  (let ((rules (--any (let ((key (car it)))
                        (when (cond ((symbolp key)
                                     (or (eq major-mode key)
                                         (derived-mode-p key)))
                                    ((stringp key)
                                     (string-match-p key (buffer-name))))
                          (cdr it)))
                      doom-popup-rules)))
    (set-window-dedicated-p nil doom-popup-mode)
    (setq doom-last-popup (current-buffer))
    (setq-local doom-popup-rule rules)))
(put 'doom-popup-mode 'permanent-local t)

;;;###autoload
(defun doom*popup-window-move (orig-fn &rest args)
  (unless (doom/popup-p)
    (apply orig-fn args)))

;;;###autoload
(defun doom/popup-p (&optional window)
  "Whether WINDOW is a popup window or not. If WINDOW is nil, use current
window. Returns nil or the popup window."
  (setq window (or window (selected-window)))
  (and (window-live-p window)
       (buffer-local-value 'doom-popup-mode (window-buffer window))
       window))

;;;###autoload
(defun doom/popups-p ()
  "Whether there is a popup window open and alive somewhere."
  (and doom-last-popup (window-live-p (get-buffer-window doom-last-popup))))

;;;###autoload
(defmacro doom/popup-save (&rest body)
  "Close popups before BODY and restore them afterwards."
  `(let ((popup-p (doom/popups-p))
         (in-popup-p (doom/popup-p)))
     (when popup-p
       (doom/popup-close-all t)
       (doom/popup-close nil t))
     (prog1
         ,@body
       (when popup-p
         (let ((origin-win (selected-window)))
           (doom/popup-last-buffer)
           (when in-popup-p
             (select-window origin-win)))))))

;;;###autoload
(defun doom/popup-buffer (buffer &optional plist)
  "Display BUFFER in a shackle popup."
  (let* ((buffer-name (cond ((stringp buffer) buffer)
                            ((bufferp buffer) (buffer-name buffer))
                            (t (error "Not a valid buffer"))))
         (buffer (get-buffer-create buffer-name)))
    (shackle-display-buffer
     buffer
     nil (or plist (shackle-match buffer-name)))))

;;;###autoload
(defun doom/popup-close (&optional window dont-kill)
  "Find and close the currently active popup (if available)."
  (interactive)
  (setq window (or window (selected-window)))
  (when (doom/popup-p window)
    (with-selected-window window
      ;; If REPL...
      (when (bound-and-true-p repl-toggle-mode)
        (setq rtog/--last-buffer nil))
      (doom-popup-mode -1)
      (unless (or dont-kill (memq :nokill doom-popup-rule))
        (let ((kill-buffer-query-functions
               (delq 'process-kill-buffer-query-function
                     kill-buffer-query-functions)))
          (kill-buffer (window-buffer window)))))
    (delete-window window)))

;;;###autoload
(defun doom/popup-close-maybe ()
  "Close the current popup *if* its buffer doesn't have a :noesc rule in
`doom-popup-rules'."
  (interactive)
  (if (memq :noesc doom-popup-rule)
      (call-interactively 'evil-force-normal-state)
    (doom/popup-close)))

;;;###autoload
(defun doom/popup-close-all (&optional dont-kill)
  "Closes all popups (kill them if DONT-KILL-BUFFERS is non-nil)."
  (interactive)
  (let ((orig-win (selected-window)))
    (mapc (lambda (w) (doom/popup-close w dont-kill))
          (--filter (and (doom/popup-p it) (not (eq it orig-win)))
                    (window-list)))))

;;;###autoload
(defun doom/popup-last-buffer ()
  "Restore the last popup."
  (interactive)
  (unless (buffer-live-p doom-last-popup)
    (setq doom-last-popup nil)
    (error "No popup to restore"))
  (doom/popup-buffer doom-last-popup))

;;;###autoload
(defun doom/popup-messages ()
  "Pop up the messages buffer."
  (interactive)
  (doom/popup-buffer (messages-buffer))
  (goto-char (point-max)))

;;;###autoload
(defun doom*popup-init (orig-fn &rest args)
  "Enables `doom-popup-mode' in every popup window and returns the window."
  (let ((window (apply orig-fn args)))
    (with-selected-window window
      (doom-popup-mode +1))
    ;; NOTE orig-fn returns a window, so `doom*popup-init' must too
    window))

;;;###autoload
(defun doom*save-popup (orig-fun &rest args)
  "Prevents messing up a popup buffer on window changes"
  (doom/popup-save (apply orig-fun args)))

(provide 'defuns-popups)
;;; defuns-popups.el ends here
