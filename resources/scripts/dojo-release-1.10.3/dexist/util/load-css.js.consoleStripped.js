define("dexist/util/load-css", ["dojo/query"],function(query){
	return function(path,doc) {
		 0 && console.debug("loadCSS",path);
		doc = doc || document;
		//todo: check this code - still needed?
		var head = doc.getElementsByTagName("head")[0];
		var exists = query("link", head).some(function(elem) {
			var href = elem.getAttribute("href");
			return href === path;
		});
		 0 && console.log(exists)
		var link = document.createElement("link");
		link.setAttribute("rel", "stylesheet");
		link.setAttribute("type", "text/css");
		link.setAttribute("href", path);
		head.appendChild(link);
	}
});