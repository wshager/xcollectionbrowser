define("dexist/CollectionBrowser", [
	"dojo/_base/declare",
	"dojo/_base/lang",
	"dojo/_base/array",
	"dojo/has",
	"dojo/dom",
	"dojo/dom-construct",
	"dojo/dom-style",
	"dojo/dom-geometry",
	"dojo/dom-form",
	"dojo/on",
	"dojo/query",
	"dojo/request",
	"dojo/data/ObjectStore",
	"dstore/Memory",
	"dstore/Cache",
	"dstore/Rest",
	"dijit/registry",
	"dijit/layout/ContentPane",
	"dijit/layout/LayoutContainer",
	"dijit/layout/StackContainer",
	"dijit/Toolbar",
	"dijit/Dialog",
	"dijit/form/Button",
	"dijit/form/CheckBox",
	"dijit/form/Select",
	"dgrid/OnDemandGrid",
	"dgrid/Editor",
	"dgrid/Keyboard",
	"dgrid/Selection",
	"dgrid/extensions/DijitRegistry",
	"dforma/Builder",
	"dojo/_base/sniff"
],
	function(declare, lang, array, has, dom, domConstruct, domStyle, domGeometry, domForm, 
			on, query, request, ObjectStore, Memory, Cache, Rest, 
			registry, ContentPane, LayoutContainer, StackContainer, Toolbar, Dialog, Button, CheckBox, Select,  
			OnDemandGrid, Editor, Keyboard, Selection, DijitRegistry, Builder) {
		
		var util = {
			confirm: function(title, message, callback) {
				// console.debug("create new Dialog");
				var callbackToExecute = callback;
				var dialog = new Dialog({
					title: title
				});
				var div = domConstruct.create('div', { style: 'width: 400px;' }, dialog.containerNode, "last");
				var msg = domConstruct.create("p", { innerHTML: message });
				div.appendChild(msg);
				var okButton = new Button({
					label: "Yes"
				});
				on(okButton, "click", lang.hitch(this, function() {
					console.debug("execute callback and hide dialog") ;
					dialog.hide();
					//dialog.destroyRecursive();
					callbackToExecute();
				}));
				div.appendChild(okButton.domNode);
	
				var cancelButton = new Button({
					label: "No"
				});
				on(cancelButton, "click", lang.hitch(this, function() {
					console.debug("do nothing, simply hide dialog") ;
					dialog.hide();
					// dialog.destroyRecursive();
				}));
				div.appendChild(cancelButton.domNode);
				dialog.show();
			},
	
			message: function(title, message, label, callback) {
				if (!label || typeof label == "function") {
					callback = label;
					label = "Close";
				}
				var dialog = new Dialog({
					title: title
				});
				on(dialog, "hide", function(ev) {
					dialog.destroyRecursive();
					if (callback) {
						callback();
					}
				});
				var div = domConstruct.create('div', {
					style: 'width: 400px;'
				}, dialog.containerNode, "last");
				var msg = domConstruct.create("div", {
					innerHTML: message
				});
				div.appendChild(msg);
				var closeButton = new Button({
					label: label,
					onClick: function() {
						dialog.hide();
					}
				});
				div.appendChild(closeButton.domNode);
				dialog.show();
			},
	
			input: function(title, message, controls, callback) {
				var dialog = new Dialog({
					title: title
				});
				var div = domConstruct.create('div', {
					style: 'width: 400px;'
				}, dialog.containerNode, "last");
				var msg = domConstruct.create("p", {
					innerHTML: message
				});
				div.appendChild(msg);
				var form = domConstruct.create("form", {
					innerHTML: controls
				}, div, "last");
				var closeButton = new Button({
					label: "Cancel",
					onClick: function() {
						dialog.hide();
						dialog.destroyRecursive();
					}
				});
				div.appendChild(closeButton.domNode);
				var okButton = new Button({
					label: "Ok",
					onClick: function() {
						dialog.hide();
						dialog.destroyRecursive();
						var value = domForm.toObject(form);
						callback(value);
					}
				});
				div.appendChild(okButton.domNode);
				dialog.show();
			}
		};
		
		var selection;
		
		return declare("dexist.CollectionBrowser", [StackContainer], {
			store: null,
			grid: null,
			target:"db/",
			collection: "/db",
			clipboard: null,
			clipboardCut: false,
			editor: null,
			tools:null,
			baseClass:"dexistCollectionBrowser",
			updateBreadcrumb:function() {
				var self = this;
				this.breadcrumb.innerHTML = "";
				array.forEach(this.collection.split("/"),function(part,i,parts){
					if(!part) return;
					domConstruct.create("a",{
						innerHTML:part,
						target: parts.slice(0,i+1).join("/"),
						onclick:function(){
							self.refresh(this.target);
						}
					},this.breadcrumb);
				},this);
			},
			startup: function() {
				if(this._started) return;
				var self = this;
				
				this.loadCSS(require.toUrl("dexist/resources/CollectionBrowser.css"));
				
				this.browsingPage = new LayoutContainer({
				});
				this.propertiesPage = new ContentPane({
				});
				this.browsingTop = new ContentPane({
					region:"top"
				});
				this.browsingPage.addChild(this.browsingTop);
				this.toolbar = new Toolbar();
				this.browsingTop.addChild(this.toolbar);
				this.breadcrumb = domConstruct.create("div",{
					"class":"dexistBreadCrumb"
				},this.browsingTop.domNode,"last");
				this.updateBreadcrumb();
				// json data store
				this.store = new Rest({
					useRangeHeaders:true,
					target:this.target,
					rpc:function(id,method,params,callId){
						var callId = callId || "call-id";
						return request.post(this.target+id,{
							data:JSON.stringify({
								method:method,
								params:params,
								id:callId
							}),
							handleAs:"json",
							headers:{
								"Content-Type":"application/json",
								"Accept":"application/json"
							}
						});
					}
				});

				this.grid = new (declare([OnDemandGrid, Keyboard, Selection, Editor, DijitRegistry]))({
					region:"center",
					id:"browsingGrid",
					collection: this.store.filter({collection:this.collection}),
					columns: [{
						label: "Name",
						field: "name",
						editor: "text",
						editOn: "click",
						canEdit: function(item, value){
							return value != "..";
						}
					},{
						label: "Permissions",
						field: "permissionsString"
					},{
						label: "Owner",
						field: "owner"
					},{
						label: "Group",
						field: "group"
					},{
						label: "Last-modified",
						field: "lastModified"
					}]
				});
				this.browsingPage.addChild(this.grid);
				this.grid.on('dgrid-refresh-complete',lang.hitch(this,function() {
					this.resize();
					var p = dijit.getEnclosingWidget(this.domNode.parentNode);
					if(p) p.resize();
				}));						
				this.grid.on(".dgrid-row:dblclick", lang.hitch(this,function(ev) {
					var row = this.grid.row(ev);
					var item = row.data;
					if(item.isCollection) {
						this.collection = "/db/"+item.id;
						// console.debug("collection: ", this.collection);
						this.updateBreadcrumb();
						this.grid.set("collection",this.store.filter({collection:this.collection}));
					} else {
						if(ev.altKey) {
							this.openResource(item.id);
						} else {
							this.onSelectResource(item.id,item);
						}
					}
				}));
				this.grid.on("dgrid-select", function(ev){
					selection = array.map(ev.rows,function(_){
						return _.data;
					});
				});
				/*on(this.grid, "keyUp", function(e) {
					if (self.grid.edit.isEditing()) {
						return;
					}
					if (!e.shiftKey && !e.altKey && !e.ctrlKey) {
						e.stopImmediatePropagation();
						e.preventDefault();
						var idx = self.grid.focus.rowIndex;
						switch (e.which) {
							case 13: // enter
								self.changeCollection(idx);
								break;
							case 8: // backspace
								self.changeCollection(0);
								break;
						}
					}
				});*/

				var tools = [{
					id:"reload",
					title:"Refresh"
				},{
					id:"reindex",
					title:"Reindex collection"
				},{
					id:"new",
					title:"New collection"
				},{
					id:"delete",
					title:"Delete resources"
				},{
					id:"properties",
					title:"Edit owner, groups and permissions"
				},{
					id:"copy",
					title:"Copy selected resources"
				},{
					id:"cut",
					title:"Cut selected resources"
				},{
					id:"paste",
					title:"Paste resources"
				},{
					id:"add",
					title:"Upload resources"
				}];
				
				this.tools = {};
				array.forEach(tools,function(_){
					var bt = new Button({
						title:_.title,
						iconClass:"dexistToolbar-"+_.id,
						showLabel:false
					});
					this.tools[_.id] = bt;
					this.toolbar.addChild(bt);
				},this)
				

				/* on(this.tools["properties"], "click", lang.hitch(this, "properties")); */
				this.tools["properties"].on("click", lang.hitch(this,function(ev) {
					if(selection.length && selection.length > 0) {
						this.store.get(selection[0].id).then(lang.hitch(this,function(item){
							this.selectChild(this.propertiesPage);
							this.form.rebuild({
								controls:[{
									name:"name",
									title:"Resource",
									type:"text",
									readOnly:true
								},{
									name:"internetMediaType",
									title:"Internet Media Type",
									type:"text",
									readOnly:true
								},{
									name:"created",
									type:"text",
									readOnly:true
								},{
									name:"lastModified",
									title:"Last Modified",
									type:"text",
									readOnly:true
								},{
									name:"owner",
									type:"text",
									trim:true
								},{
									name:"group",
									type:"text",
									trim:true
								},{
									name:"permissions",
									type:"grid",
									add:false,
									edit:false,
									remove:false,
									style:"height:200px",
									selectionMode:"none",
									columns: [{
										label: "Permission",
										field: "id"
									},{
										label: "Read",
										field: "read",
										editor: "checkbox"
									},{
										label: "Write",
										field: "write",
										editor: "checkbox"
									},{
										label: "Execute",
										field: "execute",
										editor: "checkbox"
									},{
										label: "Special",
										field: "special",
										editor: "checkbox"
									}]
								},{
									name:"acl",
									type:"grid",
									style:"height:200px",
									columns:[{
										label: "Target",
										field: "target",
										width: "20%"
									},{
										label: "Subject", 
										field: "who", 
										width: "30%"
									},{
										label: "Access", 
										field: "access", 
										width: "20%"
									},{
										label: "Read", 
										field: "read", 
										width: "10%", 
										editor: "checkbox"
									},{
										label: "Write", 
										field: "write", 
										width: "10%", 
										editor: "checkbox"
									},{
										label: "Execute", 
										field: "execute", 
										width: "10%", 
										editor: "checkbox"
									}]
								}]
							}).then(lang.hitch(this,function(widgets){
								this.form.set("value",item);
							}));
						}));
					}
				}));
				
				on(this.tools["delete"], "click", lang.hitch(this, "deleteResources"));
				on(this.tools["new"], "click", lang.hitch(this, "createCollection"));

				on(this.tools["add"], "click", lang.hitch(this, "upload"));

				on(this.tools["copy"], "click", function(ev) {
					ev.preventDefault();
					self.clipboard = self.getSelected();
					console.log("Cut %d resources", self.clipboard.length);
					self.clipboardCut = false;
				});
				on(this.tools["cut"], "click", function(ev) {
					ev.preventDefault();
					self.clipboard = self.getSelected();
					console.log("Cut %d resources", self.clipboard.length);
					self.clipboardCut = true;
				});
				on(this.tools["paste"], "click", lang.hitch(this,"pasteResources"));
				on(this.tools["reload"], "click", lang.hitch(this, "refresh"));
				on(this.tools["reindex"], "click", lang.hitch(this, "reindex"));
				/*on(this.tools["edit"], "click", lang.hitch(this, function(ev) {
					var items = this.grid.selection.getSelected();
					if(items.length && items.length > 0 && !items[0].isCollection) {
						this.openResource(items[0].id);
					}
				}));*/
				this.addChild(this.browsingPage);
				this.addChild(this.propertiesPage);
				this.grid.startup();
				//new Uploader(dom.byId("browsing-upload"), lang.hitch(this, "refresh"));
				
				this.form = new Builder({
					cancellable:true,
					cancel:function(){
						self.selectChild(self.browsingPage);
					},
					submit:function(){
						if(!this.validate()) return;
						var data = this.get("value");
						console.log(data);
						self.selectChild(self.browsingPage);
					}
				});
				
				this.propertiesPage.addChild(this.form);
				
				// resizing and grid initialization after plugin becomes visible
				this.grid.focus();
				this.inherited(arguments);
			},

			getSelected: function(collectionsOnly) {
				if(selection.length && selection.length > 0) {
					var resources = [];
					array.forEach(selection, function(item) {
						if (!collectionsOnly || item.isCollection)
							resources.push(item.id);
					});
					return resources;
				}
				return null;
			},

			/*applyProperties: function(dlg, resources) {
				var self = this;
				var form = dom.byId("browsing-dialog-form");
				var params = domForm.toObject(form);
				params.resources = resources;
				request.post("/dashboard/plugins/browsing/properties/",{
					data: params,
					handleAs: "json"
				}).then(function(data) {
					self.refresh();
					if (data.status == "ok") {
						registry.byId("browsing-dialog").hide();
					} else {
						util.message("Changing Properties Failed!", "Could not change properties on all resources!");
					}
				},function() {
					util.message("Server Error", "An error occurred while communicating to the server!");
				});
			},*/

			refresh: function(collection) {
				if(collection) {
					this.collection = collection;
					this.updateBreadcrumb();
				}
				this.grid.set("collection",this.store.filter({collection:this.collection}));
			},

			changeCollection: function(idx) {
				console.debug("Changing to item %d %o", idx, this.grid);
				var item = this.grid.getItem(idx);
				if (item.isCollection) {
					this.collection = item.id;
					this.grid.selection.deselectAll();
					this.grid.set("collection",this.store.filter({collection:this.collection}));
					this.grid.focus.setFocusIndex(0, 0);
				}
			},

			createCollection: function() {
				var self = this;
				util.input("Create Collection", "Create a new collection",
					"<label for='name'>Name:</label><input type='text' name='name'/>",
					function(value) {
						var id = self.collection.replace(/^\/db\/?/,"");
						self.store.rpc(id,"create-collection",[value.name]).then(function() {
							self.refresh();
						},function(err) {
							util.message("Creating Collection Failed!", "Could not create collection &apos;" + value.name+ "&apos;.<br>Server says: "+err.response.xhr.responseText);
						});
					}
				);
			},

			deleteResources: function(ev) {
				ev.preventDefault();
				var self = this;
				var resources = self.getSelected();
				if(resources) {
					util.confirm("Delete Resources?", "Are you sure you want to delete the selected resources?",
						function() {
							self.store.rpc("","delete-resources",[resources]).then(function() {
								self.refresh();
							},function(err) {
								util.message("Deletion Failed!", "Resources could not be deleted.<br>Server says: "+err.response.xhr.responseText);
							});
						});
				}
			},
			
			pasteResources:function(ev){
				ev.preventDefault();
				if(this.clipboard && this.clipboard.length > 0) {
					console.log("Paste: %d resources", this.clipboard.length);
					var id = this.collection.replace(/^\/db\/?/,"");
					var mthd = this.clipboardCut ? "move-resources" : "copy-resources";
					this.store.rpc(id,mthd,[this.clipboard]).then(lang.hitch(this,function(){
						this.clipboard = null
						this.clipboardCut = false;
						this.refresh();
					}),lang.hitch(this,function(err){
						this.clipboard = null
						this.clipboardCut = false;
						util.message("Paste Failed!", "Some resources could not be copied.");
					}));
				}
			},

			upload: function() {
				dom.byId("browsing-upload-collection").value = this.collection;
				var uploadDlg = registry.byId("browsing-upload-dialog");
				uploadDlg.show();
			},

			reindex: function() {
				var self = this;
				var id = this.collection.replace(/^\/db\/?/,"");
				var resources = this.getSelected(true);
				if (resources && resources.length > 0) {
					if (resources.length > 1) {
						util.message("Reindex", "Please select a single collection or none to reindex the current root collection");
						return;
					}
					id = resources[0];
				}
				
				util.confirm("Reindex collection?", 
					"Are you sure you want to reindex collection " + id + "?",
				function() {
					self.store.rpc(id,"reindex").then(function() {
						self.refresh();
					},function() {
						util.message("Reindex Failed!", "Reindex of collection " + id + " failed");
						self.refresh();
					});
				});
			},
			
			onSelectResource:function(path){
				//override!
			},
			
			openResource: function(path) {
				var exide = window.open("", "eXide");
				if (exide && !exide.closed) {
					
					// check if eXide is really available or it's an empty page
					var app = exide.eXide;
					if (app) {
						// eXide is there
						exide.eXide.app.findDocument(path);

						exide.focus();
						setTimeout(function() {
							if (has("ie") ||
								(typeof exide.eXide.app.hasFocus == "function" && !exide.eXide.app.hasFocus())) {
								util.message("Open Resource", "Opened code in existing eXide window.");
							}
						}, 200);
					} else {
						window.eXide_onload = function() {
							exide.eXide.app.findDocument(path);
						};
						// empty page
						var href = window.location.href;
						href = href.substring(0, href.indexOf("/dashboard")) + "/eXide/index.html";
						exide.location = href;
					}
				} else {
					util.message("Open Resource", "Failed to start eXide in new window.");
				}
			},
			
			loadCSS: function(path) {
				console.debug("loadCSS",path);

				//todo: check this code - still needed?
				var head = document.getElementsByTagName("head")[0];
				query("link", head).forEach(function(elem) {
					var href = elem.getAttribute("href");
					if (href === path) {
						// already loaded
						return;
					}
				});
				var link = document.createElement("link");
				link.setAttribute("rel", "stylesheet");
				link.setAttribute("type", "text/css");
				link.setAttribute("href", path);
				head.appendChild(link);
			}
		});
	});