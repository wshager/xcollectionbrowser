xquery version "3.0";

module namespace db="http://exist-db.org/apps/collectionbrowser/db";

import module namespace rql="http://lagua.nl/lib/rql" at "util/rql.xql";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace http="http://expath.org/ns/http-client";
declare namespace json="http://www.json.org";

(: standard crud functions :)
declare function db:get($collection as xs:string, $id as xs:string, $directives as item()) {
	let $is-collection := xmldb:collection-available($collection || "/" || $id)
	return
		db:resource-xml($collection || "/" || $id, true(), $is-collection)
};

declare function db:query($collection as xs:string, $query-string as xs:string, $directives as item()) {
	let $rqlquery := rql:parse($query-string)
	let $parent := util:unescape-uri(rql:get-element-by-property($rqlquery,"collection"),"utf-8")
	let $resources := 
		for $resource in db:list-collection-contents($parent) return
			let $path := $parent || "/" || $resource
			let $is-collection := local-name($resource) eq "collection"
			return
				db:resource-xml($path, false(), $is-collection)
	let $totalcount := count($resources)
	let $rqlxq := rql:to-xq($rqlquery)
	let $limit := 
		if($rqlxq("limit")) then
			$rqlxq("limit")
		else if($directives("range")) then
			rql:get-limit-from-range($directives("range"),$totalcount)
		else
			()
	let $resources := rql:xq-sort($resources, $rqlxq("sort"))
	let $subset := rql:xq-limit($resources, $limit)
	let $content-range := rql:get-content-range-header($limit,$totalcount)
	return (
		<http:response status="200">
			<http:header name="Content-Range" value="{$content-range}"/>
			<http:header name="sort" value="{$limit}"/>
		</http:response>,
		element root {
			if($subset) then
				$subset
			else
				attribute json:array { "true" },
				()
		}
	)
};

declare function db:put($collection as xs:string, $data as node(), $directives as item()) {
	let $id := $data/id/string()
	return
		if($id) then
			let $uri := xs:anyURI($collection || "/" || $id)
			return
				if(sm:has-access($uri,"w")) then
					let $props := (
						sm:chown($uri, $data/owner/string()),
						sm:chgrp($uri, $data/group/string()),
						sm:chmod($uri, db:permissions-from-data($data/permissions)),
						db:save-acl($uri,$data/acl)
					)
					(:xmldb:set-mime-type($resource, $data/internetMimeType):)
					return $data
				else
					<http:response status="403" message="Not allowed."/>
		else
			<http:response status="404" message="No ID was provided with the request."/>
};

(: RPC functions :)
declare function db:create-collection($target as xs:string, $create as node(), $id as xs:string, $directives as item()) {
	let $create := $create/string()
	let $log := util:log("DEBUG", ("creating collection ", $create))
	return
		if(sm:has-access($target,"w")) then
			try {
				<response id="{$id}" error="">
					<result>Collection {xmldb:create-collection($target, $create)} created.</result>
				</response>
			} catch * {
				(
					<http:response status="500" message="An unknown error occured while trying to create collection {$target}."/>,
					<response id="{$id}">
						<error json:literal="true">true</error>
					</response>
				)
			}
		else
			(
				<http:response status="403" message="You are not allowed to write to collection {$target}."/>,
				<response id="{$id}">
					<error json:literal="true">true</error>
				</response>
			)
};

declare function db:move-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as item()) {
	db:copyOrMove($target, $resources/json:value/string(), "move", $id)
};

declare function db:copy-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as item()) {
	db:copyOrMove($target, $resources/json:value/string(), "copy", $id)
};

declare function db:reindex($target as xs:string, $id as xs:string, $directives as item()) {
	let $reindex := xmldb:reindex($target)
	return
		element response { 
			element id {$id },
			element result {$reindex},
			element error {}
		}
};

