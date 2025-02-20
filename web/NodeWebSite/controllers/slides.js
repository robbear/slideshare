var express = require('express'),
    config = require('../utilities/config'),
    utilities = require('../utilities/utilities');

var app = module.exports = express();

app.get('/slides/:user/:slidesharename', function(req, res) {
    var uuidUser = req.params["user"];
    var slideShareName = req.params["slidesharename"];

    utilities.sendOutputHtml("slides", req, res, 'views/slides_header.html', 'views/slides_body.html',
        {
            "PageTitle": "Stori",
            "VersionString": utilities.versionString,
            "SSJ_URL": "\"" + config.slideResourceBaseUrl + uuidUser + "/" + slideShareName + "/" + config.slideShareJSONFilename + "\""
        });
});