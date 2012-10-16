;;; past.el --- paste server with elnode

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: hypermedia

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A pastebin with Elnode.

;;; Code:

(elnode-app pasteel/dir elnode esxml creole uuid)

(defconst pasteel-store-dir "/tmp/pasteel")

(defun pasteel-paste (httpcon)
  "Serve a paste."
  (let ((creole-text
         (with-current-buffer
             (find-file-noselect
              (concat
               (file-name-as-directory pasteel-store-dir)
               (elnode-http-mapping httpcon 1)))
           (buffer-substring-no-properties (point-min)(point-max)))))
    (elnode-http-start httpcon 200 '(content-type . "text/html"))
    (with-stdout-to-elnode httpcon
        (creole-wiki
         creole-text
         :destination t
         :body-header "<h1>Your paste</h1>"
         :css (concat pasteel/dir "pasteel.css")))))

(defun pasteel-bin (httpcon)
  (elnode-method httpcon
    (GET
     (elnode-send-file httpcon (concat pasteel/dir "pasteel.html")))
    (POST
     (let* ((text (elnode-http-param httpcon "text"))
            (type (elnode-http-param httpcon "type"))
            (uuid (uuid-string))
            (file (concat (file-name-as-directory pasteel-store-dir) uuid))
            ;; This could be useful for ensuring we don't repeat pastes?
            (mac (base64-encode-string
                  (hmac-sha1
                   "test"
                   (base64-encode-string text))))
            (creole-text
             (format
              "\n{{{\n##! %s\n%s\n}}}\n"
              type
              text)))
       (unless (file-exists-p pasteel-store-dir)
         (make-directory pasteel-store-dir t))
       (with-temp-file file (insert creole-text))
       (elnode-send-redirect httpcon (concat "/pasteel/" uuid))))))

(defun pasteel-handler (httpcon)
  (elnode-hostpath-dispatcher
   httpcon
   `(("^[^/]*//pasteel.css$"
      . ,(elnode-make-send-file (concat pasteel/dir "pasteel.css")))
     ("^[^/]*//pasteel/\\([^/]+\\)$" . pasteel-paste)
     ("^[^/]*/.*" . pasteel-bin))))

(provide 'pasteel)

;;; past.el ends here