declare function db:delete-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as item()) {
	try {
		for $item in $resources/json:value/string()
			let $resource := "/db/" || $item
			return
				if (xmldb:collection-available($resource)) then
					xmldb:remove($resource)
				else
					let $split := analyze-string($resource,"^(.*)/([^/]+)$")//fn:group/text()
					return
						xmldb:remove($split[1], $split[2]),
			<response id="{$id}" error="">
				<result>Resources removed successfully</result>
			</response>
	} catch * {
		(
			<http:response status="500" message="{$err:description}" />,
			<response id="{$id}">
				<error json:literal="true">true</error>
			</response>
		)
	}
};

(: private functions :)
declare
	%private
function db:permissions-from-data($permissions) {
	string-join(
		for $type in ("User", "Group", "Other")
			return db:rwx-from-data($permissions[id = $type], $type)
	)
};

declare
	%private
function db:rwx-from-data($permissions) {
    db:rwx-from-data($permissions,"")
};

declare
    %private
function db:rwx-from-data($permissions,$type as xs:string) {
	let $perms := map {
		"read" := "r",
		"write" := "w",
		"execute" := "x"
	}
	let $ret := 
		for $perm in ("read", "write", "execute")
			let $param := $permissions/*[name() = $perm]
			return
				if($param = "true") then
					$perms($perm)
				else
					"-"
	let $special :=
		if($permissions/special = "true") then
			if($type = ("User","Group")) then
				"s"
			else if($type = "Other") then 
				"t"
			else
				$ret[3]
		else
			$ret[3]
	return concat($ret[1],$ret[2],$special)
};

declare
	%private
function db:resource-xml($path as xs:string, $single as xs:boolean, $is-collection as xs:boolean) as element(json:value)? {
	let $permission := sm:get-permissions(xs:anyURI($path))/sm:permission,
	$collection := replace($path, "(.*)/.*", "$1"),
	$resource := replace($path, ".*/(.*)", "$1"),
	$created := 
		if($is-collection) then
			xmldb:created($path)
		else
			xmldb:created($collection, $resource)
	   ,
	$last-modified :=
				if($is-collection) then
					$created
				else
					xmldb:last-modified($collection, $resource)
				,
	$internet-media-type :=
		if($is-collection) then
			"<Collection>"
		else
			xmldb:get-mime-type(xs:anyURI($path))
		,
	$can-write := sm:has-access($path,"w"),
	$thumbnail :=
		if($internet-media-type = "image/svg+xml") then
			$path
		else if(starts-with($internet-media-type,"image")) then
			let $thumb := $collection || "/.thumbs/" || $resource
			return
				if(util:binary-doc-available($thumb)) then
					$collection || "/.thumbs/" || $resource
				else if(matches($resource,"\.(jpg|gif|png)$") and (xmldb:size($collection,$resource) div 1024) < 512) then
					$path
				else
					()
		else
			()
	return
		if(ends-with($collection,"/.thumbs") or $resource = ".thumbs") then
			()
		else
		<json:value>
			{
				if($single) then
					()
				else
					attribute json:array { "true" }
			}
			<name>{$resource}</name>
			<id>{replace($path,"^/db/(.*)","$1")}</id>
			<permissionsString>{if($is-collection)then "c" else "-"}{string($permission/@mode)}{if($permission/sm:acl/@entries ne "0")then "+" else ""}</permissionsString>
			<owner>{string($permission/@owner)}</owner>
			<group>{string($permission/@group)}</group>
			<internetMediaType>{$internet-media-type}</internetMediaType>
			<created>{$created}</created>
			<lastModified>{$last-modified}</lastModified>
			<writable json:literal="true">{$can-write}</writable>
			<collection>{$collection}</collection>
			<thumbnail>{$thumbnail}</thumbnail>
			<isCollection json:literal="true">{$is-collection}</isCollection>
			{
				if($single) then
					(element permissions {
						db:get-permissions($path,"")
					},
					element acl {
						db:get-acl($path,"")
					})
				else
					()
			}
		</json:value>
};

declare
	%private
