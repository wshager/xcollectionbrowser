xcollectionbrowser
==================

Standalone Collection Browser for eXist-db 2.2

To install in eXist-db:
--------------------

Download and install eXist-db 2.2 at http://exist-db.org

Build the package and install into eXist using the manager in the dashboard.

To test, point your browser to http://localhost:8080/exist/apps/collectionbrowser/

--------

If you want to use the collection browser from your app, add the dojo scripts and CSS to your page, where 'resources' should be replaced with the path to /exist/apps/collectionbrowser/resources from your current setup, and 'claro' may be replaced with the theme of your choice:
```html
<link rel="stylesheet" href="resources/scripts/dojo-release-1.10.3/dojo/resources/dojo.css"/>
<link rel="stylesheet" href="resources/scripts/dojo-release-1.10.3/dijit/themes/claro/claro.css"/>
<link rel="stylesheet" href="resources/scripts/dojo-release-1.10.3/dgrid/css/skins/claro.css"/>
<script src="resources/scripts/dojo-release-1.10.3/dojo/dojo.js" data-dojo-config="async:true,locale:'en-us'"/>
```
Then add this javascript snippet:

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
Note that the dijit theme class also needs to be set on the HTML body element.

You may want to place the widget in a dialog, e.g. a dijit [Dialog](http://dojotoolkit.org/reference-guide/dijit/Dialog.html).

**Important note**: currently you have to force Dojo locale to a region code (e.g. 'en-us') in Windows.

**You can find the source code for the client and its API on https://github.com/wshager/dexist. Please report client issues there as well.**

--------

### Thumbnails
Image previews will be shown for files smaller then 512kb. If you have large images in a collection, you can easily create thumbnails for that collection using the xquery image module. The thumbnails will be read from a .thumbs subcollection, while that collection itself will not be shown in the browser. To create thumbnails in xquery:

```xquery
declare namespace image="http://exist-db.org/xquery/image";

image:thumbnail("/db/my/images", ".thumbs", (), ())
```
Note that the image module must be enabled in your conf.xml.

-------

New Features
==============

* Allows for sorting and paging of long lists.
* Editing ACL is fixed.
* You can embed the component anywhere.
* Remember last visited collection and preferences
* Icons / image preview
* Display as tiles

This component is built as a single, self-contained Dojo Toolkit widget and communicates with the server along Dojo's JSON CRUD and RPC guidelines ([RST](https://github.com/lagua/xrst)).
