xquery version "3.0";

module namespace service="http://exist-db.org/apps/collectionbrowser/service";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace json="http://www.json.org";

declare function service:delete-resources($resources as xs:string*) {
    try {
        for $resource in $resources
        return
            if (xmldb:collection-available($resource)) then
                xmldb:remove($resource)
            else
                let $split := text:groups($resource, "^(.*)/([^/]+)$")
                return
                    xmldb:remove($split[2], $split[3]),
        <response status="ok"/>
    } catch * {
        <response status="fail">
            <message>{$err:description}</message>
        </response>
    }
};

declare function service:resources($id as xs:string, $collection as xs:string) {
    let $user := if(request:get-attribute('org.exist.login.user')) then request:get-attribute('org.exist.login.user') else "guest"
    return
        if($id ne "") then
            let $is-collection := count(service:list-collection-contents($id, $user)) > 1
            return
                service:resource-xml($id, $id, $is-collection, $user)
        else
            let $start := number(request:get-parameter("start", 0)) + 1
            let $endParam := number(request:get-parameter("end", 1000000)) + 1
            let $resources := service:list-collection-contents($collection, $user)
            let $end := if ($endParam gt count($resources)) then count($resources) else $endParam
            let $subset := subsequence($resources, $start, $end - $start + 1)
            let $parent :=
                if (matches($collection, "^/db/?$")) then
                    "/db"
                else
                    replace($collection, "^(.*)/[^/]+/?$", "$1")
            let $totalcount := count($resources) + (if($collection eq "/db") then 0 else 1)
            return (
                response:set-header("Content-Range", "items 0-" || count($subset) + 1 || "/" || $totalcount),
                <json:value> {
                    for $resource in $subset
                        let $is-collection := local-name($resource) eq "collection"
                        let $path := string-join(($collection, $resource), "/")
                        return
                            service:resource-xml($id, $path, $is-collection, $user)
                }
                </json:value>
            )
};

declare
    %private
function service:resource-xml($id as xs:string, $path as xs:string, $is-collection as xs:boolean, $user as xs:string) as element(json:value) {
    let $permission := sm:get-permissions(xs:anyURI($path))/sm:permission,
    $collection := replace($path, "(.*)/.*", "$1"),
    $resource := replace($path, ".*/(.*)", "$1"),
    $created := 
        if($is-collection) then
            format-dateTime(xmldb:created($path), "[MNn] [D00] [Y0000] [H00]:[m00]:[s00]")
        else
            format-dateTime(xmldb:created($collection, $resource), "[MNn] [D00] [Y0000] [H00]:[m00]:[s00]")
       ,
    $last-modified :=
                if($is-collection) then
                    $created
                else
                    format-dateTime(xmldb:last-modified($collection, $resource), "[MNn] [D00] [Y0000] [H00]:[m00]:[s00]")
                ,
    $internet-media-type :=
        if($is-collection) then
            "<Collection>"
        else
            xmldb:get-mime-type(xs:anyURI($path))
        ,
    $can-write :=
        if($is-collection) then
            service:canWrite($path, $user)
        else
            service:canWriteResource($collection, $resource, $user)
    return
    
        <json:value>
            {
                if($id eq "") then
                    attribute json:array { "true" }
                else
                    ()
            }
            <name>{replace($path, ".*/(.*)", "$1")}</name>
            <id>{$path}</id>
            <permissionsString>{if($is-collection)then "c" else "-"}{string($permission/@mode)}{if($permission/sm:acl/@entries ne "0")then "+" else ""}</permissionsString>
            <owner>{string($permission/@owner)}</owner>
            <group>{string($permission/@group)}</group>
            <internetMediaType>{$internet-media-type}</internetMediaType>
            <created>{$created}</created>
            <lastModified>{$last-modified}</lastModified>
            <writable json:literal="true">{$can-write}</writable>
            <collection>{$collection}</collection>
            <isCollection json:literal="true">{$is-collection}</isCollection>
            {
                if($id ne "") then
                    (element permissions {
                        service:get-permissions($id,"")
                    },
                    element acl {
                        service:get-acl($id,"")
                    })
                else
                    ()
            }
        </json:value>
};

declare
    %private
function service:permissions-classes-xml($permission as element(sm:permission)) as element(class)+ {
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
        </class>,
        <class>
            <id>Group</id>
            <read json:literal="true">{$chars[4] = "r"}</read>
            <write json:literal="true">{$chars[5] = "w"}</write>
            <execute json:literal="true">{$chars[6] = ("x", "s")}</execute>
            <special json:literal="true">{$chars[6] = ("s", "S")}</special>
        </class>,
        <class>
            <id>Other</id>
            <read json:literal="true">{$chars[7] = "r"}</read>
            <write json:literal="true">{$chars[8] = "w"}</write>
            <execute json:literal="true">{$chars[9] = ("x", "t")}</execute>
            <special json:literal="true">{$chars[9] = ("t", "T")}</special>
        </class>
    )
};

