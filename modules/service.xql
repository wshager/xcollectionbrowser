xquery version "3.0";

module namespace service="http://exist-db.org/apps/collectionbrowser/service";

import module namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace json="http://www.json.org";

(: standard crud functions :)
declare function service:get($collection as xs:string, $id as xs:string, $directives as map) {
    let $is-collection := count(service:list-collection-contents($collection || "/" || $id)) > 1
    return
        service:resource-xml($collection || "/" || $id, true(), $is-collection)
};

declare function service:query($collection as xs:string, $query as map, $directives as map) {
    let $range := $query("range")
    let $parent := $query("collection")
    let $resources := service:list-collection-contents($parent)
    let $totalcount := count($resources)
    let $ranges := 
        if($range) then
            service:get-range($range, $totalcount)
        else
            ()
    let $subset := 
        if($range and $ranges[2] < $totalcount) then
		(: sequence is 1-based :)
			subsequence($resources,$ranges[2]+1,$ranges[1])
		else
			$resources
	let $content-range := 
	    if($range) then
	        concat("items ",min(($ranges[2],$totalcount)),"-",min(($ranges[2]+$ranges[1],$totalcount))-1,"/",$totalcount)
	    else
	        ""
	return (
	    <http:response status="200">
            <http:header name="Content-Range" value="{$content-range}"/>
        </http:response>,
        element root {
            if($subset) then
                for $resource in $subset return
                    let $path := $parent || "/" || $resource
                    let $is-collection := local-name($resource) eq "collection"
                    return
                        service:resource-xml($path, false(), $is-collection)
            else
                attribute json:array { "true" },
                ()
        }
    )
};

declare function service:put($collection as xs:string, $data as node(), $directives as map) {
    let $id := $data/id/string()
    return
        if($id) then
            let $uri := $collection || "/" || $id
            let $props := (
                sm:chown($uri, $data/owner/string()),
                sm:chgrp($uri, $data/group/string()),
                sm:chmod($uri, service:permissions-from-data($data/permissions))
            )
            (:xmldb:set-mime-type($resource, $data/internetMimeType):)
            return $data
        else
            <http:response status="404" message="No ID was provided with the request."/>
};

(: RPC functions :)
declare function service:create-collection($target as xs:string, $create as node(), $id as xs:string, $directives as map) {
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

declare function service:move-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as map) {
    service:copyOrMove($target, $resources/string(), "move")
};

declare function service:copy-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as map) {
    service:copyOrMove($target, $resources/string(), "copy")
};

declare function service:reindex($target as xs:string, $id as xs:string, $directives as map) {
    let $reindex := xmldb:reindex($target)
    return
        element response { 
            element id {$id },
            element result {$reindex},
            element error {}
        }
};

declare function service:delete-resources($target as xs:string, $resources as node()*, $id as xs:string, $directives as map) {
    try {
        for $item in $resources/string()
            let $resource := $target || "/" || $item
            return
                if (xmldb:collection-available($resource)) then
                    xmldb:remove($resource)
                else
                    let $split := text:groups($resource, "^(.*)/([^/]+)$")
                    return
                        xmldb:remove($split[2], $split[3]),
            <response id="{$id}" error="">
                <result>Resources removed successfully</result>
            </response>
    } catch * {
        (
            <http:response status="500" message="{$err:description}" />,
            <response id="{$id}" result="{$err:description}">
                <error json:literal="true">true</error>
            </response>
        )
    }
};


declare
    %private
function service:permissions-from-data($permissions) {
    let $perms := map {
        "read" := "r",
        "write" := "w",
        "execute" := "x"
    }
    return
        string-join(
            for $type in ("User", "Group", "Other")
                for $perm in ("read", "write", "execute")
                    let $param := $permissions[id = $type]/*[name() = $perm]
                    return
                        if($param = "true") then
                            $perms($perm)
                        else
                            "-",
                    ""
        )
};

declare
    %private
function service:get-range($range as xs:string, $maxLimit as xs:integer) {
	let $maxCount := 0
	let $limit := 
		if($maxLimit) then
			$maxLimit
		else
			1 div 0e0
	let $start := 0
	let $end := $maxLimit
	return
		if($range) then
			let $groups := text:groups($range, "^items=(\d+)-(\d+)?$")
			return
			if(count($groups)>0) then
				let $start := 
					if($groups[2]) then
						xs:integer($groups[2])
					else
						$start
				
				let $end := 
					if($groups[3]) then
						xs:integer($groups[3])
					else
						$end
				let $limit :=
					if($end >= $start) then
						min(($limit, $end + 1 - $start))
					else
						$limit
				let $maxCount :=
					if($end >= $start) then
						1
					else
						$maxCount
				return ($limit,$start,$maxCount)
			else
				($limit,$start,$maxCount)
		else
			($limit,$start,$maxCount)
};

(: private functions :)
declare
    %private
function service:resource-xml($path as xs:string, $single as xs:boolean, $is-collection as xs:boolean) as element(json:value) {
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
    $can-write := sm:has-access($path,"w")
    return
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
            <isCollection json:literal="true">{$is-collection}</isCollection>
            {
                if($single) then
                    (element permissions {
                        service:get-permissions($path,"")
                    },
                    element acl {
                        service:get-acl($path,"")
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

declare %private function service:copyOrMove($target as xs:string, $sources as xs:string*, $action as xs:string) {
    if(sm:has-access($target,"w")) then (
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
                    switch($action)
                        case "move" return
                            xmldb:move($split[2], $target, $split[3])
                        default return
                            xmldb:copy($split[2], $target, $split[3])
    ) else
        <http:response status="403" message="You are not allowed to write to collection {$target}." />
};

declare
    %private
function service:get-permissions($id as xs:string, $class as xs:string) as element(json:value)* {
    let $permissions := sm:get-permissions(xs:anyURI($id))/sm:permission
    return
        for $c in service:permissions-classes-xml($permissions)[if(string-length($class) eq 0)then true() else id = $class] return
            <json:value json:array="true">{
                $c/child::element()
            }</json:value>
};

declare
    %private
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
                    <access>{$ace/string(@access_type)}</access>
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

declare %private function service:list-collection-contents($collection as xs:string) {
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

