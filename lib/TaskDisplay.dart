import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:altstack/Tasks/Tasks.dart'; // Importing necessary files
import 'package:altstack/Tasks/Tasks_database_helper.dart';
import 'dart:io';
import 'dart:ui';

class TaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the keyboard doesn't resize the screen
      body: Stack(
        children: [
          CounterWithUltraGradients(), // Background counter
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TaskPageView(), // Display of task page view
            ),
          ),
        ],
      ),
    );
  }
}

class TaskPageView extends StatefulWidget {
  @override
  _TaskPageViewState createState() => _TaskPageViewState();
}

class _TaskPageViewState extends State<TaskPageView> {
  final SlidableController _slidableController = SlidableController();
  List<TaskEvent>? _classEvents; // List of task events

  @override
  void initState() {
    super.initState();
    _getClassEvents(); // Fetching task events from the database
  }

  // Function to fetch task events from the database
  Future<void> _getClassEvents() async {
    final allClassEvents = await ClassEventDatabaseHelper().getAllClassEvents();
    setState(() {
      _classEvents = allClassEvents;
    });
  }

  // Function to refresh the list of task events
  Future<void> _refresh() async {
    await _getClassEvents();
  }

  @override
  Widget build(BuildContext context) {
    return _classEvents == null
        ? Center(child: CircularProgressIndicator()) // Display progress indicator while data is loading
        : RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _classEvents!.length,
              itemBuilder: (context, index) {
                return _buildClassBox(_classEvents![index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddTaskDialog(context, TaskEvent(taskName: "", description: ""));
              },
              child: Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build a task event widget
  Widget _buildClassBox(TaskEvent classEvent) {
    bool isCompleted = classEvent.isCompleted == 'YES'; // Checking if task is completed

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          _showEditTaskDialog(context, classEvent); // Display edit task dialog on tap
        },
        child: Slidable(
          key: Key(classEvent.id.toString()),
          controller: _slidableController,
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.25,
          child: Card(
            color: isCompleted ? Colors.grey : Colors.white, // Color of the task card
            child: ListTile(
              title: Text(
                classEvent.taskName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Font size of the task name
                  decoration: isCompleted ? TextDecoration.lineThrough : null, // Strikethrough if completed
                ),
              ),
              subtitle: Text(
                '${classEvent.description} ',
                style: TextStyle(
                  fontSize: 16, // Font size of the task description
                ),
              ),
              trailing: Checkbox(
                value: isCompleted,
                onChanged: (value) async {
                  setState(() {
                    isCompleted = value!;
                    classEvent.isCompleted = isCompleted ? 'YES' : 'NO'; // Update completion status
                  });
                  // Update the completion status in the database
                  await ClassEventDatabaseHelper().updateCompletionStatus(classEvent.id!, classEvent.isCompleted);
                },
              ),
            ),
          ),
          secondaryActions: <Widget>[
            // Delete action for task event
            IconSlideAction(
              caption: 'Delete',
              color: Colors.transparent,
              iconWidget: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onTap: () async {
                await _deleteClassEvent(classEvent); // Delete task event
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to display edit task dialog
  void _showEditTaskDialog(BuildContext context, TaskEvent classEvent) {
    TextEditingController classNameController = TextEditingController(text: classEvent.taskName);
    TextEditingController startTimeController = TextEditingController(text: classEvent.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: classNameController,
                decoration: InputDecoration(labelText: 'Task Name'),
              ),
              TextField(
                controller: startTimeController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String className = classNameController.text;
                String startTime = startTimeController.text;

                if (className.isNotEmpty && startTime.isNotEmpty) {
                  // Update existing class event with new details
                  classEvent.taskName = className;
                  classEvent.description = startTime;

                  // Update the class event in the database
                  await ClassEventDatabaseHelper().updateClassEvent(classEvent);

                  // Refresh the screen by updating the list of class events
                  _getClassEvents();

                  // Show a snackbar to indicate the update of the class event
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Task updated'),
                    ),
                  );

                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show an error message if any field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Function to display add task dialog
  void _showAddTaskDialog(BuildContext context, TaskEvent classEvent) {
    TextEditingController classNameController = TextEditingController();
    TextEditingController startTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: classNameController,
                decoration: InputDecoration(labelText: 'Task Name'),
              ),
              TextField(
                controller: startTimeController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String className = classNameController.text;
                String startTime = startTimeController.text;

                if (className.isNotEmpty && startTime.isNotEmpty) {
                  // Create a new class event
                  TaskEvent newClass = TaskEvent(
                    taskName: className,
                    description: startTime,
                  );

                  // Insert the new class event into the database
                  await ClassEventDatabaseHelper().insertClassEvent(newClass);

                  // Refresh the screen by updating the list of class events
                  _getClassEvents();

                  // Show a snackbar to indicate the addition of the new class
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New Task added'),
                    ),
                  );

                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show an error message if any field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a task event
  Future<void> _deleteClassEvent(TaskEvent classEvent) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Have You completed  this Task ?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmDelete != null && confirmDelete) {
      try {
        await ClassEventDatabaseHelper().deleteClassEvent(classEvent.id!);
        _getClassEvents(); // Refresh the screen after deleting
      } catch (e) {
        print("Error deleting  Task: $e");
      }
    }
  }
}

// Widget for the background counter with gradients
class CounterWithUltraGradients extends StatefulWidget {
  const CounterWithUltraGradients({super.key});

  @override
  State<CounterWithUltraGradients> createState() =>
      _CounterWithUltraGradientsState();
}

class _CounterWithUltraGradientsState extends State<CounterWithUltraGradients> {
  @override
  Widget build(BuildContext context) {
    return BackgroundShapes(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget to create background shapes with animations
class BackgroundShapes extends StatefulWidget {
  const BackgroundShapes({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<BackgroundShapes> createState() => _BackgroundShapesState();
}

class _BackgroundShapesState extends State<BackgroundShapes>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
    _controller.repeat(reverse: true);
    super.initState();
  }

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_animation),
                child: Container(),
              );
            },
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener((status) {});
    _controller.dispose();
    super.dispose();
  }
}

// Custom painter for drawing background shapes
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  const BackgroundPainter(this.animation);

  Offset getOffset(Path path) {
    final pms = path.computeMetrics(forceClosed: false).elementAt(0);
    final length = pms.length;
    final offset = pms.getTangentForOffset(length * animation.value)!.position;
    return offset;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      30,
    );
    drawShape1(canvas, size, paint, Colors.orange);
    drawShape2(canvas, size, paint, Colors.greenAccent);
    drawShape3(canvas, size, paint, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  void drawShape1(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(size.width, 0);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2,
      -100,
      size.height / 4,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 150, paint);
  }

  void drawShape2(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(size.width, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2,
      size.width * 0.9,
      size.height * 0.9,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 250, paint);
  }

  void drawShape3(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(0, 0);
    path.quadraticBezierTo(
      0,
      size.height,
      size.width / 3,
      size.height / 3,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 250, paint);
  }
}