declare function service:copyOrMove($target as xs:string, $sources as xs:string*, $action as xs:string) {
    let $target := concat("/", $target)
    let $user := if (request:get-attribute('org.exist.login.user')) then request:get-attribute('org.exist.login.user') else "guest"
    return
        if ($action = "reindex") then
            let $reindex := xmldb:reindex($target)
            return
                <response status="ok"/>
        else
            if (service:canWrite($target, $user)) then (
                for $source in $sources
                let $isCollection := xmldb:collection-available($source)
                return
                    if ($isCollection) then
                        switch($action)
                            case "move" return
                                xmldb:move($source, $target)
                            default return
                                xmldb:copy($source, $target)
                    else
                        let $split := text:groups($source, "^(.*)/([^/]+)$")
                        return
                            switch ($action)
                                case "move" return
                                    xmldb:move($split[2], $target, $split[3])
                                default return
                                    xmldb:copy($split[2], $target, $split[3]),
                    <response status="ok"/>
            ) else
                <response status="fail">
                    <message>You are not allowed to write to collection {$target}.</message>
                </response>
};

declare
function service:create-collection($collection as xs:string, $create as xs:string) {
    let $user := if (request:get-attribute('org.exist.login.user')) then request:get-attribute('org.exist.login.user') else "guest"
    let $log := util:log("DEBUG", ("creating collection ", $collection))
    return
        if (service:canWrite($collection, $user)) then
            (xmldb:create-collection($collection, $create), <response status="ok"/>)[2]
        else
            <response status="fail">
                <message>You are not allowed to write to collection {$collection}.</message>
            </response>
};

declare
function service:get-permissions($id as xs:string, $class as xs:string) as element(json:value)* {
    let $permissions := sm:get-permissions(xs:anyURI($id))/sm:permission
    return
        for $c in service:permissions-classes-xml($permissions)[if(string-length($class) eq 0)then true() else id = $class] return
            <json:value json:array="true">{
                $c/child::element()
            }</json:value>
};

declare
function service:save-permissions($id as xs:string, $recv-permissions as node()) {
        let $cs :=
            if($recv-permissions/pair[@name eq "id"] eq "User") then
                ("u", if($recv-permissions/pair[@name eq "special"] eq "true") then "+s" else "-s")
            else if($recv-permissions/pair[@name eq "id"] eq "Group") then
                ("g", if($recv-permissions/pair[@name eq "special"] eq "true") then "+s" else "-s")
            else if($recv-permissions/pair[@name eq "id"] eq "Other") then
                ("o", if($recv-permissions/pair[@name eq "special"] eq "true") then "+t" else "-t")
            else(),
            
        $c := $cs[1], (: received class :)
        $s := $cs[2], (: received special :)
            
        $r := 
            concat(if($recv-permissions/pair[@name eq "read"] eq "true") then
                "+"
            else 
                "-"
            ,"r"),
        
        $w :=
            concat(if($recv-permissions/pair[@name eq "write"] eq "true") then
                "+"
            else 
                "-"
            ,"w"),
            
        $x :=
            concat(if($recv-permissions/pair[@name eq "execute"] eq "true") then
                "+"
            else 
                "-"
            ,"x")
            
        return
            if(not(empty($cs))) then
            (
                sm:chmod(xs:anyURI($id), $c || $r || "," || $c || $w || "," || $c || $x || "," || $c || $s),
                <response status="ok"/>
            )
            else
                <response status="fail">
                    <message>Invalid class to set permissons for!</message>
                </response>
};

