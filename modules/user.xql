xquery version "3.0";

module namespace user="http://exist-db.org/apps/collectionbrowser/user";

import module namespace rql="http://lagua.nl/lib/rql" at "util/rql.xql";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace http="http://expath.org/ns/http-client";
declare namespace json="http://www.json.org";

(: standard crud functions :)
declare function user:get($collection as xs:string, $id as xs:string, $directives as item()*) {
	element root {
		element id { $id }
	}
};

declare function user:query($collection as xs:string, $query-string as xs:string, $directives as item()*) {
	let $result :=
		for $user in sm:list-users() return
			element json:value {
				attribute json:array { "true" },
				element id { $user }
			}
	let $rqlquery := rql:parse($query-string)
	let $rqlxq := rql:to-xq($rqlquery)
	let $totalcount := count($result)
	let $limit := 
		if($rqlxq("limit")) then
			$rqlxq("limit")
		else if($directives("range")) then
			rql:get-limit-from-range($directives("range"),$totalcount)
		else
			()
	let $result := rql:xq-filter($result,$rqlxq("filter"))
	let $result := rql:xq-sort($result, $rqlxq("sort"))
	let $subset := rql:xq-limit($result, $limit)
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