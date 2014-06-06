// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
(function(T) {
	var loaded_count;
	var tweeters;
	var updates = {}; 
	var loaded = {};
	var active = {};
	var skip_updated = false;
	
	/* ===============
		Ajax
	==================*/

	T.load_description = function( user_id ) {
		$.ajax({
			url: gon.tweeter_load_description_url,
			data: JSON.stringify({ user_id: user_id}),
			dataType: 'json',
			success: T.render_description,
			error: function(){console.log("couldn't load uid: " + user_id );}
		});

	};

	T.load_tweets = function(user_id) {
		$.ajax({
			url: gon.tweeter_load_timeline_url,
			data: JSON.stringify({ user_id: user_id}),
			dataType: 'json',
			success: T.render_tweets,
			error: function(){console.log("couldn't load uid: " + user_id ); loaded[user_id] = false;}
		});
	};

	T.update_tweets = function() {
		if ( T.update_tweets.active ) {
			return;
		}
		T.update_tweets.active = true;
		$.ajax({	
			url: gon.tweeter_update_many_url,
			data: JSON.stringify({ updates: updates }),
			dataType: 'json',
			success: function() { alert("update success"); updates = {}; },
			error: function() { console.log("couldn't update"); },
			complete: function() { T.update_tweets.active = false;}
		});
	};

	T.update_tweets.active = false;

	T.add_users = function ( jqEvent ) {
		if ( T.add_users.active ) {
			return;
		}
		T.add_users.active = true;
		var $textarea = jqEvent.data;
		var text = $textarea.val(); 
		var data = {
			user_ids: text.trim().split(/\s+/)
		};
		$.ajax({	
			url: gon.tweeter_add_many_url,
			data: JSON.stringify(data),
			dataType: 'json',
			success: function(result){alert("Update success. " + result.count + " new records."); },
			error: function(){alert("failed. check error log");},
			complete: function() { T.add_users.active = false;}
		});
	};

	T.add_users.active = false; 
	/*================
		UI
	================*/

	T.render_tweets = function( timeline ) {
		var tuid = timeline.user_id; 
		var html = HandlebarsTemplates['tweeters/timeline_table'](timeline);
		$('.timeline[data-tuid='+tuid+']').append(html);
		$('.tweeter-header-info[data-tuid='+tuid+']').append("Timeline Loaded");

	};

	T.render_example_description = function( user_info ) {
		var tuid = user_info.user_id;
		var sTuid = String(tuid);
		
		user_info.local_idx = 0; 
		var html = HandlebarsTemplates['tweeters/show_user']( user_info );
		$('#tweeter-container').append(html);

		T.render_tweets( user_info );

	};

	T.render_description = function( user_info ) {
		var tuid = user_info.user_id;
		var sTuid = String(tuid);
		var tweeter = active[sTuid];
		
		user_info.local_idx = tweeter.idx; 
		var html = HandlebarsTemplates['tweeters/show_user']( user_info );
		$('#tweeter-container').append(html);

		var $spam = $('.tweeter-form-wrapper[data-tuid='+tuid+'] .spam-check');
		var $cohort = $('.tweeter-form-wrapper[data-tuid='+ tuid +'] .cohort-check');
		var $info = $('.tweeter-form-wrapper[data-tuid='+ tuid +'] .info-text'); 
		$spam.on('click', null, tuid, check);
		$cohort.on('click', null, tuid, check);
		$info.on('change', null, tuid, edit_text);

		set_check($spam, tweeter.spam);
		set_check($cohort, tweeter.cohort);
		$info.val(tweeter.info);
		$('.tweeter-load-btn[data-tuid=' + tuid + ']').click(
			function (){
				if (sTuid in loaded && loaded[sTuid]) {
					return;
				} else {
					T.load_tweets(sTuid);
					loaded[sTuid] = true;
				}
			});

	};

	function check_val( $obj ) {
		return ( $obj.prop('checked') ) ? "yes" : "no";
	}

	function set_check( $obj, value) {
		if ( value === 'yes' ) {
			value = true;
		} else if ( value === 'no' ) {
			value = false;
		} else {
			value = !!value;
		}
		$obj.prop('checked', value);
	}

	function load_next_user() {
		console.log("next user.");
		while ( loaded_count < tweeters.length &&
				skip_updated &&
				tweeters[loaded_count].updated ) 
		{
			loaded_count ++;
		}

		if ( loaded_count < tweeters.length ) {
			var tweeter = tweeters[loaded_count];

			T.load_description(tweeter.twitter_user_id);
			active[tweeter.twitter_user_id] = {
				spam: tweeter.spam,
				info: tweeter.info,
				cohort: tweeter.cohort,
				updated: tweeter.updated,
				idx: loaded_count };
			loaded_count ++;
		} else {
			alert("Done! No users left in queue");
		}
	}

	function update_row(tuid) {	
		var update;
		if (! (tuid in updates)) {
			update = updates[tuid] = active[tuid]; 
		} else {
			update = updates[tuid];
		}
		return update;
	}

	function edit_text( obj ) {
		var tuid = String(obj.data);
		update = update_row(tuid);
		update.info = $(this).val();
	}

	function check( obj ) {
		var tuid = String(obj.data);
		update = update_row(tuid);

		update.cohort = check_val($('.cohort-check', $(this).parent()));
		update.spam = check_val($('.spam-check', $(this).parent()));
	}

	function init_show_ui(){
		tweeters = T.tweeters = gon.tweeters;
		loaded_count = 0; 
		$('#tweeter-next-btn').click(load_next_user);
		$('#tweeter-update-btn').click(T.update_tweets);
		$('#tweeter-skip-updated-check').click(function(){
			skip_updated = $(this).prop('checked');
		});
	}

	function init_add_ui() {
		var $textarea = $('#tweeter-add-text');
		var $button = $('#tweeter-add-btn');
		$button.on('click', null, $textarea, T.add_users);
	}

	/*================
		Initialization
	================*/	

	T.init = function() {
		if (!window.gon) {
			return;
		}
		$.ajaxSetup({
			contentType: 'application/json',
			dataType: 'json',
			type: 'POST'
		});
		if (gon.tweeters){
			init_show_ui();
		} else if (gon.tweeter_add) {
			init_add_ui();
		}
	};	

	$(function(){
		T.init(); 
	});

})(window.Tweeter || (window.Tweeter = {}));