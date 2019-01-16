'use strict';


var EcotoxTemplateSearchController = function ($http, $scope, $location, $controller, $filter, NpolarApiSecurity, EcotoxTemplate, npdcAppConfig,  NpdcSearchService, NpolarTranslate) {
  'ngInject';

  $controller('NpolarBaseController', { $scope: $scope });
  $scope.resource = EcotoxTemplate;

  npdcAppConfig.search.local.results.detail = (entry) => {
     let r = "Created: " + (entry.created).substring(0,10) + ", updated: " + (entry.updated).substring(0,10);
     return r;
 };

  npdcAppConfig.search.local.results.subtitle = "updated_by";

  $scope.showNext = function() {
    if (!$scope.feed) {
      return false;
    }
    return ($scope.feed.entries.length < $scope.feed.opensearch.totalResults);
  };

  $scope.next = function() {
    if (!$scope.feed.links) {
      return;
    }

    let nextLink = $scope.feed.links.find(link => { return (link.rel === "next"); });
    if (nextLink.href) {
      $http.get(nextLink.href.replace(/^https?:/, '')).success(function(response) {
        response.feed.entries = $scope.feed.entries.concat(response.feed.entries);
        $scope.feed = response.feed;
      });
    }
  };

  let query = function() {

      let defaults;

      defaults = {
          limit: "50",
          sort:  "title",
          fields: 'title,created,updated,updated_by,id',
          facets: 'title,updated'};

    let invariants = $scope.security.isAuthenticated() ? {} : {} ;
    return Object.assign({}, defaults, invariants);
    };


  $scope.search(query());

  $scope.security = NpolarApiSecurity;
  $scope.base_user = NpolarApiSecurity.canonicalUri('/ecotox-template');


  $scope.$on('$locationChangeSuccess', (event, data) => {
    $scope.search(query());
  });

};

module.exports = EcotoxTemplateSearchController;
