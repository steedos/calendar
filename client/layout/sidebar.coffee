import Calendar from '../core'

calendarsDep = new Tracker.Dependency;
calendarsSub = new SubsManager();
calendarsRange = null
calendarsLoading = false


Template.calendarSidebar.helpers 
	calendars: ()->
		return Calendars.find()

Template.calendarSidebar.onRendered ->
	# 读取并刷新
	calendarsSub.subscribe "calendars"

Template.calendarSidebar.events 

	'click a.calendar-add': (event)->
		$('.btn.calendar-add').click();

	'click i.calendar-edit': (event)->
		Session.set("cmDoc", this);
		$('.btn.calendar-edit').click();

	'click i.calendar-delete': (event)->
		# $('.btn.calendar-delete').click();
		console.log(this);
		delete_id=this._id;
		swal({
		  title: "删除日历",
		  text: "你确定删除此日历吗？与此日历相关联的事件也都将被删除。",
		  type: "warning",
		  showCancelButton: true,
		  cancelButtonText:"取消",
		  confirmButtonColor: "#DD6B55",
		  confirmButtonText: "确定",
		  closeOnConfirm: false,
		  html: false
		},
		# 删除表中的记录
		()->
		  # this._id取值无法删除，删除失败,this未定义
		  console.log(this._id+"   "+delete_id);
		  Calendars.remove({_id:delete_id});
		  swal("删除成功","日历已被删除！","success");
		);