function db:permissions-classes-xml($permission as element(sm:permission)) as element(class)+ {
	let $chars := for $ch in string-to-codepoints($permission/@mode)
		return codepoints-to-string($ch)
	return
	(
		<class>
			<id>User</id>
			<read json:literal="true">{$chars[1] = "r"}</read>
			<write json:literal="true">{$chars[2] = "w"}</write>
			<execute json:literal="true">{$chars[3] = ("x", "s")}</execute>
			<special json:literal="true">{$chars[3] = ("s", "S")}</special>
			<specialLabel>SetUID</specialLabel>
		</class>,
		<class>
			<id>Group</id>
			<read json:literal="true">{$chars[4] = "r"}</read>
			<write json:literal="true">{$chars[5] = "w"}</write>
			<execute json:literal="true">{$chars[6] = ("x", "s")}</execute>
			<special json:literal="true">{$chars[6] = ("s", "S")}</special>
			<specialLabel>SetGID</specialLabel>
		</class>,
		<class>
			<id>Other</id>
			<read json:literal="true">{$chars[7] = "r"}</read>
			<write json:literal="true">{$chars[8] = "w"}</write>
			<execute json:literal="true">{$chars[9] = ("x", "t")}</execute>
			<special json:literal="true">{$chars[9] = ("t", "T")}</special>
			<specialLabel>Sticky</specialLabel>
		</class>
	)
};

declare %private function db:copyOrMove($target as xs:string, $sources as xs:string*, $action as xs:string, $id as xs:string) {
	if(sm:has-access($target,"w")) then (
		for $source in $sources
		let $source := "/db/" || $source
		let $isCollection := xmldb:collection-available($source)
		return
			if ($isCollection) then
				switch($action)
					case "move" return
						xmldb:move($source, $target)
					default return
						xmldb:copy($source, $target)
			else
				let $split := analyze-string($resource,"^(.*)/([^/]+)$")//fn:group/text()
				let $res :=
					switch($action)
						case "move" return
							xmldb:move($split[1], $target, $split[2])
						default return
							xmldb:copy($split[1], $target, $split[2])
				return
					<response id="{$id}" error="">
						<result>{$res}</result>
					</response>
	) else
		<http:response status="403" message="You are not allowed to write to collection {$target}." />
};

declare
	%private
function db:get-permissions($id as xs:string, $class as xs:string) as element(json:value)* {
	let $permissions := sm:get-permissions(xs:anyURI($id))/sm:permission
	return
		for $c in db:permissions-classes-xml($permissions)[if(string-length($class) eq 0)then true() else id = $class] return
			<json:value json:array="true">{
				$c/child::element()
			}</json:value>
};

declare
	%private
function db:get-acl($id as xs:string, $acl-id as xs:string) as element(json:value)* {
	let $permissions := sm:get-permissions(xs:anyURI($id))/sm:permission
	let $acl := $permissions/sm:acl/sm:ace[if(string-length($acl-id) eq 0)then true() else @index eq $acl-id]
	return
		if(count($acl)>0) then
			for $ace in $acl return
				<json:value json:array="true">
					<id>{$ace/string(@index)}</id>
					<target>{$ace/string(@target)}</target>
					<who>{$ace/string(@who)}</who>
					<access_type>{$ace/string(@access_type)}</access_type>
					<read json:literal="true">{$ace/contains(@mode, "r")}</read>
					<write json:literal="true">{$ace/contains(@mode, "w")}</write>
					<execute json:literal="true">{$ace/contains(@mode, "x")}</execute>
				</json:value>
		else
			<json:value json:array="true"/>
};

declare %private function db:list-collection-contents($collection as xs:string) {
	(
		for $child in xmldb:get-child-collections($collection)
		order by $child ascending
		return
			<collection>{$child}</collection>
		,
		for $resource in xmldb:get-child-resources($collection)
		order by $resource ascending
		return
			<resource>{$resource}</resource>
	)
};

declare %private function db:save-acl($uri as xs:anyURI,$data as node()*) {
	(: clear and re-insert all :)
	let $del := sm:clear-acl($uri)
	for $ace in $data return
		if($ace/target="USER") then
			sm:insert-user-ace($uri, 0, $ace/who, $ace/access_type="ALLOWED", db:rwx-from-data($ace))
		else if($ace/target="GROUP") then
			sm:insert-group-ace($uri, 0, $ace/who, $ace/access_type="ALLOWED", db:rwx-from-data($ace))
		else
		   ()
};
