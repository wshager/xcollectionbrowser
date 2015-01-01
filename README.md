xcollectionbrowser
==================

Standalone Collection Browser for eXist-db 2.2

To install in eXist-db:
--------------------

Download and install eXist-db 2.2 at http://exist-db.org

Build the package and install into eXist using the manager in the dashboard.

To test, point your browser to http://localhost:8080/exist/apps/collectionbrowser/

--------

If you want to use the collection browser from your app, add the dojo scripts and CSS to your page, and add this javascript snippet:

```javascript
require(["dexist/cb-layer"],function(){
		require(["dexist/CollectionBrowser"],function(CollectionBrowser){
			var cb = new CollectionBrowser({
			  target:"/exist/apps/collectionbrowser",// depending on your setup
        onSelectResource:function(id,item,evt){
          // use this method to determine what will happen when a document is selected (double-click)
        }
			});
			cb.placeAt("someDiv");
			cb.startup();
		});
});
```

*Important note*: currently you have to force Dojo locale to 'en-us' in Windows.

--------


New Features
==============

* Allows for sorting and paging of long lists.
* Editing ACL is fixed.
* You can embed the component anywhere.

This component is built as a single, self-contained Dojo Toolkit widget and communicates with the server along Dojo's JSON CRUD and RPC guidelines ([RST](https://github.com/lagua/xrst)).

TODO
=====

Add folder/file icons/preview.
