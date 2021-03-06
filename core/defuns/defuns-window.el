;;; defuns-window.el --- library for acting on windows

;;;###autoload
(defun doom*evil-window-split (orig-fn &rest args)
  (interactive)
  (doom/neotree-save
   (apply orig-fn args)
   (evil-window-down 1)))

;;;###autoload
(defun doom*evil-window-vsplit (orig-fn &rest args)
  (interactive)
  (doom/neotree-save
   (apply orig-fn args)
   (evil-window-right 1)))

;;;###autoload
(defun doom/evil-window-move (direction)
  "Move current window to the next window in DIRECTION. If there are no windows
there and there is only one window, split in that direction and place this
window there. If there are no windows and this isn't the only window, use
evil-window-move-* (e.g. `evil-window-move-far-left')"
  (let* ((this-window (get-buffer-window))
         (this-buffer (current-buffer))
         (that-window (windmove-find-other-window direction nil this-window))
         (that-buffer (window-buffer that-window)))
    (when (or (minibufferp that-buffer)
              (doom/popup-p that-window))
      (setq that-buffer nil that-window nil))
    (if (not (or that-window (one-window-p t)))
        (funcall (case direction
                   ('left 'evil-window-move-far-left)
                   ('right 'evil-window-move-far-right)
                   ('up 'evil-window-move-very-top)
                   ('down 'evil-window-move-very-bottom)))
      (unless that-window
        (setq that-window
              (split-window this-window nil (cond ((eq direction 'up) 'above)
                                                  ((eq direction 'down) 'below)
                                                  (t direction))))
        (with-selected-window that-window
          (switch-to-buffer doom-buffer))
        (setq that-buffer (window-buffer that-window)))
      (with-selected-window this-window
        (switch-to-buffer that-buffer))
      (with-selected-window that-window
        (switch-to-buffer this-buffer))
      (select-window that-window))))

;;;###autoload
(defun doom/evil-window-move-l () (interactive) (doom/evil-window-move 'left))
;;;###autoload
(defun doom/evil-window-move-d () (interactive) (doom/evil-window-move 'down))
;;;###autoload
(defun doom/evil-window-move-u () (interactive) (doom/evil-window-move 'up))
;;;###autoload
(defun doom/evil-window-move-r () (interactive) (doom/evil-window-move 'right))

;;;###autoload
(defun doom/new-buffer ()
  (interactive)
  (switch-to-buffer (generate-new-buffer "*new*")))

;;;###autoload
(defun doom/new-frame ()
  (interactive)
  (let ((nlinum-p (and (featurep 'nlinum)
                       (memq 'nlinum--setup-window window-configuration-change-hook))))
    ;; Disable nlinum to fix elusive "invalid face linum" bug
    (remove-hook 'window-configuration-change-hook 'nlinum--setup-window t)
    (let ((frame (new-frame))
          (frame-name (format "*new-%s*" (length doom-wg-frames))))
      (with-selected-frame frame
        (wg-create-workgroup frame-name t)
        (add-to-list 'doom-wg-frames (cons frame frame-name))))
    (when nlinum-p
      (add-hook 'window-configuration-change-hook 'nlinum--setup-window nil t))))

;;;###autoload
(defun doom/close-frame ()
  (interactive)
  (let ((frame (assq (selected-frame) doom-wg-frames)))
    (if frame
        (progn (wg-delete-workgroup (wg-get-workgroup (cdr frame)))
               (delete-frame (car frame)))
      (delete-frame))))

;;;###autoload
(defun doom/evil-window-resize (direction &optional count)
  (interactive)
  (let ((count (or count 1))
        (next-window (window-in-direction direction)))
    (when (or (not next-window) (not (doom/real-buffer-p (window-buffer next-window))))
      (setq count (- count)))
    (cond ((memq direction '(left right))
           (evil-window-increase-width count))
          ((memq direction '(above below))
           (evil-window-increase-height count)))))

;;;###autoload (autoload 'doom/evil-window-resize-r "defuns-window" nil t)
(evil-define-command doom/evil-window-resize-r (&optional count)
  (interactive "<c>") (doom/evil-window-resize 'right count))
;;;###autoload (autoload 'doom/evil-window-resize-l "defuns-window" nil t)
(evil-define-command doom/evil-window-resize-l (&optional count)
  (interactive "<c>") (doom/evil-window-resize 'left count))
;;;###autoload (autoload 'doom/evil-window-resize-u "defuns-window" nil t)
(evil-define-command doom/evil-window-resize-u (&optional count)
  :repeat nil
  (interactive "<c>") (doom/evil-window-resize 'above count))
;;;###autoload (autoload 'doom/evil-window-resize-d "defuns-window" nil t)
(evil-define-command doom/evil-window-resize-d (&optional count)
  (interactive "<c>") (doom/evil-window-resize 'below count))

;;;###autoload
(defun doom/window-reorient ()
  "Reorient all windows that are scrolled to the right."
  (interactive)
  (let ((i 0))
    (mapc (lambda (w)
            (with-selected-window w
              (when (> (window-hscroll) 0)
                (cl-incf i)
                (evil-beginning-of-line))))
          (doom/get-visible-windows))
    (message "Reoriented %s windows" i)))

(provide 'defuns-window)
;;; defuns-window.el ends here
