xcollectionbrowser
==================

Standalone Collection Browser for eXist-db 2.2

To install in eXist-db:
--------------------

Download and install eXist-db 2.2 at http://exist-db.org

Build the package and install into eXist using the manager in the dashboard.

To test, point your browser to http://localhost:8080/exist/apps/collectionbrowser/

--------

New Features
==============

The collection browser allows for sorting and paging of long lists. 

This component is built as a single, self-contained Dojo Toolkit widget and communicates with the server along Dojo's JSON CRUD and RPC guidelines ([RST](https://github.com/lagua/xrst)).

TODO
=====

There's still work to do on Uploading and storing ACL.
