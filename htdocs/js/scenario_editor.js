var SCENARIOS_IN_FEATURE = new Object();
function init_page_DB() {
    var processed_data = new Object();

    push_cmd("get_feature_list", JSON.stringify({'get': 1 }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({'get': 1 }));
	push_cmd("get_scen_list", JSON.stringify({'get': 1 }));
    processed_data = processor(send_cmd());

    FEATURE_SELECT_LIST  = processed_data['get_feature_list'];
    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
	SCENARIO_SELECT_LIST = processed_data['get_scen_list'];
}


function fill_feature_list()
{
    var feature_list = create_select_list('feature_list_name', 'feature_list', FEATURE_SELECT_LIST, null, { "prefix" : FEATURE_PREFIX, "id" : "FeatureID", "name" : "Title" } );

    document.getElementById("feature_list_container").innerHTML = "";
    document.getElementById("feature_list_container").appendChild(feature_list);
    set_features_to_empty();
    set_css_for_none_empty_feature_list();

    create_button_as_img('delete_item_from_feature_list_btn', Are_you_sure_you_want_to_delete_feature, "Add sentence", "img/clear.png");
    create_button_as_img('add_item_to_feature_list_btn', add_new_feature_to_feature_list, "Add item", "img/add.png");

}

function fill_scenario_list() {
    document.getElementById("scenario_list").innerHTML = "";
    var scenario_list = create_select_list('scenario_list_name', 'scenario_list', SCENARIO_SELECT_LIST, null, { "prefix" : FEATURE_PREFIX, "id" : "ScenarioID", "name" : "Description" });
	
    document.getElementById("scenario_list_container").innerHTML = "";
    document.getElementById("scenario_list_container").appendChild(scenario_list);
    //set_scen_list_items_to_empty();
    //set_css_for_empty_scenarios();

    create_button_as_img('delete_item_from_scenario_list_btn', Are_you_sure_you_want_to_delete_scenario, "Add sentence", "img/clear.png");
    create_button_as_img('add_item_to_scenario_list_btn', add_new_scenario_to_scenario_list, "Add item", "img/add.png");	
}

function add_new_scenario_to_scenario_list() {
    var scenario_name= document.getElementById("add_new_scenario_input").value;

	$('#add_new_scenario_input').val('');
    push_cmd("add_new_scen_to_scenlist", JSON.stringify({
        'Description': scenario_name,
    }));
    processor(send_cmd());
	
	update_scenario_list();
}

function set_css_for_none_empty_feature_list() {
    for (var item in FEATURE_SCENARIO_IDS) {
        var fea_selectlist = document.getElementById(FEATURE_PREFIX + FEATURE_SCENARIO_IDS[item]['FeatureID']);
        fea_selectlist.setAttribute('class', 'not_empty');
    }
}

function set_features_to_empty() {
    var fea_selectlist;
    var id;

    for (var item in FEATURE_SELECT_LIST) {
        id = FEATURE_PREFIX + FEATURE_SELECT_LIST[item]['FeatureID'];
        fea_selectlist = document.getElementById(id);
        fea_selectlist.setAttribute('class', 'empty');
    }
}

function add_new_feature_to_feature_list() {
    var feature_name = document.getElementById('add_new_feature_input').value;

    $('#add_new_feature_input').val('');

    push_cmd("add_new_fea_to_fealist", JSON.stringify({
        'Title': feature_name
    }));
    processor(send_cmd());

    update_feature_and_scenario_list();
}

function Are_you_sure_you_want_to_delete_feature() {
    var feature_name = get_feature_name_by_id( document.getElementById("feature_list").value );

    $("#Delete_feature_from_feature_list").dialog({
        width: 800,
        height: 200,
        position: [600, 600],
        title: "Are you sure do you want" + "\n" + "to delete: " + feature_name + " feature?",
        buttons:
        {
            "Delete scenarios": {
                text: 'Delete feature',
                click: function() {
                    $(this).dialog("close");
                    var feature_id = document.getElementById("feature_list").value;
                    delete_item_from_feature_list( feature_id );
                }

            },
            "Cancel": {
                text: 'Not now',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    });
}

function delete_item_from_feature_list( feature_id ) {
    clear_feature( feature_id );
    update_feature_and_scenario_list();
}

function clear_feature(selected_fea_id) {
    clear_feature_HTML();
    push_cmd("delete_feature", JSON.stringify({
        'FeatureID': selected_fea_id
    }));
    processor(send_cmd());
}

function update_feature_and_scenario_list() {
    push_cmd("get_feature_list", JSON.stringify({
        'get': 1
    }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({
        'get': 1
    }));
    var processed_data = processor(send_cmd());

    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
	FEATURE_SELECT_LIST  = processed_data['get_feature_list'];

    fill_feature_list();
}

 function update_scenario_list() {
    var processed_data = {};

    push_cmd("get_scen_list", JSON.stringify({
        'get': 1
    }));

    processed_data = processor(send_cmd());

    SCENARIO_SELECT_LIST  = processed_data['get_scen_list'];

    fill_scenario_list();	
	
}

function get_feature_name_by_id(selected_fea_id) {
    for (var item in FEATURE_SELECT_LIST) {
        if (FEATURE_SELECT_LIST[item]['FeatureID'] == selected_fea_id) {
        	return FEATURE_SELECT_LIST[item]['Title'];
        }
    }
}

function get_featext() {
	alert( 'get_featext' );
	
}

function get_locked_status() {
    Feature_status(true);
    Scenario_status(true);
}

function Scenario_status(async) {
    var ret_val = new Object();
    push_cmd("get_scenario_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);

    } else {
        ret_val = processor(send_cmd(async), ret_val);
    }
    return ret_val['get_scenario_locked_status'];
}

function Feature_status(async) {
    var ret_val = new Object();
    push_cmd("get_feature_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);

    } else {
        ret_val = processor(send_cmd(async), ret_val);
    }
    return ret_val['get_feature_locked_status'];
}


function locked_status(table) {
    if (table['table'] == "FeatureID") {
        if (feature_is_locked(table['id'])) {
            FEATURE_LOCKED_BY_ME = false;
            $("a[href='#select_sentence']").css('display', 'none');
        } else {
            FEATURE_LOCKED_BY_ME = true;
            set_Feature_locked(table['id']);
            $("a[href='#select_sentence']").css('display', 'inline');
        }
    } else if (table['table'] == "ScenarioID") {
        if (scenario_is_locked(table['id'])) {
            SCENARIO_LOCKED_BY_ME = false;
            $("a[href='#select_sentence']").css('display', 'none');
        } else {
            SCENARIO_LOCKED_BY_ME = true;
            set_Scenario_locked(table['id']);
            $("a[href='#select_sentence']").css('display', 'inline');
        }
    }
}

function init_page() {
	var feature_id,
	    feature_name,
	    get_fea_text;
		
	//get_fea_text = create_button_as_img("get_featext", get_featext, "", "img/get_fea_text.png");
	//document.getElementById("Feature-input").appendChild(get_fea_text);	
	
    init_page_DB();
    fill_feature_list();
	fill_scenario_list();

    $("#locked_status").show();

    sortable_li();

    document.getElementById('feature_list').ondblclick = select_feature;
    document.getElementById('scenario_list').ondblclick = add_scenario_to_feature;

	
    setInterval(function() {
        get_locked_status();
    }, 10000);
    
}

function select_feature () {
	feature_id = document.getElementById("feature_list").value;
	feature_name = get_feature_name(feature_id);
	    	
	if (-1 == ACTUAL_FEATURE) {
        ACTUAL_FEATURE = feature_id;
        locked_status({
            'table': 'FeatureID',
            'id': ACTUAL_FEATURE
        });

    } else {

        if (FEATURE_LOCKED_BY_ME == true) {
            set_Feature_unlocked(ACTUAL_FEATURE);
            ACTUAL_FEATURE = feature_id;
            locked_status({
                'table': 'FeatureID',
                'id': ACTUAL_FEATURE
            });
        } else {
            ACTUAL_FEATURE = feature_id;
            locked_status({
                'table': 'FeatureID',
                'id': ACTUAL_FEATURE
            });
        }
    }
	modify_feature();    	
}

function add_scenario_to_feature() {
    var selected_scen_id   = document.getElementById("scenario_list").value;
    var li_number          = get_li_number_from_id("Scenarios_in_Feature");
    var selected_scen_name = get_scenario_name(selected_scen_id);
    var li_id              = "scenario_in_feature" + li_number;

    add_new_scenario_to_feature({
        'feature_id'   : ACTUAL_FEATURE,
        'scenario_id'  : selected_scen_id,
        'scenario_data': selected_scen_name,
        'scen_infea_id': li_id,
        'position'     : li_number,
    });

    update_scenario_list_in_feature();
}

function add_new_scenario_to_feature(ids) {
    push_cmd("add_scen_to_fea", JSON.stringify({
        'FeatureID' : ids['feature_id'],
        'ScenarioID': ids['scenario_id'],
        'Position'  : ids['position'],
    }));
    processor(send_cmd());
}

function get_li_number_from_id(id) {
    return document.getElementById(id).childNodes.length;
}

function get_feature_name() {
    for (var item in FEATURE_SELECT_LIST) {
        if (FEATURE_SELECT_LIST[item]['FeatureID'] == ACTUAL_FEATURE) {
            return FEATURE_SELECT_LIST[item]['Title'];
        }
    }
}

function get_scenario_name(scenario_id) {
    var selected_scen_name;
    for (var item in SCENARIO_SELECT_LIST) {
        if (SCENARIO_SELECT_LIST[item]['ScenarioID'] == scenario_id) {
            selected_scen_name = SCENARIO_SELECT_LIST[item]['Description'];
            break;
        }
    }
    return selected_scen_name;
}

function set_Feature_locked(feature_id) {
    if (feature_id != -1) {
        push_cmd("Feature_is_locked", JSON.stringify({
            'FeatureID': feature_id
        }));
        processor(send_cmd());
    }
}

function set_Feature_unlocked(feature_id) {
    if (feature_id != -1) {
        push_cmd("Feature_is_unlocked", JSON.stringify({
            'FeatureID': feature_id
        }));
        processor(send_cmd())
    }
}

function sortable_li() {
    $(function() {
        $("ul.droptrue").sortable({
            connectWith: "ul",
            dropOnEmpty: true
        }).disableSelection();

        $("#recycle_for_sentences, #selected_sentence_sortable").sortable({
            connectWith: "ul",
            dropOnEmpty: true,
            stop: function(event, ui) {
                recycler(event, ui);
            }
        }).disableSelection();
    });

    $(function() {
        $("#selected_sentence_sortable_without_fea, #scenario_text_without_fea").sortable({
            connectWith: ".connectedSortable"
        }).disableSelection();
    });

    $(function() {
        $("#Scenarios_in_Feature").sortable();
        $("#Scenarios_in_Feature").disableSelection();
    });
}

function feature_is_locked(feature_id) {
    $("a[href='#select_sentence']").css('display', 'inline');
    var fea_ids = Feature_status(false);

    for (var item in fea_ids) {
        if (fea_ids[item]['FeatureID'] == feature_id) {
            return fea_ids[item]['LockedStatus'];
        }
    }
}

function Feature_status(async) {
    var ret_val = new Object();
    push_cmd("get_feature_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);

    } else {
        ret_val = processor(send_cmd(async));
    }
    return ret_val['get_feature_locked_status'];
}

function modify_feature() {
    open_dialog_for_scenarios_in_feauture();
    update_scenario_list_in_feature();
}

function open_dialog_for_scenarios_in_feauture() {
	//delete_scen_from_fea_btn1 = create_button_as_img("del_scen_from_fea_btn_" + li_id, delete_scenario_from_fea_dialog, "Add scenario", "img/clear.png");
	
	create_button_as_img('close_feature', close_feature, 'Close Feaure', "img/clear.png");
	create_button_as_img('are_you_sure_clear_feature', are_you_sure_clear_feature, 'Clear Feaure', "img/clear.png");
	create_button_as_img('save_scenarios_to_feature',  save_scenarios_to_feature,  'Save Feaure', "img/add.png");

    //$('#get_feature_text').hide();

    var ret_val = save_feature_file();
    //create_link_for_DownloadFile( ret_val['Save_Feature'], 'get_feature_text');
    document.getElementById("Scenarios_in_Feature_title").innerHTML = "Selected feature: " + get_feature_name_by_id(ACTUAL_FEATURE);
}

function close_feature () {
    if (FEATURE_LOCKED_BY_ME == true) {
        set_Feature_unlocked(ACTUAL_FEATURE);
        clear_feature_HTML();
        document.getElementById("Scenarios_in_Feature_title").innerHTML = 'No feature selected';
    }
}

function clear_feature_HTML() {
    var li_list = $("#Scenarios_in_Feature").children();
    li_list.remove();
}


//TODO: refactor
function update_scenario_list_in_feature() {
	var scenario_list_in_fea,
	    li_id,
		scenario_in_feature,
	    modify_scen,
	    scenario_id,
		scenario_name,
		scenario_data;
	
	
    scenario_list_in_fea = get_scen_list_by_feature();
    delete_scenariolist_in_feature_HTML();
	
    if (scenario_list_in_fea == null) {
		return 0;

    } else {
        for (var i = 0; i < scenario_list_in_fea.length; i++) {
            li_id               = "scenario_in_feature" + i;
            scenario_in_feature = "scenario_in_feature" + i;

            delete_scen_from_fea_btn1 = create_button_as_img("del_scen_from_fea_btn_" + li_id, delete_scenario_from_fea_dialog, "Add scenario", "img/clear.png");
            edit_scen_from_fea_btn1 = create_button_as_img("edit_scen_from_fea_btn_" + li_id, edit_scenario, "Add scenario", "img/Edit-Document-icon.png");
            modify_scen = create_button_as_img("edit_scen_from_fea_btn_" + li_id, rename_scenario_HTML, "Add scenario", "img/update.png");

            scenario_id = scenario_list_in_fea[i]['ScenarioID'];
            scenario_name = get_scenario_name(scenario_list_in_fea[i]['ScenarioID']);
            scenario_data = scenario_name;

            $("#Scenarios_in_Feature").append(create_li({
                "id": li_id,
                'value': scenario_id
            }));
            $("#" + li_id).text(scenario_name);

            $("#" + li_id).append(delete_scen_from_fea_btn1);

            $("#" + li_id).append(edit_scen_from_fea_btn1);

            $("#" + li_id).append(modify_scen);

            SCENARIOS_IN_FEATURE[li_id] = {
                'btn_list': [edit_scen_from_fea_btn1, delete_scen_from_fea_btn1],
                'scenario_id': scenario_list_in_fea[i]['ScenarioID'],
                "scenario_in_fea": scenario_in_feature,
                "li_id": li_id,
            };
        }
        selected_fea_id_prev = document.getElementById("feature_list").value;
    }
}

function edit_scenario(DIALOG_WITHOUT_FEATURE) {
	alert('edit_scenario');
}

function rename_scenario_HTML() {
	alert('rename_scenario_HTML');
}

function delete_scenariolist_in_feature_HTML() {
    var scenariolist_in_feature = document.getElementById("Scenarios_in_Feature");

    while (scenariolist_in_feature.firstChild) {
        scenariolist_in_feature.removeChild(scenariolist_in_feature.firstChild);
    }
}

function get_scen_list_by_feature() {
    push_cmd("get_scen_list_by_fea", JSON.stringify({
        'FeatureID': ACTUAL_FEATURE
    }));
    var ret_val = processor(send_cmd());
    return ret_val['get_scen_list_by_fea'];
}

/*
function create_link_for_DownloadFile () {
	alert('create_link_for_DownloadFile');
}
*/

function Are_you_sure_you_want_to_delete_scenario() {
    var selected_scen_id,
	    scenario_name, 
	    num_of_feas;
	
	selected_scen_id = document.getElementById("scenario_list").value;
    scenario_name    = get_scenario_name(selected_scen_id);
	num_of_feas      = get_feature_number_by_scen_id(selected_scen_id);
	
    if (num_of_feas !== null) {
		create_used_fealist();
        $("#Delete_scenario_from_features").dialog({
            width: 400,
            height: 400,
            position: [600, 600],
            buttons: {
                "Delete scenarios": {
                    text: 'Delete scenario',
                    click: function() {
                        delete_item_from_scenario_list(selected_scen_id);
						$(this).dialog("close");
                    }

                },

                "Cancel": {
                    text: 'Not now',
                    click: function() {
                        $(this).dialog("close");
                    }
                }
            }
        });
    } else {
        $("#Delete_scenario").dialog({
            width: 250,
            height: 50,
            position: [600, 600],
            buttons: {
                "Delete scenarios": {
                    text: 'Delete scenario',
                    click: function() {
                        clear_scenario();
                    }

                },

                "Cancel": {
                    text: 'Not now',
                    click: function() {
                        $(this).dialog("close");
                    }
                }
            }
        });
    }
}

function get_feature_number_by_scen_id() {
    var ret_val = {};
    ret_val['get_features_by_scenario_id'] = 1;

    push_cmd("get_features_by_scenario_id", JSON.stringify({
        'fea_scen.ScenarioID': document.getElementById("scenario_list").value
    }));

    ret_val = processor(send_cmd());
 
    return ret_val['get_features_by_scenario_id'];
}

function delete_item_from_scenario_list(scen_id) {
    push_cmd("delete_scen_from_fea", JSON.stringify({
        'ScenarioID': scen_id,
        'FeatureID': document.getElementById("feas_by_scen").value
    }));
    processor(send_cmd());
    update_scenario_list_in_feature();
    var number_of_feas_cont_scen = get_feature_number_by_scen_id(scen_id);
    if (number_of_feas_cont_scen == null) {
        $('#Delete_scenario_from_features').dialog("close");
    }
}

function create_used_fealist() {
    var ret_val,
	    feature_list;
	
	push_cmd("get_features_by_scenario_id", JSON.stringify({
        'fea_scen.ScenarioID': document.getElementById("scenario_list").value
    }));
	
    ret_val      = processor(send_cmd(), ret_val);
    feature_list = create_select_list('feas_by_scen', 'feas_by_scen', ret_val['get_features_by_scenario_id'], null, { "prefix" : FEATURE_PREFIX, "id" : "FeatureID", "name" : "Title" });

	document.getElementById("features_by_scenario").appendChild(feature_list);	
}

function clear_scenario() {
    push_cmd("clear_scen", JSON.stringify({
        'ScenarioID': document.getElementById("scenario_list").value
    }));
    processor(send_cmd());

    //create_scen_list();
    update_scenario_list();
    update_scenario_list_in_feature();

    $("#Delete_scenario").dialog("close");
}

function are_you_sure_clear_feature() {
    var feature_name = get_feature_name(ACTUAL_FEATURE);

    $("#Are_you_sure").dialog({
        width: 800,
        height: 200,
        position: [600, 600],
        buttons:
        {
            "Delete scenarios": {
                text: 'Delete all scenarios',
                click: function() {
                    $(this).dialog("close");
                    clear_feature(ACTUAL_FEATURE);
                    update_scenario_list_in_feature();
                    update_feature_and_scenario_list();
                }
            },
            "Cancel": {
                text: 'Not now',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    });

    $('#Are_you_sure').dialog('option', 'title', "Are you sure do you want" + "\n" + "to delete all scenarios" + "\n" + "from " + feature_name + " feature?");
}

function save_scenarios_to_feature() {
    SAVE_SCENARIO_DATAS = {};
    var scenarios = check_selected_scenarios_for_database_saving();

    save_scenarios_in_feature({
        'feature_id': ACTUAL_FEATURE,
        'scenlist': scenarios,
    });

    update_feature_and_scenario_list();
    modify_feature();
}

function save_scenarios_in_feature(Scenario_datas) {
    push_cmd("save_scenarios_to_feature", JSON.stringify({
        'FeatureID': Scenario_datas['feature_id'],
        'ScenarioList': Scenario_datas['scenlist']
    }));
    processor(send_cmd());
}

function check_selected_scenarios_for_database_saving() {
    var sentence_number = $("#Scenarios_in_Feature").children().length;
    var li_gherkin_list = $("#Scenarios_in_Feature").children();
    var scenario_in_feature = [];

    for (var i = 0; i < sentence_number; i++) {
        scenario_in_feature[i] = li_gherkin_list[i].value;
    }

    return scenario_in_feature;
}

function clear_feature_HTML() {
    var li_list = $("#Scenarios_in_Feature").children();
    li_list.remove();
}

function save_feature_file() {
    push_cmd("Save_Feature", JSON.stringify(  {
			'FeatureName'   : get_feature_name( ACTUAL_FEATURE )  ,
			'FeatureText'   : get_gherkin_text_by_feature()   ,
    } ) ) ;

    return processor( send_cmd() );
}

function get_gherkin_text_by_feature() {
	//alert('get_gherkin_text_by_feature');
}

function delete_scenario_from_fea_dialog() {
    var scenario_id = get_scen_id_by_btn_id(this.id, 1);
    var row_id = this.id;

    $("#Are_you_sure").dialog({
        width: 500,
        height: 150,
        position: [600, 600],
        buttons:
        {
            "Delete scenario": {
                text: 'Delete scenario',
                click: function() {
                    $(this).dialog("close");
                    delete_scen_from_fea(row_id, scenario_id);
                    save_scenarios_to_feature();
                }
            },

            "Cancel": {
                text: 'Cancel',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    });
    var selecte_fea_name;
    var scenario_name = get_scenario_name(scenario_id);

    selecte_fea_name = get_feature_name_by_id(ACTUAL_FEATURE);
    var delete_scenario_from_fea = " Are you sure you want to delete: " + scenario_name + "scenario from" + selecte_fea_name + "feature";
    document.getElementById("Are_you_sure").innerHTML = delete_scenario_from_fea;
}

function delete_scen_from_fea(row_id, act_scen_id) {
    var li_id = get_li_id_from_row_id(row_id);

    delete_selected_li_from_HTML(li_id);
    delete_ids_from_scen_list_by_row_id(li_id);
}

function get_li_id_from_row_id(row_id) {
    var li_id = row_id.replace("del_scen_from_fea_btn_", "");
    return li_id;
}

function delete_selected_li_from_HTML(li_id) {
    $("#" + li_id).remove();
}

function delete_ids_from_scen_list_by_row_id(row_id) {
    if (SCENARIOS_IN_FEATURE.hasOwnProperty(row_id)) {
        delete SCENARIOS_IN_FEATURE[row_id];
    }
}

function get_scen_id_by_btn_id(btn_id, isDeleteBtn) {
    var btn_idx = 0;
    isDeleteBtn ? btn_idx = 1 : btn_idx = 0;

    for (var idx in SCENARIOS_IN_FEATURE) {
        if (SCENARIOS_IN_FEATURE[idx]['btn_list'][btn_idx].id == btn_id) {
            return SCENARIOS_IN_FEATURE[idx]['scenario_id'];
        }
    }
    return -1;
}