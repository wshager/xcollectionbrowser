xquery version "3.0";

(:
 * This module provides an interface that normalizes to Dojo/Persevere-style REST functions
 * Currently this modules forces JSON output
 :)

module namespace rst="http://lagua.nl/lib/rst";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
import module namespace json="http://www.json.org";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

(:  the main function to call from the controller :)
declare function rst:process($path as xs:string, $directives as map) {
	let $query := string(request:get-query-string())
	return rst:process($path, $directives, $query)
};

(:  function to call from the controller, override query :)
declare function rst:process($path as xs:string, $directives as map, $query as item()*) {
	let $directives := map:new(($directives, map { "from-controller" := true() }))
	let $method := request:get-method()
	let $content-type := string(request:get-header("content-type"))
	let $accept := string(request:get-header("accept"))
	let $data :=
		if($method = ("PUT","POST")) then
			string(request:get-data())
		else
			()
	return rst:process($path, $directives, $query, $content-type, $accept, $data, $method)
};

(:  the main function to call from RESTXQ :)
declare function rst:process($path as xs:string, $directives as map, $query as item()*, $content-type as xs:string, $accept as xs:string, $data as item()*, $method as xs:string) {
	let $directives := 
		if(map:contains($directives,"id-property")) then
			$directives
		else
			map:new(($directives, map { "id-property" := "id" }))
	let $model := replace($path, "^/?([^/]+).*", "$1")
	let $id := replace($path, "^/?" || $model || "/(.*)", "$1")
	let $root := $directives("root-collection")
	(: TODO choose default root :)
	let $collection := $root || "/" || $model
	let $response :=
		if($method = "GET") then
			if($id) then
				rst:get($collection,$id,$directives)
			else 
				rst:query($collection,$query,$directives)
		else if($method=("PUT","POST")) then
			(: assume data :)
			let $data := 
				if(matches($content-type,"application/[json|javascript]")) then
					if($data) then
						rst:to-plain-xml(xqjson:parse-json(util:binary-to-string($data)))
					else
						<root/>
				else
					(:  bdee bdee bdatsallfolks :)
					$data
			return
				(: this launches a custom method :)
				if($method = "POST" and exists($data[method])) then
					let $target := concat(
						$collection,
						if($id) then "/" else "",
						$id
					)
					return rst:rpc($target,$data/method/string(),$data/params,$data/id/string(),$directives)
				else
					rst:put($collection,$data,$directives)
		else if($method = "DELETE") then
			rst:delete($collection,$id,$directives)
		else
			<http:response status="405" message="Method not implemented"/>
	let $output := (
		util:declare-option("output:method", "json"),
		util:declare-option("output:media-type", "application/json")
	)
	return
		if(name($response[1]) = "http:response") then
			(: expect custom response :)
			let $http-response := $response[1]
			let $result := remove($response,1)
			return
				if($directives("from-controller")) then
					(: parse http:response entry :)
					(
						if($http-response/@status) then
							response:set-status-code($http-response/@status)
						else
							(),
						for $header in $http-response/http:header return 
							response:set-header($header/@name,$header/@value),
						if($result) then
							$result
						else
							element response {
								$http-response/@message/string(),
								$http-response/message/string()
							}
					)
				else
					(
						<rest:response>{$http-response}</rest:response>,
						$result
					)
		else
			$response
};

declare function rst:get($collection as xs:string,$id as xs:string,$directives as map) {
	let $module := rst:import-module($directives)
	let $fn := function-lookup(xs:QName($directives("module-prefix") || ":get"), 3)
	return $fn($collection,$id,$directives)
};

declare function rst:query($collection as xs:string,$query as item()*,$directives as map) {
	let $module := rst:import-module($directives)
	let $fn := function-lookup(xs:QName($directives("module-prefix") || ":query"), 3)
	return $fn($collection,$query,$directives)
};

declare function rst:put($collection as xs:string,$data as node(),$directives as map) {
	let $module := rst:import-module($directives)
	let $fn := function-lookup(xs:QName($directives("module-prefix") || ":put"), 3)
	return $fn($collection,$data,$directives)
};

declare function rst:delete($collection as xs:string,$id as xs:string,$directives as map) {
	let $module := rst:import-module($directives)
	let $fn := function-lookup(xs:QName($directives("module-prefix") || ":delete"), 3)
	return $fn($collection,$id,$directives)
};

declare function rst:rpc($target as xs:string,$method as xs:string,$params as node()*,$id as xs:string,$directives as map) {
	let $module := rst:import-module($directives)
	let $arity := count($params)
	let $fn := function-lookup(xs:QName($directives("module-prefix") || ":" || $method), $arity + 3)
	return
		switch($arity)
			case 1 return
				$fn($target,$params[1],$id,$directives)
			case 2 return
				$fn($target,$params[1],$params[2],$id,$directives)
			case 3 return
				$fn($target,$params[1],$params[2],$params[2],$id,$directives)
			case 4 return
				$fn($target,$params[1],$params[2],$params[3],$params[4],$id,$directives)
			case 5 return
				$fn($target,$params[1],$params[2],$params[3],$params[4],$params[5],$id,$directives)
			case 6 return
				$fn($target,$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$id,$directives)
			case 7 return
				$fn($target,$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[6],$id,$directives)
			default return
				$fn($target,$id,$directives)
};

declare function rst:import-module($directives as map) {
	let $uri := xs:anyURI($directives("module-uri"))
	let $prefix := $directives("module-prefix")
	let $location := xs:anyURI($directives("module-location"))
	return util:import-module($uri, $prefix, $location)
};

declare %private function rst:to-plain-xml($node as element()) as item()* {
	let $name := string(node-name($node))
	let $name :=
		if($name = "json") then
			"root"
		else if($name = "pair" and $node/@name) then
			$node/@name
		else if($name = "item") then
			"json:value"
		else
			$name
	return
		if($node[@type = "array"]) then
		   for $item in $node/node() return
			element {$name} {
				attribute {"json:array"} {"true"},
				rst:to-plain-xml($item)
			}
		else if($name="json:value") then
			if(empty($node/*)) then
				(if($node/@type = ("number","boolean")) then
					attribute {"json:literal"} {"true"}
				else
					(),
				$node/string())
			else
			   for $item in $node/node() return
					rst:to-plain-xml($item)
		else
			element {$name} {
				if($node/@type = "array") then
					attribute {"json:array"} {"true"}
				else if($node/@type = ("number","boolean")) then
					attribute {"json:literal"} {"true"}
				else
					(),
				$node/@*[matches(name(.),"json:")],
				for $child in $node/node() return
					if($child instance of element()) then
						rst:to-plain-xml($child)
					else
						$child
			}
};