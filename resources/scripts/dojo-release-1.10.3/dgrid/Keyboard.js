//>>built
define("dgrid/Keyboard","dojo/_base/declare dojo/aspect dojo/on dojo/_base/lang dojo/has put-selector/put ./util/misc dojo/_base/sniff".split(" "),function(s,n,m,p,D,t,E){function u(a){a.preventDefault()}var F={checkbox:1,radio:1,button:1},v=/\bdgrid-cell\b/,w=/\bdgrid-row\b/,d=s(null,{pageSkip:10,tabIndex:0,keyMap:null,headerKeyMap:null,postMixInProperties:function(){this.inherited(arguments);this.keyMap||(this.keyMap=p.mixin({},d.defaultKeyMap));this.headerKeyMap||(this.headerKeyMap=p.mixin({},
d.defaultHeaderKeyMap))},postCreate:function(){function a(a){var b=a.target;return b.type&&(!F[b.type]||32===a.keyCode)}function c(c){function g(){b._focusedHeaderNode&&(b._focusedHeaderNode.tabIndex=-1);if(b.showHeader){if(e)for(var a=b.headerNode.getElementsByTagName("th"),c=0,h;h=a[c];++c){if(f.test(h.className)){b._focusedHeaderNode=k=h;break}}else b._focusedHeaderNode=k=b.headerNode;k&&(k.tabIndex=b.tabIndex)}}var e=b.cellNavigation,f=e?v:w,d=c===b.headerNode,k=c;d?(g(),n.after(b,"renderHeader",
g,!0)):n.after(b,"renderArray",function(a){var d=b._focusedNode||k;if(f.test(d.className)&&E.contains(c,d))return a;for(var g=c.getElementsByTagName("*"),e=0,l;l=g[e];++e)if(f.test(l.className)){d=b._focusedNode=l;break}d.tabIndex=b.tabIndex;return a});b._listeners.push(m(c,"mousedown",function(c){a(c)||b._focusOnNode(c.target,d,c)}));b._listeners.push(m(c,"keydown",function(c){if(!c.metaKey&&!c.altKey){var h=b[d?"headerKeyMap":"keyMap"][c.keyCode];h&&!a(c)&&h.call(b,c)}}))}this.inherited(arguments);
var b=this;this.tabableHeader&&(c(this.headerNode),m(this.headerNode,"dgrid-cellfocusin",function(){b.scrollTo({x:this.scrollLeft})}));c(this.contentNode)},removeRow:function(a){if(!this._focusedNode)return this.inherited(arguments);var c=this,b=document.activeElement===this._focusedNode,h=this[this.cellNavigation?"cell":"row"](this._focusedNode),d=h.row||h,e;a=a.element||a;if(a===d.element){e=this.down(d,!0);if(!e||e.element===a)e=this.up(d,!0);this._removedFocus={active:b,rowId:d.id,columnId:h.column&&
h.column.id,siblingId:!e||e.element===a?void 0:e.id};setTimeout(function(){c._removedFocus&&c._restoreFocus(d.id)},0);this._focusedNode=null}this.inherited(arguments)},insertRow:function(){var a=this.inherited(arguments);this._removedFocus&&!this._removedFocus.wait&&this._restoreFocus(a);return a},_restoreFocus:function(a){var c=this._removedFocus,b;if((a=(a=a&&this.row(a))&&a.element&&a.id===c.rowId?a:"undefined"!==typeof c.siblingId&&this.row(c.siblingId))&&a.element){if(!a.element.parentNode.parentNode){c.wait=
!0;return}"undefined"!==typeof c.columnId&&(b=this.cell(a,c.columnId))&&b.element&&(a=b);c.active&&0!==a.element.offsetHeight?this._focusOnNode(a,!1,null):(t(a.element,".dgrid-focus"),a.element.tabIndex=this.tabIndex,this._focusedNode=a.element)}delete this._removedFocus},addKeyHandler:function(a,c,b){return n.after(this[b?"headerKeyMap":"keyMap"],a,c,!0)},_focusOnNode:function(a,c,b){var d="_focused"+(c?"Header":"")+"Node";c=this[d];var g=this.cellNavigation?"cell":"row",e=this[g](a),f,l,k,x,q;if(a=
e&&e.element){if(this.cellNavigation){f=a.getElementsByTagName("input");q=0;for(k=f.length;q<k;q++)if(l=f[q],(-1!==l.tabIndex||"_dgridLastValue"in l)&&!l.disabled){l.focus();x=!0;break}}null!==b&&(b=p.mixin({grid:this},b),b.type&&(b.parentType=b.type),b.bubbles||(b.bubbles=!0));c&&(t(c,"!dgrid-focus[!tabIndex]"),b&&(b[g]=this[g](c),m.emit(c,"dgrid-cellfocusout",b)));c=this[d]=a;b&&(b[g]=e);d=this.cellNavigation?v:w;!x&&d.test(a.className)&&(a.tabIndex=this.tabIndex,a.focus());t(a,".dgrid-focus");
b&&m.emit(c,"dgrid-cellfocusin",b)}},focusHeader:function(a){this._focusOnNode(a||this._focusedHeaderNode,!0)},focus:function(a){(a=a||this._focusedNode)?this._focusOnNode(a,!1):this.contentNode.focus()}}),r=d.moveFocusVertical=function(a,c){var b=this.cellNavigation,d=this[b?"cell":"row"](a),d=b&&d.column.id,g=this.down(this._focusedNode,c,!0);b&&(g=this.cell(g,d));this._focusOnNode(g,!1,a);a.preventDefault()};s=d.moveFocusUp=function(a){r.call(this,a,-1)};var G=d.moveFocusDown=function(a){r.call(this,
a,1)},H=d.moveFocusPageUp=function(a){r.call(this,a,-this.pageSkip)},I=d.moveFocusPageDown=function(a){r.call(this,a,this.pageSkip)},y=d.moveFocusHorizontal=function(a,c){if(this.cellNavigation){var b=!this.row(a);this._focusOnNode(this.right(this["_focused"+(b?"Header":"")+"Node"],c),b,a);a.preventDefault()}},z=d.moveFocusLeft=function(a){y.call(this,a,-1)},A=d.moveFocusRight=function(a){y.call(this,a,1)},B=d.moveHeaderFocusEnd=function(a,c){var b;this.cellNavigation&&(b=this.headerNode.getElementsByTagName("th"),
this._focusOnNode(b[c?0:b.length-1],!0,a));a.preventDefault()},J=d.moveHeaderFocusHome=function(a){B.call(this,a,!0)},C=d.moveFocusEnd=function(a,c){var b=this.cellNavigation,d=this.contentNode,g=d.scrollTop+(c?0:d.scrollHeight),d=d[c?"firstChild":"lastChild"],e=-1<d.className.indexOf("dgrid-preload"),f=e?d[(c?"next":"previous")+"Sibling"]:d,l=f.offsetTop+(c?0:f.offsetHeight),k;if(e){for(;f&&0>f.className.indexOf("dgrid-row");)f=f[(c?"next":"previous")+"Sibling"];if(!f)return}!e||1>d.offsetHeight?
(b&&(f=this.cell(f,this.cell(a).column.id)),this._focusOnNode(f,!1,a)):(D("dom-addeventlistener")||(a=p.mixin({},a)),k=n.after(this,"renderArray",function(d){var e=d[c?0:d.length-1];b&&(e=this.cell(e,this.cell(a).column.id));this._focusOnNode(e,!1,a);k.remove();return d}));g===l&&a.preventDefault()},K=d.moveFocusHome=function(a){C.call(this,a,!0)};d.defaultKeyMap={32:u,33:H,34:I,35:C,36:K,37:z,38:s,39:A,40:G};d.defaultHeaderKeyMap={32:u,35:B,36:J,37:z,39:A};return d});
//# sourceMappingURL=Keyboard.js.map