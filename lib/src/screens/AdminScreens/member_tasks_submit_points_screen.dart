import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ftc_application/blocs/adminBloc/admin_event.dart';
import 'package:ftc_application/blocs/notificationBloc/bloc.dart';
import 'package:ftc_application/src/models/PushNotificationRequest.dart';
import 'package:ftc_application/src/models/Task.dart';
import 'package:ftc_application/src/models/route_argument.dart';
import 'package:ftc_application/config/app_config.dart' as config;
import 'package:ftc_application/src/widgets/AdminScreenWidgets/PointsSubmissionWidgets/submit_points_task_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ftc_application/blocs/adminBloc/admin_bloc.dart';
import 'package:ftc_application/src/widgets/loading_widget.dart';
import 'package:ftc_application/blocs/memberTasksBloc/bloc.dart';

class SubmitPointsMemberScreen extends StatefulWidget {
  final RouteArgument routeArgument;
  SubmitPointsMemberScreen({required this.routeArgument});

  @override
  _SubmitPointsMemberScreenState createState() =>
      _SubmitPointsMemberScreenState();
}

class _SubmitPointsMemberScreenState extends State<SubmitPointsMemberScreen> {
  Completer<void> _refreshCompleter = new Completer();
  late List<Task> tasks;
  late String memberName;
  late int jobId;
  late int memberId;

  @override
  void initState() {
    super.initState();
    _setRouteArguments();
    BlocProvider.of<MemberTasksBloc>(context)
        .add(GetMemberJobTasks(jobId: jobId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemberTasksBloc, MemberTasksState>(
        builder: (context, taskState) {
      if (taskState is InitialMemberTasksState) {
        BlocProvider.of<MemberTasksBloc>(context)
            .add(GetMemberJobTasks(jobId: jobId));
        return LoadingWidget();
      } else if (taskState is MemberTasksLoading) {
        return LoadingWidget();
      } else if (taskState is MemberTasksLoaded) {
        tasks = taskState.memberTasks;
        tasks.removeWhere((item) => item.approvalStatus != "READY");
        return _memberTasks();
      } else {
        BlocProvider.of<MemberTasksBloc>(context)
            .add(GetMemberJobTasks(jobId: jobId));
        return LoadingWidget();
      }
    });
  }

  Widget _memberTasks() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            memberName,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          backgroundColor: Colors.deepPurpleAccent,
        ),
        body: RefreshIndicator(
          onRefresh: () {
            BlocProvider.of<MemberTasksBloc>(context)
                .add(RefreshMemberTasks(jobId: jobId));
            return _refreshCompleter.future;
          },
          child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    config.Colors().mainColor(1),
                    config.Colors().accentColor(.8),
                  ],
                ),
              ),
              child: _memberTasksList()),
        ),
      ),
    );
  }

  Widget _memberTasksList() {
    return tasks.length > 0
        ? ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, count) {
              return SubmitPointsTaskCard(
                task: tasks[count],
                submit: _submitPoints,
                index: count,
              );
            })
        : Center(
            child: Text(
            'ماعنده اعمال جديده',
            style: Theme.of(context)
                .textTheme
                .headline2!
                .merge(TextStyle(color: Colors.white, fontSize: 24)),
          ));
  }

  _submitPoints(Task task, Map<String, dynamic> payload, int index) {
    BlocProvider.of<AdminBloc>(context)
        .add(UpdateTask(taskId: task.id, payload: payload));

    BlocProvider.of<NotificationBloc>(context).add(SendMemberMessage(
        memberId: memberId,
        notification: PushNotificationRequest.message(
            'أعمالك', "الرئيس رصد وحده من اعمالك")));
    setState(() {
      tasks.remove(task);
    });
  }

  _setRouteArguments() {
    memberName = widget.routeArgument.argumentsList[0] as String;
    jobId = widget.routeArgument.argumentsList[1] as int;
    memberId = widget.routeArgument.argumentsList[2] as int;
  }
}
