var action = require('..\\actions')
var assert = require('..\\assertions')

var URL = 'http://localhost/gherkin_editor/index.html';

module.exports = {
	test: function (feature) {
		feature('Example usage', function (scenario) {
			scenario('fill', function() {
				return action.open(URL)
					.then(action.render)
					.then(action.fill('#username', 'trenyika'))
					.then(action.fill('#password', 'alma'))
					.then(action.click('#login'))
//					.then(assert.assertDisplayed('#feature_list'))
					.then(action.scenarioEnd(''))
			})
			
			scenario('add feature', function() {
				return action.open(URL)
					.then(action.render)
					.then(action.fill('#add_new_feature_input', 'new feature'))
					.then(action.click('#add_item_to_feature_list_btn'))
					.then(action.scenarioEnd(''))
			})
			
			scenario('delete feature', function() {
				return action.open(URL)
					.then(action.render)
					.then(action.clickItemInSelectList('#feature_list a', 'new feature'))
					.then(action.click('#delete_item_from_feature_list_btn'))
					.then(action.click('#delete_feature_dialog_btn'))
					.then(assert.selectList('#feature_list a', ["asfasdfasdf", "egy", "egyujfeature", "harom", "jjjjjjj", "proba"]))
					.then(action.scenarioEnd(''))
			})
			
			scenario('end', function() {
				return action.open(URL)
					.then(action.render)
					.then(action.scenarioEnd(''))
			})
		})
	}
}