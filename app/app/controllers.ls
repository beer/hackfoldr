angular.module 'app.controllers' []
.controller AppCtrl: <[$scope $location $resource $rootScope]> ++ (s, $location, $resource, $rootScope) ->

  s <<< {$location}
  s.$watch '$location.path()' (activeNavId or '/') ->
    s <<< {activeNavId}

  s.getClass = (id) ->
    if s.activeNavId.substring 0 id.length is id
      'active'
    else
      ''
.controller HackFolderCtrl: <[$scope $routeParams HackFolder]> ++ ($scope, $routeParams, HackFolder) ->
  console?log $routeParams
  # XXX turn iframes cache into a service
  $scope <<< do
    hasViewMode: -> it.match /g(doc|present|draw)/
    sortableOptions: do
      update: -> console?log \notyetupdated
    iframes: HackFolder.iframes
    docs: HackFolder.docs
    activate: HackFolder.activate
    reload: (hackId) -> HackFolder.getIndex hackId, true ->

  $scope.$watch 'hackId' (hackId) ->
    <- HackFolder.getIndex hackId, false
    $scope.$watch 'docId' (docId) -> HackFolder.activate docId

  $scope.hackId = if $routeParams.hackId => that else 's8r4l008sk'
  $scope.docId = encodeURIComponent $routeParams.docId if $routeParams.docId

.directive 'resize' <[$window]> ++ ($window) ->
  (scope) ->
    scope.width = $window.innerWidth
    scope.height = $window.innerHeight
    angular.element $window .bind 'resize' ->
      scope.$apply ->
        scope.width = $window.innerWidth
        scope.height = $window.innerHeight

.factory HackFolder: <[$http]> ++ ($http) ->
  iframes = {}
  docs = []
  var hackId
  do
    iframes: iframes
    docs: docs
    activate: (id, edit=false) ->
      [{type}:doc] = [d for d in docs when d.id is id]
      mode = if edit => \edit else \view
      src = match type
      | \gdoc =>
          "https://docs.google.com/document/d/#id/#mode"
      | \gsheet =>
          "https://docs.google.com/spreadsheet/ccc?key=#id"
      | \gpresent =>
          "https://docs.google.com/presentation/d/#id/#mode"
      | \gdraw =>
          "https://docs.google.com/drawings/d/#id/#mode"
      | \gsheet =>
          "https://docs.google.com/spreadsheet/ccc?key=#id"
      | \hackpad =>
          "https://hackpad.com/#id"
      | \ethercalc =>
          "http://ethercalc.com/#id"
      | \url => decodeURIComponent decodeURIComponent id

      if iframes[id]
          that <<< {src, mode}
      else
          iframes[id] = {src, doc, mode}

    getIndex: (id, force, cb) ->
      return cb docs if hackId is id and !force
      csv <- $http.get "http://www.ethercalc.com/_/#{id}/csv"
      .success

      hackId := id
      docs.length = 0

      entries = for line in csv.split /\n/ when line
        [url, title, ...rest] = line.split /,/
        title -= /"/g
        entry = { url, title, id: url.1 } <<< match url
        | // ^https?:\/\/www\.ethercalc\.com/(.*) //
            type: \ethercalc
        | // https:\/\/docs\.google\.com/document/(?:d/)?([^/]+)/ //
            type: \gdoc
        | // https:\/\/docs\.google\.com/spreadsheet/ccc\?key=([^/?&]+) //
            type: \gsheet
        | // https:\/\/docs\.google\.com/drawings/(?:d/)?([^/]+)/ //
            type: \gdraw
        | // https:\/\/docs\.google\.com/presentation/(?:d/)?([^/]+)/ //
            type: \gpresent
        | // https?:\/\/hackpad\.com/(?:.*?)-([\w]+)(\#.*)?$ //
            type: \hackpad
        | // ^https?:\/\/ //
            type: \url
            id: encodeURIComponent encodeURIComponent url
            icon: "http://g.etfv.co/#{ encodeURIComponent url }"
        | otherwise => console?log \unrecognized url
        entry.icon ?= "img/#{ entry.type }.png"
        entry
      docs.splice 0, -1, ...(entries.filter -> it?)
      cb docs