declare
function service:get-acl($id as xs:string, $acl-id as xs:string) as element(json:value)* {
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

declare
function service:change-properties($resources as xs:string, $owner as xs:string?, $group as xs:string?, $mime as xs:string?) {
    for $resource in $resources
    let $uri := xs:anyURI($resource)
    return (
        sm:chown($uri, $owner),
        sm:chgrp($uri, $group),
        sm:chmod($uri, service:permissions-from-form()),
        xmldb:set-mime-type($resource, $mime)
    ),
    <response status="ok"/>
};

(:declare:)
(:    %rest:POST:)
(:    %rest:path("/upload/"):)
(:    %output:media-type("application/json"):)
(:    %output:method("json"):)
(:function service:upload() {:)
(:    let $collection := request:get-parameter("collection", "/db/abc"):)
(:    let $names := request:get-uploaded-file-name("uploadedfiles[]"):)
(:    let $files := request:get-uploaded-file-data("uploadedfiles[]"):)
(:    let $log := util:log("DEBUG", ("files: ", $files)):)
(:    return:)
(:        <result>:)
(:        {:)
(:            map-pairs(function($name, $file) {:)
(:                let $stored := xmldb:store($collection, xmldb:encode-uri($name), $file):)
(:                let $log := util:log("DEBUG", ("Uploaded: ", $stored)):)
(:                return:)
(:                    <json:value>:)
(:                        <file>{$stored}</file>:)
(:                        <size>xmldb:size($collection, $name)</size>:)
(:                        <type>xmldb:get-mime-type($stored)</type>:)
(:                    </json:value>:)
(:            }, $names, $files):)
(:        }:)
(:        </result>:)
(:};:)

declare %private function service:permissions-from-form() {
    string-join(
        for $type in ("u", "g", "w")
        for $perm in ("r", "w", "x")
        let $param := request:get-parameter($type || $perm, ())
        return
            if ($param) then
                $perm
            else
                "-",
        ""
    )
};

declare %private function service:list-collection-contents($collection as xs:string, $user as xs:string) {
    
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
    
    (:
    let $subcollections := 
        for $child in xmldb:get-child-collections($collection)
        where sm:has-access(xs:anyURI(concat($collection, "/", $child)), "r")
        return
            $child
    let $resources :=
        for $r in xmldb:get-child-resources($collection)
        where sm:has-access(xs:anyURI(concat($collection, "/", $r)), "r")
        return
            $r
    for $resource in ($subcollections, $resources)
    order by $resource ascending
	return
		$resource
	:)
};

declare %private function service:canWrite($collection as xs:string, $user as xs:string) as xs:boolean {
    if (xmldb:is-admin-user($user)) then
    	true()
	else
    	let $permissions := xmldb:permissions-to-string(xmldb:get-permissions($collection))
    	let $owner := xmldb:get-owner($collection)
    	let $group := xmldb:get-group($collection)
    	let $groups := xmldb:get-user-groups($user)
    	return
        	if ($owner eq $user) then
            	substring($permissions, 2, 1) eq 'w'
        	else if ($group = $groups) then
            	substring($permissions, 5, 1) eq 'w'
        	else
            	substring($permissions, 8, 1) eq 'w'
};

declare %private function service:canWriteResource($collection as xs:string, $resource as xs:string, $user as xs:string) as xs:boolean {
    if (xmldb:is-admin-user($user)) then
		true()
	else
		let $permissions := xmldb:permissions-to-string(xmldb:get-permissions($collection, $resource))
		let $owner := xmldb:get-owner($collection, $resource)
		let $group := xmldb:get-group($collection, $resource)
		let $groups := xmldb:get-user-groups($user)
		return
			if ($owner eq $user) then
				substring($permissions, 2, 1) eq 'w'
			else if ($group = $groups) then
				substring($permissions, 5, 1) eq 'w'
			else
				substring($permissions, 8, 1) eq 'w'
};

declare %private function service:merge-properties($maps as map(*)) {
    map:new(
        for $key in map:keys($maps[1])
        let $values := distinct-values(for $map in $maps return $map($key))
        return
            map:entry($key, if (count($values) = 1) then $values[1] else "")
    )
};

declare %private function service:get-property-map($resource as xs:string) as map(*) {
    let $isCollection := xmldb:collection-available($resource)
    return
        if ($isCollection) then
            map {
                "owner" := xmldb:get-owner($resource),
                "group" := xmldb:get-group($resource),
                "last-modified" := format-dateTime(xmldb:created($resource), "[MNn] [D00] [Y0000] [H00]:[m00]:[s00]"),
                "permissions" := xmldb:permissions-to-string(xmldb:get-permissions($resource)),
                "mime" := xmldb:get-mime-type(xs:anyURI($resource))
            }
        else
            let $components := text:groups($resource, "^(.*)/([^/]+)$")
            return
                map {
                    "owner" := xmldb:get-owner($components[2], $components[3]),
                    "group" := xmldb:get-group($components[2], $components[3]),
                    "last-modified" := 
                        format-dateTime(xmldb:last-modified($components[2], $components[3]), "[MNn] [D00] [Y0000] [H00]:[m00]:[s00]"),
                    "permissions" := xmldb:permissions-to-string(xmldb:get-permissions($components[2], $components[3])),
                    "mime" := xmldb:get-mime-type(xs:anyURI($resource))
                }
};

declare %private function service:get-properties($resources as xs:string*) as map(*) {
    service:merge-properties(for $resource in $resources return service:get-property-map($resource))
};

declare %private function service:get-users() {
    distinct-values(
        for $group in sm:get-groups()
        return
            sm:get-group-members($group)    
    )
};


declare %private function service:path-to-col-res-path($path as xs:string) {
    (replace($path, "(.*)/.*", "$1"), replace($path, ".*/", ""))
};
