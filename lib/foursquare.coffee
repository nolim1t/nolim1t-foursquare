request = require 'request'
conf = {
	foursquare: {
		authUrl: 'https://foursquare.com/oauth2/authorize',
		tokenUrl: 'https://foursquare.com/oauth2/access_token',
		baseUrl: 'https://api.foursquare.com/v2/'
		accessToken: process.env.FOURSQUARECLIENTID,
		accessSecret: process.env.FOURSQUARECLIENTSECRET,
		redirUrl: process.env.FOURSQUAREREDIRURL,
	}
}

# Example: coffee -e 'require("./lib/foursquare.coffee").auth.generateurl (cb) -> console.log cb '
generateredirecturl = (callback) ->
	callback(conf.foursquare.authUrl + '?client_id=' + conf.foursquare.accessToken + '&response_type=code&redirect_uri=' + encodeURIComponent(conf.foursquare.redirUrl))

# Example: coffee -e 'require("./lib/foursquare.coffee").auth.accesstoken "" (cb) -> console.log cb '
getaccesstoken = (code, callback) ->
	url = conf.foursquare.tokenUrl + '?client_id=' + conf.foursquare.accessToken + '&grant_type=authorization_code&client_secret=' + encodeURIComponent(conf.foursquare.accessSecret) + '&redirect_uri=' + encodeURIComponent(conf.foursquare.redirUrl) + '&code=' + encodeURIComponent(code)
	request {uri: url, method: 'GET'}, (error, response, body) ->
		if not error and response.statusCode == 200
			try
				res_dict = JSON.parse(body)
			catch e
				res_dict = {access_token: 'error'}
			if res_dict.access_token != 'error'
				access_token = res_dict.access_token
				request {uri: conf.foursquare.baseUrl + 'users/self?oauth_token=' + encodeURIComponent(access_token) + '&v=20131101', method: 'GET'}, (aterr, atres, atbody) ->
					if not error and atres.statusCode == 200
						try
							profile = JSON.parse(atbody)
						catch e
							profile = {error: true, reason: e}
						if profile.error == undefined
							callback({status: 'ok', access_token: access_token, id: profile.response.user.id, profile: profile.response.user})
						else
							callback({status: 'error', reason: 'Error processing response', response: atbody, info: profile.e})
					else
						callback({status: 'error', reason: 'API error from foursquare', response: atbody})
			else
				callback({status: 'error', reason: 'API error from foursquare', response: body})
		else
			callback({status: 'error', reason: 'API error from foursquare', response: body})

#######
# Example: coffee -e 'require("./lib/foursquare.coffee").endpoints.trending "-33.859972,151.211111", (cb) -> console.log cb '
showtrending = (ll, callback) ->
	url = conf.foursquare.baseUrl + 'venues/trending?ll=' + encodeURIComponent(ll) + '&client_id=' + encodeURIComponent(conf.foursquare.accessToken) + '&client_secret=' + encodeURIComponent(conf.foursquare.accessSecret) + '&v=20131101'
	request {uri: url, method: 'GET'}, (error, response, body) ->
		if not error and response.statusCode == 200
			res_dict = JSON.parse(body)['response']
			callback({status: 'ok', venues: res_dict['venues']})
		else
			callback({status: 'error', reason: 'API error from foursquare', response: body})

# Example: coffee -e 'require("./lib/foursquare.coffee").endpoints.categories (cb) -> console.log cb '
showcategories = (callback) ->
	url = conf.foursquare.baseUrl + 'venues/categories?client_id=' + encodeURIComponent(conf.foursquare.accessToken) + '&client_secret=' + encodeURIComponent(conf.foursquare.accessSecret) + '&v=20131101'
	request {uri: url, method: 'GET'}, (error, response, body) ->
		if not error and response.statusCode == 200
			res_dict = JSON.parse(body)['response']
			category_list = []
			for category in res_dict['categories']
				category_list.push {type: 'parent', shortName: category.shortName, catid: category.id}
				for subcat in category.categories
					category_list.push {type: 'child', shortName: subcat.shortName, catid: subcat.id}
			
			callback({status: 'ok', categories: category_list})
		else
			callback({status: 'error', reason: 'API error from foursquare', response: body})

# Example: coffee -e 'require("./lib/foursquare.coffee").endpoints.search.query "Ivy Bar", "330 George St. Sydney Australia", (cb) -> console.log cb'
searchvenue = (name, address, callback) ->
	url = conf.foursquare.baseUrl + 'venues/search?query=' + encodeURIComponent(name) + '&near=' + encodeURIComponent(address) + '&radius=1000&client_id=' + encodeURIComponent(conf.foursquare.accessToken) + '&client_secret=' + encodeURIComponent(conf.foursquare.accessSecret) + '&v=20131101'
	request {uri: url, method: 'GET'}, (error, response, body) ->
		if not error and response.statusCode == 200
			res_dict = JSON.parse(body)['response']
			places = []
			for group in res_dict.groups
				for item in group.items
					places.push item


			callback({status: 'ok', matchlist: places})
		else
			callback({status: 'error', reason: 'API error from foursquare', response: body})


# Example: coffee -e 'require("./lib/foursquare.coffee").endpoints.search.match "Ivy Bar", "330 George St. Sydney Australia", (cb) -> console.log cb'
matchvenue = (name, address, callback) ->
	url = conf.foursquare.baseUrl + 'venues/search?intent=match&query=' + encodeURIComponent(name) + '&near=' + encodeURIComponent(address) + '&radius=1000&client_id=' + encodeURIComponent(conf.foursquare.accessToken) + '&client_secret=' + encodeURIComponent(conf.foursquare.accessSecret) + '&v=20131101'
	request {uri: url, method: 'GET'}, (error, response, body) ->
		if not error and response.statusCode == 200
			res_dict = JSON.parse(body)['response']
			matchedplaces = []
			for group in res_dict.groups
				for item in group.items
					matchedplaces.push item

			mp2 = []
			mp1 = []

			for place in matchedplaces
				if place.verified == true
					mp2.push place
				else
					mp1.push place

			matchedplaces = []	

			# Only put correct ones in
			for place in mp2
				matchedplaces.push place

			# put incorrect ones first (maybe discard it)
			for place in mp1
				matchedplaces.push place

			callback({status: 'ok', matchlist: matchedplaces})
		else
			callback({status: 'error', reason: 'API error from foursquare', response: body})

# Checkin Detail
checkindetail = (info, callback) ->
	if info.accesstoken != undefined and info.checkinid != undefined
		url = conf.foursquare.baseUrl + 'checkins/' + info.checkinid + '?oauth_token=' + info.accesstoken + '&v=20131101'
		request {uri: url, method: 'GET'}, (error, response, body) ->
			if not error and response.statusCode == 200
				cbpayload = {status: 'ok', checkin: checkin}
				try
					checkin = JSON.parse(body).response.checkin
				catch e
					checkin = {}
					cbpayload.status = 'error'
					cbpayload.reason = 'Invalid response returned from foursquare'

				cbpayload.checkin = checkin
				callback(cbpayload)
			else
				callback({status: 'error', reason: 'API error from foursquare', response: body})
	else
		callback({status: 'error', reason: 'bad parameters'})
#######
module.exports = {
	auth: {
		accesstoken: getaccesstoken,
		generateurl: generateredirecturl
	},
	endpoints: {
		trending: showtrending,
		categories: showcategories,
		search: {
			match: matchvenue,
			query: searchvenue
		},
		checkin: checkindetail
	}
}