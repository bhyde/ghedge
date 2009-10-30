(asdf:defsystem :ghedge
  :version "0.1"
  :serial t
  :depends-on (drakma cxml cl-ppcre fare-matcher)
  :components ((:file "packages")
	       (:file "utilities")))
