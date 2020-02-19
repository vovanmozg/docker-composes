require 'rest-client'

response = RestClient.get('https://api.trello.com/1/batch?urls=/members/trello/', {})
p response.body

