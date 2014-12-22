//>>built
define("dgrid/extensions/ColumnResizer","dojo/_base/declare dojo/on dojo/query dojo/_base/lang dojo/dom dojo/dom-geometry dojo/has ../util/misc put-selector/put dojo/_base/html xstyle/css!../css/extensions/ColumnResizer.css".split(" "),function(A,n,p,x,y,B,v,h,k){function z(a){for(var b=a.length,c=b,q=a[0].length,f=Array(b);b--;)f[b]=Array(q);for(var m={},b=0;b<c;b++)for(var e=f[b],l=a[b],t=0,h=0;t<q;t++){var g=l[h],d;if("undefined"===typeof e[t]){e[t]=g.id;if(g.rowSpan&&1<g.rowSpan){d=f;for(var k=
g.rowSpan,p=b,r=t,s=g.id,u=1;u<k;u++)d[p+u][r]=s}if(0<b&&g.colSpan&&1<g.colSpan)for(d=1;d<g.colSpan;d++)if(e[++t]=g.id,g.rowSpan&&1<g.rowSpan)for(var k=f,p=g.rowSpan,r=b,s=t,u=g.id,n=1;n<p;n++)k[r+n][s]=u;m[g.id]=a[0][t].id;h++}}return m}function r(a,b,c,q,f){if(!(0>=c)){var d=a.columns[b],e;if(d&&(e={grid:a,columnId:b,width:c,bubbles:!0,cancelable:!0},q&&(e.parentType=q),!a._resizedColumns||n.emit(a.headerNode,"dgrid-columnresize",e)))return"auto"===c?delete d.width:(d.width=c,c+="px"),(q=a._columnSizes[b])?
q.set("width",c):q=h.addCssRule("#"+h.escapeCssIdentifier(a.domNode.id)+" .dgrid-column-"+h.escapeCssIdentifier(b,"-"),"width: "+c+";"),a._columnSizes[b]=q,!1!==f&&a.resize(),!0}}var d,w=0,s={create:function(){d=k("div.dgrid-column-resizer")},destroy:function(){k(d,"!");d=null},show:function(a){a=B.position(a.domNode,!0);d.style.top=a.y+"px";d.style.height=a.h+"px";k(document.body,d)},move:function(a){d.style.left=a+"px"},hide:function(){d.parentNode.removeChild(d)}};return A(null,{resizeNode:null,
minWidth:40,adjustLastColumn:!0,_resizedColumns:!1,buildRendering:function(){this.inherited(arguments);w||s.create();w++},destroy:function(){this.inherited(arguments);for(var a in this._columnSizes)this._columnSizes[a].remove();--w||s.destroy()},resizeColumnWidth:function(a,b){return r(this,a,b)},configStructure:function(){var a=this._oldColumnSizes=x.mixin({},this._columnSizes),b;this._resizedColumns=!1;this._columnSizes={};this.inherited(arguments);for(b in a)b in this._columnSizes||a[b].remove();
delete this._oldColumnSizes},_configColumn:function(a){this.inherited(arguments);var b=a.id,c;"width"in a&&((c=this._oldColumnSizes[b])?c.set("width",a.width+"px"):c=h.addCssRule("#"+h.escapeCssIdentifier(this.domNode.id)+" .dgrid-column-"+h.escapeCssIdentifier(b,"-"),"width: "+a.width+"px;"),this._columnSizes[b]=c)},renderHeader:function(){this.inherited(arguments);var a=this,b;if(this.columnSets&&this.columnSets.length)for(var c=this.columnSets.length;c--;)b=x.mixin(b||{},z(this.columnSets[c]));
else this.subRows&&1<this.subRows.length&&(b=z(this.subRows));for(var c=p(".dgrid-cell",a.headerNode),d=c.length;d--;){var f=c[d],m=f.columnId,e=a.columns[m],l=f.childNodes;if(e&&!1!==e.resizable){e=k("div.dgrid-resize-header-container");for(f.contents=e;0<l.length;)k(e,l[0]);f=k(f,e,"div.dgrid-resize-handle.resizeNode-"+h.escapeCssIdentifier(m,"-"));f.columnId=b&&b[m]||m}}a.mouseMoveListen||(n(a.headerNode,".dgrid-resize-handle:mousedown"+(v("touch")?",.dgrid-resize-handle:touchstart":""),function(b){a._resizeMouseDown(b,
this);a.mouseMoveListen.resume();a.mouseUpListen.resume()}),a._listeners.push(a.mouseMoveListen=n.pausable(document,"mousemove"+(v("touch")?",touchmove":""),h.throttleDelayed(function(b){a._updateResizerPosition(b)}))),a._listeners.push(a.mouseUpListen=n.pausable(document,"mouseup"+(v("touch")?",touchend":""),function(b){a._resizeMouseUp(b);a.mouseMoveListen.pause();a.mouseUpListen.pause()})),a.mouseMoveListen.pause(),a.mouseUpListen.pause())},_resizeMouseDown:function(a,b){a.preventDefault();y.setSelectable(this.domNode,
!1);this._startX=this._getResizeMouseLocation(a);this._targetCell=p(".dgrid-column-"+h.escapeCssIdentifier(b.columnId,"-"),this.headerNode)[0];this._updateResizerPosition(a);s.show(this)},_resizeMouseUp:function(a){var b=this._columnSizes,c,d,f;this.adjustLastColumn&&(f=this.headerNode.clientWidth-1);this._resizedColumns||(c=p(".dgrid-cell",this.headerNode),this.columnSets&&this.columnSets.length?c=c.filter(function(a){return"0"===a.columnId.split("-")[0]&&!(a.columnId in b)}):this.subRows&&1<this.subRows.length&&
(c=c.filter(function(a){return"0"===a.columnId.charAt(0)&&!(a.columnId in b)})),d=c.map(function(a){return a.offsetWidth}),c.forEach(function(a,b){r(this,a.columnId,d[b],null,!1)},this),this._resizedColumns=!0);y.setSelectable(this.domNode,!0);c=this._targetCell;var m=this._getResizeMouseLocation(a)-this._startX,e=c.offsetWidth+m,l=this._getResizedColumnWidths(),k=l.totalWidth,l=l.lastColId,n=p(".dgrid-column-"+h.escapeCssIdentifier(l,"-"),this.headerNode)[0].offsetWidth;e<this.minWidth&&(e=this.minWidth);
r(this,c.columnId,e,a.type)&&c.columnId!==l&&this.adjustLastColumn&&(k+m<f?r(this,l,"auto",a.type):n-m<=this.minWidth&&r(this,l,this.minWidth,a.type));s.hide();delete this._startX;delete this._targetCell},_updateResizerPosition:function(a){if(this._targetCell){a=this._getResizeMouseLocation(a);var b=this._targetCell.offsetWidth,c=a;b+(a-this._startX)<this.minWidth&&(c=this._startX-(b-this.minWidth));s.move(c)}},_getResizeMouseLocation:function(a){var b=0;a.pageX?b=a.pageX:a.clientX&&(b=a.clientX+
document.body.scrollLeft+document.documentElement.scrollLeft);return b},_getResizedColumnWidths:function(){var a=0,b=p((this.columnSets?".dgrid-column-set-cell ":"")+"tr:first-child .dgrid-cell",this.headerNode),c=b.length;if(!c)return{};for(var d=b[c-1].columnId;c--;)a+=b[c].offsetWidth;return{totalWidth:a,lastColId:d}}})});
//# sourceMappingURL=ColumnResizer.js.map